import WatchConnectivity
import Foundation

#if os(watchOS)

final class WatchConnectivity: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivity()
    private weak var store: WatchEventStore?

    func start(store: WatchEventStore) {
        self.store = store
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Invio dati da Apple Watch verso iPhone
    func send(_ events: [Event]) {
        guard WCSession.isSupported() else { return }
        
        guard let data = try? JSONEncoder().encode(events) else { return }
        let payload: [String: Any] = ["events": data]

        let session = WCSession.default
        if session.activationState == .activated {
            // 1. Invia aggiornamento di contesto
            try? session.updateApplicationContext(payload)
            
            // 2. Metti in coda il trasferimento info
            session.transferUserInfo(payload)
            
            // 3. Se l'iPhone è raggiungibile in tempo reale, invia subito un messaggio
            if session.isReachable {
                session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
            }
        }
    }

    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            updateFromDictionary(session.receivedApplicationContext)
        }
    }

    // Ricezione via transferUserInfo
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        DispatchQueue.main.async {
            self.updateFromDictionary(userInfo)
        }
    }

    // Ricezione via updateApplicationContext
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            self.updateFromDictionary(applicationContext)
        }
    }

    // Ricezione via sendMessage
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.updateFromDictionary(message)
        }
    }

    private func updateFromDictionary(_ dict: [String: Any]) {
        guard let data = dict["events"] as? Data,
              let receivedEvents = try? JSONDecoder().decode([Event].self, from: data) else { return }
        self.store?.events = receivedEvents
    }
}

#endif // os(watchOS)
