import EventKit
import Observation

/// Legge i calendari del dispositivo (iCloud, Google, Outlook… se aggiunti in Impostazioni > Calendario).
@Observable
final class CalendarImporter {
    private let ek = EKEventStore()
    var status = EKEventStore.authorizationStatus(for: .event)
    var calendars: [EKCalendar] = []

    var hasAccess: Bool { status == .fullAccess }

    func requestAccess() async {
        _ = try? await ek.requestFullAccessToEvents()
        status = EKEventStore.authorizationStatus(for: .event)
        if hasAccess { loadCalendars() }
    }

    func loadCalendars() {
        calendars = ek.calendars(for: .event)
            .sorted { ($0.source.title, $0.title) < ($1.source.title, $1.title) }
    }

    /// Eventi dei calendari scelti, da oggi ai prossimi `days` giorni.
    func events(from chosen: [EKCalendar], days: Int, category: EventCategory) -> [Event] {
        guard !chosen.isEmpty else { return [] }
        let cal = Calendar.current
        let start = cal.startOfDay(for: .now)
        let end = cal.date(byAdding: .day, value: days, to: start)!
        let predicate = ek.predicateForEvents(withStart: start, end: end, calendars: chosen)

        return ek.events(matching: predicate).map { ev in
            let s = ev.startDate!
            // Evento "tutto il giorno": lo chiudiamo alle 23:59 dello stesso giorno
            let e = ev.isAllDay ? cal.date(byAdding: .minute, value: 1439, to: cal.startOfDay(for: s))! : ev.endDate!
            // Gli eventi ricorrenti condividono l'identifier: aggiungiamo la data di inizio
            let uid = "\(ev.eventIdentifier ?? ev.title ?? "evento")-\(Int(s.timeIntervalSince1970))"
            return Event(title: ev.title ?? "Senza titolo",
                         category: category,
                         start: s, end: e,
                         place: ev.location ?? "",
                         notes: ev.notes ?? "",
                         invited: ["Tu"],
                         externalID: uid)
        }
    }
}
