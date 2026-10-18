import SwiftUI

@main
struct FocusFlowApp: App {
    @AppStorage("accentColor") private var accentColorRaw: String = AppAccentColor.indigo.rawValue
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    init() {
        if CommandLine.arguments.contains("--uitesting") {
            UserDefaults.standard.removeObject(forKey: "focusflow.tasks")
            UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasSeenOnboarding {
                    ContentView()
                } else {
                    OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                }
            }
            .tint(appAccentColor)
        }
    }

    private var appAccentColor: Color {
        AppAccentColor(rawValue: accentColorRaw)?.color ?? .indigo
    }
}
