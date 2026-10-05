import SwiftUI
import Observation

#if os(watchOS)

@Observable
final class WatchEventStore {
    var events: [Event] = []

    func todayEvents() -> [Event] {
        let cal = Calendar.current
        let today = Date.now
        return events
            .filter { cal.isDate($0.start, inSameDayAs: today) }
            .sorted { $0.start < $1.start }
    }
}

#endif
