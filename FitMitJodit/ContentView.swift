import SwiftUI

struct ContentView: View {
    var body: some View {
        Text(AppInfo.displayName)
            .font(.largeTitle)
            .accessibilityIdentifier("appTitle")
    }
}
