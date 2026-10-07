import EventKit
import Observation

#if os(watchOS)

@Observable
final class WatchCalendarImporter {
    private let ek = EKEventStore()
    var status = EKEventStore.authorizationStatus(for: .event)

    var hasAccess: Bool { status == .fullAccess }

    /// Richiede il permesso direttamente sul display dell'Apple Watch
    func requestAccess() async {
        _ = try? await ek.requestFullAccessToEvents()
        status = EKEventStore.authorizationStatus(for: .event)
    }

    /// Legge gli eventi di TUTTI i calendari abilitati sull'Apple Watch per i prossimi `days` giorni
    func loadUpcomingEvents(days: Int = 7) -> [Event] {
        guard hasAccess else { return [] }
        
        let cal = Calendar.current
        let start = cal.startOfDay(for: .now)
        let end = cal.date(byAdding: .day, value: days, to: start)!
        
        let predicate = ek.predicateForEvents(withStart: start, end: end, calendars: nil)
        
        return ek.events(matching: predicate).map { ev in
            let s = ev.startDate!
            let e = ev.isAllDay ? cal.date(byAdding: .minute, value: 1439, to: cal.startOfDay(for: s))! : ev.endDate!
            let uid = "\(ev.eventIdentifier ?? ev.title ?? "evento")-\(Int(s.timeIntervalSince1970))"
            
            return Event(
                title: ev.title ?? "Senza titolo",
                category: .work, // Categoria predefinita o da mappare
                start: s,
                end: e,
                place: ev.location ?? "",
                notes: ev.notes ?? "",
                invited: ["Tu"],
                externalID: uid
            )
        }
    }
}

#endif
