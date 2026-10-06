import SwiftUI

#if os(watchOS)

@main
struct cronoOrbitWatchApp: App {
    @State private var store: WatchEventStore

    init() {
        let s = WatchEventStore()
        _store = State(initialValue: s)
        WatchSessionManager.shared.start(store: s)   // la sessione parte subito, anche in background
    }

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environment(store)
        }
    }
}

#endif
