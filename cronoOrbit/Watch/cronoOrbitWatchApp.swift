import SwiftUI

#if os(watchOS)

@main
struct cronoOrbitWatchApp: App {
    @State private var store = WatchEventStore()

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environment(store)
                .onAppear {
                    WatchConnectivity.shared.start(store: store)
                }
        }
    }
}

#endif
