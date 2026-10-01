import SwiftUI
import WatchConnectivity
import Observation

#if os(watchOS) // solo Apple Watch

/// Lato Apple Watch: riceve gli impegni dall'iPhone e li tiene in cache per l'uso offline.
@Observable
final class WatchStore: NSObject, WCSessionDelegate {
    var events: [Event] = []
    private let key = "events"

    override init() {
        super.init()
        if let data = UserDefaults.standard.data(forKey: key) { decode(data) }
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func events(on day: Date) -> [Event] {
        events.filter { Calendar.current.isDate($0.start, inSameDayAs: day) }
              .sorted { $0.start < $1.start }
    }

    private func decode(_ data: Data) {
        if let list = try? JSONDecoder().decode([Event].self, from: data) { events = list }
    }

    private func apply(_ data: Data) {
        UserDefaults.standard.set(data, forKey: key)
        DispatchQueue.main.async { self.decode(data) }
    }

    // MARK: WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let data = session.receivedApplicationContext[key] as? Data { apply(data) }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let data = applicationContext[key] as? Data { apply(data) }
    }
}
#endif
