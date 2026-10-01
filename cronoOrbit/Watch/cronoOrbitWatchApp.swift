import SwiftUI

#if os(watchOS) // solo Apple Watch

@main
struct cronoOrbitWatchApp: App {
    @State private var store = WatchStore()

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environment(store)
        }
    }
}
#endif
