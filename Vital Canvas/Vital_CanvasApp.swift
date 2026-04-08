import SwiftUI
import SwiftData

@main
struct VitalCanvasApp: App {
    // @State ensures these are created exactly once even when the App struct is re-evaluated
    @State private var controller = AppController()
    @State private var languageManager = LanguageManager()
    @State private var container = VitalCanvasApp.makeContainer()

    var body: some Scene {
        WindowGroup {
            RootView(controller: controller, languageManager: languageManager)
                .onAppear {
                    controller.setup(modelContext: container.mainContext)
                }
        }
        .modelContainer(container)
    }

    // MARK: - Container factory (called once via @State initialisation)

    static func makeContainer() -> ModelContainer {
        let schema = Schema([
            HealthSnapshot.self,
            BaselineProfile.self,
            CanvasArtwork.self,
            PermissionState.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        // 1st attempt — normal persistent store
        if let c = try? ModelContainer(for: schema, configurations: [config]) {
            return c
        }

        // 2nd attempt — wipe corrupted / incompatible store and retry
        if let storeURL = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appending(path: "default.store") {
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
        }
        if let c = try? ModelContainer(for: schema, configurations: [config]) {
            return c
        }

        // Fallback — in-memory (no persistence, but app still runs)
        let memConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [memConfig])
    }
}

// MARK: - Root routing

struct RootView: View {
    var controller: AppController
    var languageManager: LanguageManager

    var body: some View {
        ZStack {
            VCColor.background.ignoresSafeArea()

            Group {
                if !languageManager.hasSelectedLanguage {
                    LanguageSelectionView(languageManager: languageManager)
                        .transition(.opacity)
                } else if !controller.hasCompletedOnboarding {
                    OnboardingView(controller: controller, languageManager: languageManager)
                        .transition(.opacity)
                } else {
                    HomeView(controller: controller, languageManager: languageManager)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: languageManager.hasSelectedLanguage)
            .animation(.easeInOut(duration: 0.3), value: controller.hasCompletedOnboarding)
        }
        .preferredColorScheme(.dark)
    }
}
