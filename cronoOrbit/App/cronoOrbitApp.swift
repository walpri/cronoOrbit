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
                    // Aspetta mezzo secondo per assicurare l'attivazione della sessione WCSession nel simulatore
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    PhoneConnectivity.shared.send(store.events)
                }
                .onChange(of: store.events) { _, new in
                    PhoneConnectivity.shared.send(new)
                }
        }
    }
}
#endif
