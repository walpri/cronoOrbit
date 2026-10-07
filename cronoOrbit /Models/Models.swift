import SwiftUI
import Observation

enum EventCategory: String, CaseIterable, Identifiable, Codable {
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
    /// Nome tradotto come String (grafici e testi composti)
    var title: String { Bundle.main.localizedString(forKey: rawValue, value: rawValue, table: nil) }
    var color: Color {
        switch self {
        case .focus:  Color(red: 0.56, green: 0.69, blue: 1.0)
        case .health: Color(red: 0.49, green: 1.0, blue: 0.70)
        case .work:   Color(red: 1.0, green: 0.82, blue: 0.40)
        case .social: Color(red: 1.0, green: 0.62, blue: 0.78)
        }
    }
}

/// Come è andato un impegno
enum CompletionStatus: String, Codable, Hashable { case done, partial, skipped }

struct EventCompletion: Codable, Hashable {
    var status: CompletionStatus
    var actualMinutes: Int          // minuti realmente svolti
    var checkedAt = Date.now
}

struct Event: Identifiable, Hashable, Codable {
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
    /// Esito dichiarato o misurato (nil = ancora da verificare)
    var completion: EventCompletion? = nil
    /// Quando hai premuto "Avvia" (nil = non in corso)
    var trackingStart: Date? = nil
    
    /// Vero se l'esito è già stato dichiarato o misurato
    var isCompleted: Bool { completion != nil }
    
    var startMinutes: Double { Event.minutes(start) }
    var endMinutes: Double { Event.minutes(end) }
    var duration: TimeInterval { end.timeIntervalSince(start) }
    /// Eventi "tutto il giorno" (compleanni, festività…): non si verificano
    var isAllDay: Bool { duration >= 20 * 3600 }

    static func minutes(_ d: Date) -> Double {
        let c = Calendar.current
        return Double(c.component(.hour, from: d) * 60 + c.component(.minute, from: d))
    }
}

extension Event {
    /// Frasi mostrate dopo aver confermato un impegno (iPhone e Apple Watch)
    static var motivationalQuotes: [String] {
        [
            String(localized: "Ottimo lavoro! Un passo alla volta."),
            String(localized: "Un impegno in meno, un obiettivo più vicino."),
            String(localized: "Costanza batte talento. Continua così!"),
            String(localized: "Bravo! Ora goditi una pausa meritata."),
            String(localized: "Ogni impegno rispettato conta.")
        ]
    }
}

extension TimeInterval {
    /// Es. "2h 30m"
    var hm: String {
        let m = max(0, Int(self / 60))
        return "\(m / 60)h " + String(format: "%02d", m % 60) + "m"
    }
}

/// Esito di un impegno inviato dall'Apple Watch all'iPhone
struct CompletionUpdate: Codable, Hashable {
    var id: Event.ID
    var completion: EventCompletion
}

@Observable
final class EventStore {
    var events: [Event] = []
    /// Eventi importati che l'utente ha eliminato: non vanno reimportati
    private(set) var ignoredExternalIDs = Set<String>()
    /// Medaglie attualmente vinte (serve a riconoscere quando una vittoria viene annullata)
    private(set) var awardedMedals = Set<String>()
    /// Medaglie annullate perché un impegno non è stato confermato in tempo
    private(set) var medalAlerts: [MedalAlert] = []

    init() {
        if let snap = Self.load() {
            events = snap.events
            ignoredExternalIDs = Set(snap.ignored)
            awardedMedals = Set(snap.medals ?? [])
            medalAlerts = snap.alerts ?? []
        } else {
            events = EventStore.sample()       // solo al primo avvio
        }
    }

    func events(on day: Date) -> [Event] {
        events.filter { Calendar.current.isDate($0.start, inSameDayAs: day) }
              .sorted { $0.start < $1.start }
    }
    func event(_ id: Event.ID) -> Event? { events.first { $0.id == id } }

    func add(_ e: Event) { events.append(e); persist() }

    func delete(_ id: Event.ID) {
        if let ext = event(id)?.externalID { ignoredExternalIDs.insert(ext) }
        events.removeAll { $0.id == id }
        persist()
    }

    func update(_ e: Event) {
        if let i = events.firstIndex(where: { $0.id == e.id }) { events[i] = e }
        persist()
    }

