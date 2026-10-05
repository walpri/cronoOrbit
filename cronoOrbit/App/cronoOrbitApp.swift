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
                    // 1. Colleghiamo lo store così l'iPhone può aggiornarsi quando il Watch gli risponde
                    PhoneConnectivity.shared.store = store
                    
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
#endif // os(iOS)
