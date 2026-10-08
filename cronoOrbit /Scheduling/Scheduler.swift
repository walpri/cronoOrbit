import Foundation

// MARK: - Motore di pianificazione (calcolo puro, senza AI: è lui a decidere gli orari)

struct TimeSlot: Identifiable, Hashable {
    var start: Date
    var end: Date
    var id: Date { start }
    var duration: TimeInterval { end.timeIntervalSince(start) }
}

enum SchedulePlan {
    case free(TimeSlot)
    case conflict(with: [Event], alternatives: [TimeSlot])
    case suggestions([TimeSlot])                              
    case noRoom
}

struct Scheduler {
    /// Finestra della giornata in cui proporre impegni (8:00–22:00)
    var dayStartHour = 8
    var dayEndHour = 22
    var cal = Calendar.current

    /// Gli eventi "tutto il giorno" (>= 20 ore) sono promemoria, non bloccano l'agenda.
    private func blocking(_ events: [Event]) -> [Event] {
        events.filter { $0.duration < 20 * 3600 && $0.completion == nil }
    }

    /// Eventi che si sovrappongono all'intervallo indicato.
    func conflicts(start: Date, end: Date, in events: [Event]) -> [Event] {
        blocking(events)
            .filter { $0.start < end && $0.end > start }
            .sorted { $0.start < $1.start }
    }

    /// Spazi liberi di una giornata lunghi almeno `minDuration`.
    func freeSlots(on day: Date, in events: [Event], minDuration: TimeInterval, after: Date = .distantPast) -> [TimeSlot] {
        let dayStart = cal.startOfDay(for: day)
        guard let windowStart = cal.date(byAdding: .hour, value: dayStartHour, to: dayStart),
              let windowEnd = cal.date(byAdding: .hour, value: dayEndHour, to: dayStart) else { return [] }

        var cursor = max(windowStart, roundUp(after))
        let busy = blocking(events)
            .filter { $0.end > cursor && $0.start < windowEnd }
            .sorted { $0.start < $1.start }

        var out: [TimeSlot] = []
        for e in busy {
            if e.start.timeIntervalSince(cursor) >= minDuration {
                out.append(TimeSlot(start: cursor, end: e.start))
            }
            cursor = max(cursor, e.end)
        }
        if windowEnd.timeIntervalSince(cursor) >= minDuration {
            out.append(TimeSlot(start: cursor, end: windowEnd))
        }
        return out
    }

    /// Controlla un orario preciso: libero, oppure in conflitto con alternative.
    func plan(duration: TimeInterval, preferredStart: Date?, events: [Event],
              now: Date = .now, daysAhead: Int = 7) -> SchedulePlan {
        if let p = preferredStart, p >= now.addingTimeInterval(-60) {
            let end = p.addingTimeInterval(duration)
            let clash = conflicts(start: p, end: end, in: events)
            if clash.isEmpty { return .free(TimeSlot(start: p, end: end)) }
            let alts = alternatives(duration: duration, near: p, events: events, now: now, daysAhead: daysAhead)
            return alts.isEmpty ? .noRoom : .conflict(with: clash, alternatives: alts)
        }
        return suggestions(duration: duration, near: now, events: events, now: now, daysAhead: daysAhead)
    }

    /// I primi orari liberi vicini a `near`.
    func suggestions(duration: TimeInterval, near: Date, events: [Event],
                     now: Date = .now, daysAhead: Int = 7) -> SchedulePlan {
        let alts = alternatives(duration: duration, near: near, events: events, now: now, daysAhead: daysAhead)
        return alts.isEmpty ? .noRoom : .suggestions(alts)
    }

    /// Fino a `limit` orari liberi, i più vicini a `target`, in ordine cronologico.
    func alternatives(duration: TimeInterval, near target: Date, events: [Event],
                      now: Date, daysAhead: Int, limit: Int = 3) -> [TimeSlot] {
        var candidates: [TimeSlot] = []
        let firstDay = cal.startOfDay(for: max(target, now))
        for offset in 0...daysAhead {
            guard let day = cal.date(byAdding: .day, value: offset, to: firstDay) else { continue }
            for slot in freeSlots(on: day, in: events, minDuration: duration, after: now) {
                let latestStart = slot.end.addingTimeInterval(-duration)
                let start = min(max(target, slot.start), latestStart)   // il punto dello spazio più vicino a target
                candidates.append(TimeSlot(start: start, end: start.addingTimeInterval(duration)))
            }
        }
        let closest = candidates.sorted {
            abs($0.start.timeIntervalSince(target)) < abs($1.start.timeIntervalSince(target))
        }
        return Array(closest.prefix(limit)).sorted { $0.start < $1.start }
    }

    /// Arrotonda per eccesso ai 5 minuti.
    private func roundUp(_ d: Date) -> Date {
        guard d != .distantPast else { return d }
        let step: TimeInterval = 300
        return Date(timeIntervalSinceReferenceDate: (d.timeIntervalSinceReferenceDate / step).rounded(.up) * step)
    }
}

/// Es. "gio 2 ott · 15:30–16:30"
func slotLabel(_ s: TimeSlot) -> String {
    let day = s.start.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    let from = s.start.formatted(date: .omitted, time: .shortened)
    let to = s.end.formatted(date: .omitted, time: .shortened)
    return "\(day) · \(from)–\(to)"
}