    /// Aggiunge solo gli eventi non ancora importati. Ritorna quanti ne ha aggiunti.
    @discardableResult
    func importEvents(_ new: [Event]) -> Int {
        let known = Set(events.compactMap(\.externalID)).union(ignoredExternalIDs)
        let fresh = new.filter { $0.externalID.map { !known.contains($0) } ?? true }
        events.append(contentsOf: fresh)
        if !fresh.isEmpty { persist() }
        return fresh.count
    }

    // MARK: Verifica degli impegni svolti

    /// Impegni finiti negli ultimi 7 giorni di cui non hai ancora confermato l'esito.
    func toVerify(now: Date = .now) -> [Event] {
        let from = now.addingTimeInterval(-7 * 86_400)
        let list = events.filter {
            $0.end <= now && $0.end >= from && $0.completion == nil && $0.trackingStart == nil && !$0.isAllDay
        }
        let awaiting = list.filter { $0.isAwaitingVerification(now: now) }.sorted { $0.end < $1.end }   // scade prima
        let expired = list.filter { !$0.isAwaitingVerification(now: now) }.sorted { $0.end > $1.end }
        return awaiting + expired
    }

    /// "Avvia": da adesso il tempo viene misurato.
    func startTracking(_ id: Event.ID, at date: Date = .now) {
        guard var e = event(id) else { return }
        e.trackingStart = date
        e.completion = nil
        update(e)
    }

    /// "Termina": salva i minuti realmente trascorsi. Da 80% della durata prevista in su vale "svolto".
    func stopTracking(_ id: Event.ID, at date: Date = .now) {
        guard var e = event(id), let started = e.trackingStart else { return }
        let minutes = max(1, Int(date.timeIntervalSince(started) / 60))
        let planned = max(1, Int(e.duration / 60))
        e.completion = EventCompletion(status: minutes * 100 >= planned * 80 ? .done : .partial, actualMinutes: minutes)
        e.trackingStart = nil
        update(e)
    }

    /// Esito dichiarato a mano (o dalla notifica).
    /// Se l'impegno è in corso, i minuti sono quelli realmente trascorsi (da "Avvia" o dall'inizio) e il timer si ferma.
    func setCompletion(_ id: Event.ID, status: CompletionStatus, minutes: Int? = nil, now: Date = .now) {
        guard var e = event(id) else { return }
        let planned = max(1, Int(e.duration / 60))
        let inProgress = e.start <= now && now < e.end
        let from = e.trackingStart ?? e.start
        let elapsed = max(1, Int(now.timeIntervalSince(from) / 60))
        let actual: Int
        switch status {
        case .done:    actual = minutes ?? (inProgress ? elapsed : planned)
        case .partial: actual = minutes ?? (inProgress ? elapsed : max(1, planned / 2))
        case .skipped: actual = 0
        }
        e.completion = EventCompletion(status: status, actualMinutes: actual)
        e.trackingStart = nil
        update(e)
    }

    /// Esiti arrivati dall'Apple Watch. Non sovrascrive un esito già presente sull'iPhone.
        func applyCompletions(_ updates: [CompletionUpdate]) {
            var changed = false
            for u in updates {
                guard let i = events.firstIndex(where: { $0.id == u.id }), events[i].completion == nil else { continue }
                events[i].completion = u.completion
                events[i].trackingStart = nil
                changed = true
            }
            if changed { persist() }
        }
    
    func clearCompletion(_ id: Event.ID) {
        guard var e = event(id) else { return }
        e.completion = nil
        e.trackingStart = nil
        update(e)
    }

    // MARK: Medaglie

    /// Ricalcola le medaglie. Una vittoria si annulla se un impegno che la sosteneva
    /// non è stato confermato entro 15 minuti dalla sua fine.
    func refreshMedals(now: Date = .now) {
        var changed = false
        for medal in Medal.allCases {
            let wins = medal.progress(in: events, now: now).isWon
            if wins && !awardedMedals.contains(medal.rawValue) {
                awardedMedals.insert(medal.rawValue)
                changed = true
            } else if !wins && awardedMedals.contains(medal.rawValue) {
                awardedMedals.remove(medal.rawValue)
                // l'impegno scaduto che ha fatto perdere la medaglia
                let culprit = events
                    .filter { medal.accepts($0) && $0.isVerificationExpired(now: now) }
                    .max { $0.end < $1.end }
                if let culprit {
                    medalAlerts.append(MedalAlert(medalRaw: medal.rawValue, eventTitle: culprit.title, date: now))
                }
                changed = true
            }
        }
        if changed { persist() }
    }

