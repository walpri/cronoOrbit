import Foundation

// MARK: - Calcolo del resoconto settimanale (puro, senza interfaccia)

enum ReportPeriod: String, CaseIterable, Identifiable {
    case week, month
    var id: String { rawValue }
}

enum ReportMetric: String, CaseIterable, Identifiable {
    case done      // ore VERIFICATE: contano solo gli impegni che hai confermato (o misurato con "Avvia")
    case planned   // ore pianificate (tutti gli impegni della settimana)
    var id: String { rawValue }
}

struct PeriodReport {
    var start: Date
    var dayCount: Int                               // 7 per la settimana, 28-31 per il mese
    var totals: [EventCategory: TimeInterval]
    var daily: [[EventCategory: TimeInterval]]      // un elemento per giorno, a partire da `start`
    var plannedChecked: TimeInterval                // ore previste degli impegni finiti e verificati
    var actualChecked: TimeInterval                 // ore realmente svolte in quegli impegni
    var unverified: Int                             // impegni finiti senza esito
    var total: TimeInterval { totals.values.reduce(0, +) }

    /// Quanto di ciò che avevi programmato hai davvero svolto (0...1)
    var completionRate: Double? {
        plannedChecked > 0 ? min(1, actualChecked / plannedChecked) : nil
    }
}

typealias WeekReport = PeriodReport

enum ReportCalculator {

    /// Ore per categoria in un periodo (settimana o mese).
    /// - Svolte: solo impegni con un esito (Fatto / In parte, o misurati con Avvia/Termina). I "Non fatto" valgono 0.
    /// - Due impegni sovrapposti della stessa categoria non contano doppio.
    /// - Gli eventi "tutto il giorno" non contano.
    static func report(start periodStart: Date, dayCount: Int, events: [Event], metric: ReportMetric,
                       now: Date = .now, cal: Calendar = .current) -> PeriodReport {
        let periodEnd = cal.date(byAdding: .day, value: dayCount, to: periodStart) ?? periodStart

        var perCategory: [EventCategory: [(start: Date, end: Date)]] = [:]
        var plannedChecked: TimeInterval = 0
        var actualChecked: TimeInterval = 0
        var unverified = 0

        for e in events where !e.isAllDay {
            // 1) intervallo da contare, secondo la metrica
            var interval: (start: Date, end: Date)?
            switch metric {
            case .planned:
                interval = (e.start, e.end)
            case .done:
                if let t = e.trackingStart {
                    interval = (t, now)                                   // in corso adesso
                } else if let c = e.completion, c.status != .skipped, c.actualMinutes > 0 {
                    interval = (e.start, e.start.addingTimeInterval(TimeInterval(c.actualMinutes) * 60))
                }
            }
            if let iv = interval {
                let s = max(iv.start, periodStart)
                let t = min(iv.end, periodEnd)
                if t > s { perCategory[e.category, default: []].append((s, t)) }
            }

            // 2) statistiche di completamento: impegni finiti in questa settimana
            if e.end > periodStart && e.end <= periodEnd && e.end <= now {
                if let c = e.completion {
                    plannedChecked += e.duration
                    actualChecked += min(e.duration, TimeInterval(c.actualMinutes) * 60)
                } else if e.trackingStart == nil {
                    unverified += 1
                }
            }
        }

        var totals: [EventCategory: TimeInterval] = [:]
        var daily = Array(repeating: [EventCategory: TimeInterval](), count: dayCount)

        for (category, list) in perCategory {
            var merged: [(start: Date, end: Date)] = []
            for iv in list.sorted(by: { $0.start < $1.start }) {
                if let last = merged.last, iv.start <= last.end {
                    merged[merged.count - 1].end = max(last.end, iv.end)
                } else {
                    merged.append(iv)
                }
            }
            for iv in merged {
                totals[category, default: 0] += iv.end.timeIntervalSince(iv.start)
                for d in 0..<dayCount {
                    guard let dayStart = cal.date(byAdding: .day, value: d, to: periodStart),
                          let dayEnd = cal.date(byAdding: .day, value: d + 1, to: periodStart) else { continue }
                    let overlap = min(iv.end, dayEnd).timeIntervalSince(max(iv.start, dayStart))
                    if overlap > 0 { daily[d][category, default: 0] += overlap }
                }
            }
        }
        return PeriodReport(start: periodStart, dayCount: dayCount, totals: totals, daily: daily,
                          plannedChecked: plannedChecked, actualChecked: actualChecked, unverified: unverified)
    }
}
