import SwiftUI

@main
struct cronoOrbitApp: App {
    @State private var store = EventStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
        }
    }
}
