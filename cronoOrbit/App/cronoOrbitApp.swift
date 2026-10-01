import SwiftUI

#if os(iOS) // solo iPhone: non va compilato nel target Apple Watch

@main
struct cronoOrbitApp: App {
    @State private var store = EventStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .task {
                    PhoneConnectivity.shared.start()
                    PhoneConnectivity.shared.send(store.events)
                }
                .onChange(of: store.events) { _, new in
                    PhoneConnectivity.shared.send(new)
                }
        }
    }
}
#endif
