import Foundation
import SwiftData
import UIKit

private let kOnboardingKey = "vc_onboarding_done"

@MainActor
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
    private var isSetUp = false

    // MARK: - Setup (called once; safe to call multiple times)

    func setup(modelContext: ModelContext) {
        guard !isSetUp else { return }
        isSetUp = true
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
        // Lazy setup: ensure repos are ready even if onAppear fires after this task
        if !isSetUp { setup(modelContext: modelContext) }
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

        // Fetch raw values on cooperative thread pool, then build @Model on main actor
        let values = await snapshotBuilder.fetchValues(for: date)
        let snapshot = HealthSnapshot(date: date)
        snapshot.sleepHours       = values.sleepHours
        snapshot.averageHeartRate = values.averageHeartRate
        snapshot.restingHeartRate = values.restingHeartRate
        snapshot.hrv              = values.hrv
        snapshot.stepCount        = values.stepCount
        snapshot.workoutMinutes   = values.workoutMinutes
        snapshot.mindfulMinutes   = values.mindfulMinutes
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

        // UserDefaults is the primary source of truth for onboarding.
        // NEVER downgrade hasCompletedOnboarding from true → false here:
        // SwiftData may be empty (in-memory fallback after schema change / fresh install),
        // while the user already completed onboarding in a previous session.
        if let state = permissionState {
            // SwiftData record exists — upgrade UserDefaults if needed
            if state.hasCompletedOnboarding && !hasCompletedOnboarding {
                hasCompletedOnboarding = true
                UserDefaults.standard.set(true, forKey: kOnboardingKey)
            }
        } else if hasCompletedOnboarding {
            // UserDefaults says done but SwiftData has no record — recreate it
            let state = PermissionState()
            state.hasCompletedOnboarding = true
            modelContext.insert(state)
            try? modelContext.save()
            permissionState = state
        }
        // If both are false, nothing to do — onboarding not yet completed.
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
