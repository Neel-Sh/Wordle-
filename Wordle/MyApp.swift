import SwiftUI

@main struct EncoreApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .defaultAppStorage(EncorePreferences.defaults)
        }
    }
}

enum EncorePreferences {
    static var defaults: UserDefaults {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-ui-testing") || arguments.contains("-ui-testing-resume") {
            return UserDefaults(suiteName: "encore.ui-tests")!
        }
        #endif
        return .standard
    }
}
