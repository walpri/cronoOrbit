import WatchConnectivity
import Foundation
import Observation

#if os(iOS)

@Observable
final class PhoneConnectivity: NSObject, WCSessionDelegate {
    static let shared = PhoneConnectivity()
    
    // Riferimento allo store di iPhone per aggiornare la lista quando l'Apple Watch risponde al popup
    weak var store: EventStore?
    
    private var pendingEvents: [Event] = []

    func start() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func send(_ events: [Event]) {
        self.pendingEvents = events
        guard WCSession.isSupported() else { return }

        let cal = Calendar.current
        let start = cal.startOfDay(for: .now)
        let end = cal.date(byAdding: .day, value: 7, to: start)!
        let upcoming = events.filter { $0.start >= start && $0.start < end }

        guard let data = try? JSONEncoder().encode(upcoming) else { return }
        let payload: [String: Any] = ["events": data]

        let session = WCSession.default
        if session.activationState == .activated {
            try? session.updateApplicationContext(payload)
            session.transferUserInfo(payload)
            if session.isReachable {
                session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
            }
        }
    }

    // MARK: - Ricezione dati da Apple Watch
    
    // Riceve quando l'app è aperta sul Watch
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleIncomingData(message)
    }

    // Riceve se il pacchetto arriva tramite context o background
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        handleIncomingData(applicationContext)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        handleIncomingData(userInfo)
    }

    private func handleIncomingData(_ data: [String: Any]) {
        guard let rawData = data["events"] as? Data,
              let updatedEvents = try? JSONDecoder().decode([Event].self, from: rawData) else { return }
        
        DispatchQueue.main.async { [weak self] in
            // Aggiorna lo store locale dell'iPhone con gli eventi ricevuti dal Watch
            self?.store?.events = updatedEvents
        }
    }

    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            send(pendingEvents)
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}

#endif
