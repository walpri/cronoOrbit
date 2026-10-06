import Foundation
import WatchConnectivity

#if os(iOS) // solo iPhone: non va compilato nel target Apple Watch

/// Lato iPhone: manda all'Apple Watch gli impegni dei prossimi 7 giorni
/// e riceve dal Watch gli esiti ("Fatto" / "Non fatto") degli impegni terminati.
final class PhoneConnectivity: NSObject, WCSessionDelegate {
    static let shared = PhoneConnectivity()
    private var pending: [Event] = []
    private weak var store: EventStore?

    func start(store: EventStore) {
        self.store = store
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func send(_ events: [Event]) {
        pending = events
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated,
              WCSession.default.isPaired,
              WCSession.default.isWatchAppInstalled else { return }

        let cal = Calendar.current
        let start = cal.startOfDay(for: .now)
        let end = cal.date(byAdding: .day, value: 7, to: start)!
        let upcoming = events.filter { $0.start >= start && $0.start < end }
        guard let data = try? JSONEncoder().encode(upcoming) else { return }
        try? WCSession.default.updateApplicationContext(["events": data])
    }

    // MARK: Ricezione dal Watch

    private func handle(_ dict: [String: Any]) {
        guard let data = dict["completions"] as? Data,
              let updates = try? JSONDecoder().decode([CompletionUpdate].self, from: data) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.store?.applyCompletions(updates)
        }
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated { send(pending) }
    }

    /// Il Watch è stato appena abbinato o l'app Watch è stata installata: rimanda gli impegni
    func sessionWatchStateDidChange(_ session: WCSession) {
        send(pending)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        handle(userInfo)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handle(message)
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
}
#endif
