import WatchConnectivity
import Foundation

#if os(watchOS)

/// Lato Apple Watch: riceve gli impegni dall'iPhone e gli manda indietro gli esiti.
/// (Non si chiama `WatchConnectivity` per non andare in conflitto con il framework omonimo.)
final class WatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    private weak var store: WatchEventStore?
    /// Esiti da inviare appena la sessione è attiva
    private var outbox: [CompletionUpdate] = []

    func start(store: WatchEventStore) {
        self.store = store
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: Invio verso l'iPhone

    /// Manda all'iPhone solo l'esito appena dato (non l'intero elenco: sul Watch ci sono solo 7 giorni).
    func send(_ update: CompletionUpdate) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else {
            outbox.append(update)
            return
        }
        transmit([update], via: session)
    }

    private func transmit(_ updates: [CompletionUpdate], via session: WCSession) {
        guard let data = try? JSONEncoder().encode(updates) else { return }
        let payload: [String: Any] = ["completions": data]
        // Consegna garantita anche se l'iPhone non è raggiungibile adesso
        session.transferUserInfo(payload)
        // Consegna immediata se l'iPhone è vicino e l'app è attiva (l'iPhone ignora i doppioni)
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        }
    }

    // MARK: Ricezione dall'iPhone

    private func receive(_ dict: [String: Any]) {
        guard let data = dict["events"] as? Data,
              let received = try? JSONDecoder().decode([Event].self, from: data) else { return }
        Task { @MainActor [weak self] in
            self?.store?.apply(received: received)
        }
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        guard activationState == .activated else { return }
        receive(session.receivedApplicationContext)
        if !outbox.isEmpty {
            transmit(outbox, via: session)
            outbox.removeAll()
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        receive(applicationContext)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        receive(userInfo)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        receive(message)
    }
}

#endif