    func dismissMedalAlert(_ id: MedalAlert.ID) {
        medalAlerts.removeAll { $0.id == id }
        persist()
    }

    // MARK: Salvataggio su disco (gli impegni restano anche dopo aver chiuso l'app)

    private struct Snapshot: Codable {
        var events: [Event]
        var ignored: [String]
        var medals: [String]?
        var alerts: [MedalAlert]?
    }

    private static var fileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("events.json")
    }

    private static func load() -> Snapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }

    private func persist() {
        let snap = Snapshot(events: events, ignored: Array(ignoredExternalIDs),
                            medals: Array(awardedMedals), alerts: medalAlerts)
        if let data = try? JSONEncoder().encode(snap) { try? data.write(to: Self.fileURL, options: .atomic) }
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

// MARK: - Scadenza di verifica (15 minuti) e medaglie

/// Quanto vale un impegno per le medaglie
enum MedalCredit { case none, provisional, confirmed }

extension Event {
    /// Dopo la fine hai 15 minuti per confermare l'esito
    static let verificationWindow: TimeInterval = 15 * 60

    var verifyDeadline: Date { end.addingTimeInterval(Event.verificationWindow) }

    /// Finito da meno di 15 minuti e senza esito: puoi ancora confermarlo in tempo
    func isAwaitingVerification(now: Date = .now) -> Bool {
        !isAllDay && completion == nil && trackingStart == nil && end <= now && now <= verifyDeadline
    }

    /// Passati 15 minuti dalla fine senza esito: non conta più per le medaglie
    func isVerificationExpired(now: Date = .now) -> Bool {
        !isAllDay && completion == nil && trackingStart == nil && now > verifyDeadline
    }

    /// Solo gli impegni "Fatto" e confermati in tempo contano per le medaglie.
    /// Mentre i 15 minuti scorrono il credito è provvisorio.
    func medalCredit(now: Date = .now) -> MedalCredit {
        if let c = completion {
            return (c.status == .done && c.checkedAt <= verifyDeadline) ? .confirmed : .none
        }
        return isAwaitingVerification(now: now) ? .provisional : .none
    }
}

enum Medal: String, CaseIterable, Identifiable, Codable {
    case study, sport, deepFocus
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .study:     "Study"
        case .sport:     "Sport"
        case .deepFocus: "Deep Focus"
        }
    }

    /// Impegni confermati necessari per vincere la medaglia
    var goal: Int {
        switch self {
        case .study:     3
        case .sport:     2
        case .deepFocus: 2
        }
    }

    /// Questo impegno vale per la medaglia?
    func accepts(_ e: Event) -> Bool {
        switch self {
        case .study:     return e.category == .work || e.category == .focus
        case .sport:     return e.category == .health
        case .deepFocus: return e.category == .focus && e.duration >= 3600
        }
    }

    func progress(in events: [Event], now: Date = .now) -> MedalProgress {
        var confirmed = 0, provisional = 0
        for e in events where accepts(e) {
            switch e.medalCredit(now: now) {
            case .confirmed:   confirmed += 1
            case .provisional: provisional += 1
            case .none:        break
            }
        }
        return MedalProgress(confirmed: confirmed, provisional: provisional, goal: goal)
    }
}

struct MedalProgress {
    var confirmed: Int
    var provisional: Int
    var goal: Int
    var total: Int { confirmed + provisional }
    var isWon: Bool { total >= goal }
    /// Vinta, ma solo grazie a impegni che aspettano ancora la conferma
    var isProvisional: Bool { isWon && confirmed < goal }
}

struct MedalAlert: Codable, Identifiable, Hashable {
    var id = UUID()
    var medalRaw: String
    var eventTitle: String
    var date: Date
    var medalName: String { Medal(rawValue: medalRaw)?.displayName ?? medalRaw }
}
