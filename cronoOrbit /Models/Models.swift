import SwiftUI
import Observation

enum EventCategory: String, CaseIterable, Identifiable {
    case focus = "Focus", health = "Salute", work = "Lavoro", social = "Sociale"
    var id: String { rawValue }
    /// Nome mostrato nell'interfaccia (si traduce con la lingua del sistema)
    var name: LocalizedStringKey {
        switch self {
        case .focus:  "Focus"
        case .health: "Salute"
        case .work:   "Lavoro"
        case .social: "Sociale"
        }
    }
    var color: Color {
        switch self {
        case .focus:  Color(red: 0.56, green: 0.69, blue: 1.0)
        case .health: Color(red: 0.49, green: 1.0, blue: 0.70)
        case .work:   Color(red: 1.0, green: 0.82, blue: 0.40)
        case .social: Color(red: 1.0, green: 0.62, blue: 0.78)
        }
    }
}

struct Event: Identifiable, Hashable {
    var id = UUID()
    var title: String
    var category: EventCategory
    var start: Date
    var end: Date
    var place = ""
    var notes = ""
    var invited: [String] = []
    var reminderMinutes = 15
    /// ID del calendario di origine (serve a evitare duplicati quando si reimporta)
    var externalID: String? = nil

    var startMinutes: Double { Event.minutes(start) }
    var endMinutes: Double { Event.minutes(end) }
    var duration: TimeInterval { end.timeIntervalSince(start) }

    static func minutes(_ d: Date) -> Double {
        let c = Calendar.current
        return Double(c.component(.hour, from: d) * 60 + c.component(.minute, from: d))
    }
}

extension TimeInterval {
    /// Es. "2h 30m"
    var hm: String {
        let m = max(0, Int(self / 60))
        return "\(m / 60)h " + String(format: "%02d", m % 60) + "m"
    }
}

@Observable
final class EventStore {
    var events: [Event] = EventStore.sample()

    func events(on day: Date) -> [Event] {
        events.filter { Calendar.current.isDate($0.start, inSameDayAs: day) }
              .sorted { $0.start < $1.start }
    }
    func add(_ e: Event) { events.append(e) }
    func delete(_ id: Event.ID) { events.removeAll { $0.id == id } }

    /// Aggiunge solo gli eventi non ancora importati. Ritorna quanti ne ha aggiunti.
    @discardableResult
    func importEvents(_ new: [Event]) -> Int {
        let known = Set(events.compactMap(\.externalID))
        let fresh = new.filter { $0.externalID.map { !known.contains($0) } ?? true }
        events.append(contentsOf: fresh)
        return fresh.count
    }

    // Dati di esempio: sostituiscili con la tua persistenza (SwiftData, CloudKit, EventKit…)
    static func sample() -> [Event] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        func at(_ day: Int, _ h: Int, _ m: Int = 0) -> Date {
            let d = cal.date(byAdding: .day, value: day, to: today)!
            return cal.date(byAdding: .minute, value: h * 60 + m, to: d)!
        }
        return [
            Event(title: "Lezione di finanza", category: .work, start: at(0, 8, 30), end: at(0, 10, 30), place: "Università, Aula 4", invited: ["Tu", "Giulia"]),
            Event(title: "Studio in biblioteca", category: .focus, start: at(0, 11), end: at(0, 13), place: "Biblioteca centrale", invited: ["Tu"]),
            Event(title: "Palestra", category: .health, start: at(0, 18), end: at(0, 19, 30), place: "Palestra", invited: ["Tu", "Marco"]),
            Event(title: "Deep work: Design UI", category: .focus, start: at(1, 11, 30), end: at(1, 13), place: "Studio · Via Solferino 24, Milano", notes: "Sessione senza distrazioni per finalizzare il nuovo flusso mobile.", invited: ["Tu", "Giulia", "Marco"]),
            Event(title: "Aperitivo con amici", category: .social, start: at(2, 19), end: at(2, 21), place: "Centro", invited: ["Tu", "Giulia"])
        ]
    }
}
