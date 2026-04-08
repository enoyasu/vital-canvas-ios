import Foundation
import SwiftData
import UIKit

@Observable
final class AppController {
    private(set) var isLoading = false
    private(set) var todayArtwork: CanvasArtwork?
    private(set) var recentArtworks: [CanvasArtwork] = []
    private(set) var permissionState: PermissionState?
    private(set) var hasCompletedOnboarding = false

    private let authService = HealthAuthorizationService()
    private let snapshotBuilder = SnapshotBuilder()
    private let baselineCalc = BaselineCalculator()
    private let titleGen = ArtworkTitleGenerator()
    private var artworkRepo: ArtworkRepository?
    private var snapshotRepo: SnapshotRepository?

    func setup(modelContext: ModelContext) {
        artworkRepo = ArtworkRepository(modelContext: modelContext)
        snapshotRepo = SnapshotRepository(modelContext: modelContext)
        artworkRepo?.ensureArtworksDirectory()
        loadPermissionState(modelContext: modelContext)
        loadArtworks()
    }

    // MARK: - Onboarding

    func completeOnboarding(modelContext: ModelContext) {
        if let state = permissionState {
            state.hasCompletedOnboarding = true
            try? modelContext.save()
        } else {
            let state = PermissionState()
            state.hasCompletedOnboarding = true
            modelContext.insert(state)
            try? modelContext.save()
            permissionState = state
        }
        hasCompletedOnboarding = true
    }

    func requestHealthPermissions() async {
        try? await authService.requestAuthorization()
    }

    // MARK: - Artwork

    func generateTodayArtworkIfNeeded(modelContext: ModelContext, language: Language = .english) async {
        guard artworkRepo?.fetchForDate(Date()) == nil else {
            loadArtworks()
            return
        }
        await generateArtwork(for: Date(), modelContext: modelContext, language: language)
    }

    func generateArtwork(for date: Date, modelContext: ModelContext, language: Language = .english) async {
        guard let artworkRepo, let snapshotRepo else { return }
        isLoading = true
        defer { isLoading = false }

        let snapshot = await snapshotBuilder.buildSnapshot(for: date)
        snapshotRepo.save(snapshot)

        let historicalSnapshots = snapshotRepo.fetchRecent(days: 28)
        let baselines = baselineCalc.computeBaselines(from: historicalSnapshots)

        let params: BaselineCalculator.NormalizedParams
        if baselines.isEmpty {
            params = baselineCalc.normalizeWithDefaults(snapshot: snapshot)
        } else {
            params = baselineCalc.normalize(snapshot: snapshot, baselines: baselines)
        }

        let seed = makeSeed(for: date)
        let titleResult = titleGen.generate(params: params, language: language)
        let artParams = ArtworkGenerator.makeParams(normalized: params, seed: seed)

        let artwork = CanvasArtwork(
            date: date,
            seed: seed,
            title: titleResult.title,
            subtitle: titleResult.subtitle,
            summary: titleResult.summary,
            sleep: params.sleep,
            hrv: params.hrv,
            restingHR: params.restingHR,
            activity: params.activity,
            mindfulness: params.mindfulness
        )

        let image = await MainActor.run {
            ArtworkGenerator.generate(params: artParams)
        }
        artworkRepo.save(artwork, image: image)
        loadArtworks()
    }

    func loadImage(for artwork: CanvasArtwork) -> UIImage? {
        artworkRepo?.loadImage(for: artwork)
    }

    // MARK: - Private

    private func loadPermissionState(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<PermissionState>()
        let states = (try? modelContext.fetch(descriptor)) ?? []
        permissionState = states.first
        hasCompletedOnboarding = permissionState?.hasCompletedOnboarding ?? false
    }

    private func loadArtworks() {
        let artworks = artworkRepo?.fetchRecent(limit: 7) ?? []
        todayArtwork = artworks.first(where: { Calendar.current.isDateInToday($0.date) })
        recentArtworks = artworks
    }

    private func makeSeed(for date: Date) -> Int {
        let cal = Calendar.current
        let components = cal.dateComponents([.year, .month, .day], from: date)
        let y = components.year ?? 2026
        let m = components.month ?? 1
        let d = components.day ?? 1
        return y * 10000 + m * 100 + d
    }
}
