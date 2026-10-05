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

#endif
