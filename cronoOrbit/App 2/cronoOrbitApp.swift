import SwiftUI

#if os(iOS) // solo iPhone: non va compilato nel target Apple Watch

@main
struct cronoOrbitApp: App {
    @State private var store: EventStore

    init() {
        let s = EventStore()
        _store = State(initialValue: s)
        NotificationManager.shared.start(store: s)      // risposte alle notifiche anche ad app chiusa
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .task {
                    await NotificationManager.shared.reschedule(for: store.events)
                    PhoneConnectivity.shared.start()
                    PhoneConnectivity.shared.send(store.events)
                }
                .onChange(of: store.events) { _, new in
                    PhoneConnectivity.shared.send(new)
                    Task { await NotificationManager.shared.reschedule(for: new) }
                }
        }
    }
}
#endif
