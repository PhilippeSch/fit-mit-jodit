import SwiftUI

@main
struct FitMitJoditWatchApp: App {
    var body: some Scene {
        WindowGroup {
            Text(AppInfo.displayName)
                .accessibilityIdentifier("watchTitle")
        }
    }
}
