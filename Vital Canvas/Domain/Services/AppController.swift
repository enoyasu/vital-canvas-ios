import Foundation
import SwiftData
import UIKit

private let kOnboardingKey = "vc_onboarding_done"

@Observable
final class AppController {
    private(set) var isLoading = false
    private(set) var todayArtwork: CanvasArtwork?
    private(set) var recentArtworks: [CanvasArtwork] = []
    private(set) var permissionState: PermissionState?
    // Read from UserDefaults immediately so the correct screen is shown before SwiftData loads
    private(set) var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: kOnboardingKey)

    private let authService = HealthAuthorizationService()
    private let snapshotBuilder = SnapshotBuilder()
    private let baselineCalc = BaselineCalculator()
    private let titleGen = ArtworkTitleGenerator()
    private var artworkRepo: ArtworkRepository?
    private var snapshotRepo: SnapshotRepository?

    // MARK: - Setup (called once from .onAppear with the stable ModelContext)

    func setup(modelContext: ModelContext) {
        artworkRepo = ArtworkRepository(modelContext: modelContext)
        snapshotRepo = SnapshotRepository(modelContext: modelContext)
        artworkRepo?.ensureArtworksDirectory()
        syncPermissionState(modelContext: modelContext)
        loadArtworks()
    }

    // MARK: - Onboarding

    func completeOnboarding(modelContext: ModelContext) {
        // Persist to both UserDefaults (instant) and SwiftData (durable)
        UserDefaults.standard.set(true, forKey: kOnboardingKey)
        hasCompletedOnboarding = true

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

        // Generate image on a background thread to avoid blocking the main actor
        let image = await Task.detached(priority: .userInitiated) {
            ArtworkGenerator.generate(params: artParams)
        }.value

        artworkRepo.save(artwork: makeArtwork(date: date, seed: seed, title: titleResult, params: params), image: image)
        loadArtworks()
    }

    func loadImage(for artwork: CanvasArtwork) -> UIImage? {
        artworkRepo?.loadImage(for: artwork)
    }

    // MARK: - Private

    private func syncPermissionState(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<PermissionState>()
        let states = (try? modelContext.fetch(descriptor)) ?? []
        permissionState = states.first
        // SwiftData is the source of truth — sync back to UserDefaults and memory
        let done = permissionState?.hasCompletedOnboarding ?? false
        if done != hasCompletedOnboarding {
            hasCompletedOnboarding = done
            UserDefaults.standard.set(done, forKey: kOnboardingKey)
        }
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

    private func makeArtwork(
        date: Date, seed: Int,
        title: ArtworkTitleGenerator.TitleResult,
        params: BaselineCalculator.NormalizedParams
    ) -> CanvasArtwork {
        CanvasArtwork(
            date: date,
            seed: seed,
            title: title.title,
            subtitle: title.subtitle,
            summary: title.summary,
            sleep: params.sleep,
            hrv: params.hrv,
            restingHR: params.restingHR,
            activity: params.activity,
            mindfulness: params.mindfulness
        )
    }
}
