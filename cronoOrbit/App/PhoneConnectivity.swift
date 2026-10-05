import WatchConnectivity
import Foundation

#if os(iOS)

final class PhoneConnectivity: NSObject, WCSessionDelegate {
    static let shared = PhoneConnectivity()
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
            // 1. Aggiorna il contesto generale
            try? session.updateApplicationContext(payload)
            // 2. Metti in coda il trasferimento info (garantito nel simulatore)
            session.transferUserInfo(payload)
            // 3. Se raggiungibile, invia subito un messaggio
            if session.isReachable {
                session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
            }
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
