import SwiftUI

#if os(iOS) // solo iPhone: non va compilato nel target Apple Watch

@main
struct cronoOrbitApp: App {
    @State private var store: EventStore
    
    // 1. Inizializza il ProgressManager qui
    @StateObject private var progressManager = ProgressManager()
    
    init() {
        let s = EventStore()
        _store = State(initialValue: s)
        
        // 2. Modifica la chiamata per passare ENTRAMBI al NotificationManager
        // Nota: Assicurati di aver fatto la Modifica 3 in NotificationManager.swift come spiegato prima!
        // Se non l'hai fatta, per ora commenta questa riga o togli ', progress: progressManager'
        NotificationManager.shared.start(store: s, progress: ProgressManager())
    }
    
    var body: some Scene {
        WindowGroup {
            RootView() // Questa è la tua vista iniziale vera
                .environment(store)
                // 3. Passa il ProgressManager a tutta l'app
                .environmentObject(progressManager)
                .task {
                    await NotificationManager.shared.reschedule(for: store.events)
                    PhoneConnectivity.shared.start(store: store)
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

