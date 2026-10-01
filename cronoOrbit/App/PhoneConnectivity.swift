import WatchConnectivity

#if os(iOS) // solo iPhone: non va compilato nel target Apple Watch

/// Lato iPhone: manda all'Apple Watch gli impegni dei prossimi 7 giorni.
final class PhoneConnectivity: NSObject, WCSessionDelegate {
    static let shared = PhoneConnectivity()
    private var pending: [Event] = []

    func start() {
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

    // MARK: WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated { send(pending) }
    }
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
}
#endif
