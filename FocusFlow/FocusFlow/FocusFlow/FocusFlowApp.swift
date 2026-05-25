import SwiftUI

@main
struct FocusFlowApp: App {

    init() {
        // Очистка данных при запуске из UI-тестов для изоляции каждого теста
        if CommandLine.arguments.contains("--uitesting") {
            UserDefaults.standard.removeObject(forKey: "focusflow.tasks")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
