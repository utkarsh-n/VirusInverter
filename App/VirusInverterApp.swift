import SwiftUI

@main
struct VirusInverterApp: App {
    @State private var session = InverterSession()

    var body: some Scene {
        WindowGroup {
            InverterRootView(session: session)
                .tint(BenchTheme.amber)
        }
    }
}
