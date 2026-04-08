import SwiftUI
import SwiftData

@main
struct VitalCanvasApp: App {
    @State private var controller = AppController()
    @State private var languageManager = LanguageManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            HealthSnapshot.self,
            BaselineProfile.self,
            CanvasArtwork.self,
            PermissionState.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView(controller: controller, languageManager: languageManager)
                .onAppear {
                    controller.setup(modelContext: sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

struct RootView: View {
    var controller: AppController
    var languageManager: LanguageManager

    var body: some View {
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
        .preferredColorScheme(.dark)
    }
}
