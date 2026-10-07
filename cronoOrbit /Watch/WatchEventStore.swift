import SwiftUI
import Observation

#if os(watchOS)

/// Lato Apple Watch: tiene gli impegni ricevuti dall'iPhone (con cache per l'uso offline)
/// e ricorda gli esiti dati dal polso finché l'iPhone non li conferma.
@Observable @MainActor
final class WatchEventStore {
    var events: [Event] = []
    /// Esiti dati sul Watch non ancora visti tornare dall'iPhone
    private var pendingCompletions: [Event.ID: EventCompletion] = [:]
    private let key = "events"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let list = try? JSONDecoder().decode([Event].self, from: data) {
            events = list
        }
    }

    func todayEvents() -> [Event] {
        let cal = Calendar.current
        let today = Date.now
        return events
            .filter { cal.isDate($0.start, inSameDayAs: today) && !$0.isAllDay }
            .sorted { $0.start < $1.start }
    }

    /// Nuovo elenco arrivato dall'iPhone.
    /// Se hai già risposto sul Watch ma l'iPhone non lo sa ancora, la tua risposta non va persa.
    func apply(received: [Event]) {
        events = received.map { incoming in
            var e = incoming
            if let local = pendingCompletions[e.id] {
                if e.completion != nil { pendingCompletions[e.id] = nil }
                else { e.completion = local }
            }
            return e
        }
        persist()
    }

    /// Segna l'esito di un impegno. Ritorna l'aggiornamento da mandare all'iPhone.
    func complete(_ id: Event.ID, status: CompletionStatus) -> CompletionUpdate? {
        guard let i = events.firstIndex(where: { $0.id == id }) else { return nil }
        let planned = max(1, Int(events[i].duration / 60))
        let completion = EventCompletion(status: status, actualMinutes: status == .skipped ? 0 : planned)
        events[i].completion = completion
        events[i].trackingStart = nil
        pendingCompletions[id] = completion
        persist()
        return CompletionUpdate(id: id, completion: completion)
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

#endif
