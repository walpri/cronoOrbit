import SwiftUI
import Observation

#if os(iOS)

struct EventDraft {
    var title: String
    var category: EventCategory
}

/// Modifiche da applicare a un impegno esistente
struct EventChanges {
    var title: String? = nil
    var category: EventCategory? = nil
    var slot: TimeSlot? = nil
}

/// Pulsante sotto un messaggio dell'assistente
struct ChatAction: Identifiable {
    enum Kind {
        case add(EventDraft, TimeSlot)
        case update(Event.ID, EventChanges)
        case delete(Event.ID)
        case chooseTarget(Event.ID, ParsedRequest)   // scegli su quale impegno agire
        case dismiss
    }
    let id = UUID()
    var label: String
    var icon: String
    var destructive = false
    var kind: Kind
}

struct ChatMessage: Identifiable {
    enum Role { case user, assistant }
    let id = UUID()
    let role: Role
    var text: String
    var actions: [ChatAction] = []
}

@Observable @MainActor
final class AssistantViewModel {
    var messages: [ChatMessage] = []
    var isWorking = false
    /// Durata usata quando l'AI del dispositivo non è disponibile
    var defaultMinutes = 60

    /// Ultimo impegno di cui si sta parlando: "spostalo alle 15" si riferisce a lui
    private var focusedEventID: Event.ID?
    /// Ho chiesto "cosa vuoi cambiare?": il prossimo messaggio è la modifica
    private var awaitingChange = false

    private let scheduler = Scheduler()
    private let service = AssistantService()

    init() {
        let greeting = AssistantService.isAvailable
            ? String(localized: "Ciao! Posso mostrarti l'agenda e aggiungere, spostare o eliminare impegni. Prova: «Che impegni ho domani?», «Sposta la palestra alle 19» o «Elimina l'aperitivo».")
            : String(localized: "L'AI del dispositivo non è disponibile, uso la comprensione di base. Prova: «Che impegni ho domani?», «Sposta la palestra alle 19» o «Elimina la palestra».")
        messages = [ChatMessage(role: .assistant, text: greeting)]
    }

    // MARK: - Richiesta in linguaggio naturale

    func send(_ text: String, store: EventStore) async {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, !isWorking else { return }
        messages.append(ChatMessage(role: .user, text: t))
        isWorking = true
        defer { isWorking = false }

        let cal = Calendar.current
        let local = LocalParser.parse(t)

        // Domande sull'agenda: nessun bisogno dell'AI
        switch local.action {
        case .list:
            awaitingChange = false
            showList(on: local.day ?? cal.startOfDay(for: .now), store: store)
            return
        case .free:
            awaitingChange = false
            showFree(on: local.day ?? cal.startOfDay(for: .now), store: store)
            return
        default:
            break
        }

        // Risposta a "Cosa vuoi cambiare?": il messaggio è la modifica dell'impegno in discussione
        if awaitingChange, local.action == .add {
            awaitingChange = false
            var r = local
            r.action = .edit
            if r.time == nil && r.day == nil && r.duration == nil && !r.title.isEmpty { r.newTitle = r.title }
            r.title = ""
            targetThen(r, store: store)
            return
        }
        awaitingChange = false

        var request = local
        if AssistantService.isAvailable, var ai = try? await service.parse(t) {
            if local.action != .add {
                // Verbo esplicito (sposta, elimina…): decide il parser locale. L'AI aiuta solo con titolo e nuovo titolo.
                ai.action = local.action
                ai.altTitle = local.title.isEmpty ? nil : local.title
                if ai.title.trimmingCharacters(in: .whitespaces).isEmpty { ai.title = local.title }
                ai.newTitle = local.newTitle ?? ai.newTitle
                ai.targetDay = local.targetDay
                ai.day = local.day
                ai.time = local.time
                ai.shift = local.shift
                ai.durationDelta = local.durationDelta
                ai.duration = local.duration
                request = ai
            } else if ai.action != .add, !EventMatcher.find(ai.title, day: nil, in: store.events).isEmpty {
                // Nessun verbo, ma l'AI ha capito che parli di un impegno che esiste già ("la palestra la voglio alle 19")
                request = ai
            } else {
                ai.action = .add
                request = ai
            }
        } else if request.action == .add, request.duration == nil, !AssistantService.isAvailable {
            request.duration = TimeInterval(defaultMinutes * 60)
        }

        switch request.action {
        case .add:               add(request, store: store)
        case .edit, .delete:     targetThen(request, store: store)
        case .list, .free:       break
        }
    }

    // MARK: - Nuovo impegno

    private func add(_ r: ParsedRequest, store: EventStore) {
        let cal = Calendar.current
        let now = Date.now
        let title = r.title.isEmpty ? String(localized: "Nuovo evento") : r.title
        let duration = r.duration ?? 3600
        let draft = EventDraft(title: title, category: r.category ?? .focus)
        let plan: SchedulePlan

        if let time = r.time {
            let base = r.day ?? cal.startOfDay(for: now)
            let start = cal.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: base) ?? now
            plan = scheduler.plan(duration: duration, preferredStart: start, events: store.events, now: now)
        } else {
            let day = r.day ?? cal.startOfDay(for: now)
            let morning = cal.date(bySettingHour: scheduler.dayStartHour, minute: 0, second: 0, of: day) ?? day
            plan = scheduler.suggestions(duration: duration, near: max(now, morning), events: store.events, now: now)
        }

        switch plan {
        case .free(let slot):
            say(String(localized: "Sei libero \(slotLabel(slot)). Lo aggiungo?"),
                [addAction(draft, slot), cancelAction()])

        case .conflict(let clash, let alternatives):
            let time = clash[0].start.formatted(date: .omitted, time: .shortened)
            let names = clash.map(\.title).joined(separator: ", ")
            say(String(localized: "Alle \(time) sei già impegnato: \(names). Ti propongo questi orari liberi:"),
                alternatives.map { addAction(draft, $0) })

        case .suggestions(let slots):
            say(String(localized: "Ecco i primi orari liberi per «\(title)»:"),
                slots.map { addAction(draft, $0) })

        case .noRoom:
            say(String(localized: "Non trovo uno spazio libero di \(Int(duration / 60)) minuti nei prossimi 7 giorni."))
        }
    }

    // MARK: - Trova l'impegno da modificare o eliminare

    private func targetThen(_ r: ParsedRequest, store: EventStore) {
        let query = r.title.trimmingCharacters(in: .whitespaces)
        var matches: [Event] = []

        if !query.isEmpty || r.targetDay != nil {
            matches = EventMatcher.find(query, day: r.targetDay, in: store.events)
            if matches.isEmpty, let alt = r.altTitle {
                matches = EventMatcher.find(alt, day: r.targetDay, in: store.events)
            }
            if matches.isEmpty, r.targetDay != nil {                 // il giorno indicato potrebbe essere sbagliato
                matches = EventMatcher.find(query, day: nil, in: store.events)
            }
        } else if let id = focusedEventID, let e = store.events.first(where: { $0.id == id }) {
            matches = [e]                                            // "spostalo alle 15"
        }

        switch matches.count {
        case 0:
            // Mai un vicolo cieco: mostra i prossimi impegni e fai scegliere
            let upcoming = EventMatcher.upcoming(in: store.events)
            if upcoming.isEmpty {
                say(String(localized: "Non hai impegni in agenda."))
            } else {
                let text = query.isEmpty
                    ? String(localized: "Quale impegno intendi?")
                    : String(localized: "Non ho trovato «\(query)». Quale di questi impegni intendi?")
                say(text, upcoming.map { chooseAction($0, r) } + [cancelAction()])
            }
        case 1:
            focusedEventID = matches[0].id
            apply(r, to: matches[0], store: store)
        default:
            say(String(localized: "Quale impegno intendi?"), matches.map { chooseAction($0, r) } + [cancelAction()])
        }
    }

    private func apply(_ r: ParsedRequest, to e: Event, store: EventStore) {
        focusedEventID = e.id
        switch r.action {
        case .delete: askDelete(e)
        default:      edit(e, r, store: store)
        }
    }

    // MARK: - Eliminare

    private func askDelete(_ e: Event) {
        say(String(localized: "Vuoi eliminare «\(e.title)» (\(slotLabel(TimeSlot(start: e.start, end: e.end))))?"),
            [ChatAction(label: String(localized: "Elimina"), icon: "trash", destructive: true, kind: .delete(e.id)),
             cancelAction()])
    }

    // MARK: - Modificare

    private func edit(_ e: Event, _ r: ParsedRequest, store: EventStore) {
        let cal = Calendar.current
        var changes = EventChanges()
        if let t = r.newTitle, t != e.title { changes.title = t }
        if let c = r.category, c != e.category { changes.category = c }

        let newDuration: TimeInterval? = r.duration ?? r.durationDelta.map { max(900, e.duration + $0) }
        let timeChanged = r.day != nil || r.time != nil || r.shift != nil
        let durationChanged = newDuration.map { abs($0 - e.duration) > 59 } ?? false

        // Solo titolo o categoria: nessun controllo di orari
        guard timeChanged || durationChanged else {
            if changes.title == nil && changes.category == nil {
                awaitingChange = true       // il prossimo messaggio sarà la modifica
                say(String(localized: "Cosa vuoi cambiare di «\(e.title)»? Dimmi un nuovo orario, una nuova durata o un nuovo titolo."))
            } else {
                say(String(localized: "Aggiorno «\(e.title)» con le modifiche richieste. Confermi?"),
                    [updateAction(e.id, changes, label: String(localized: "Conferma")), cancelAction()])
            }
            return
        }

        // Nuovo orario: stesso giorno/ora di prima se non indicati
        let start: Date
        if r.day == nil, r.time == nil, let shift = r.shift {
            start = e.start.addingTimeInterval(shift)               // "posticipa di mezz'ora"
        } else {
            let old = cal.dateComponents([.hour, .minute], from: e.start)
            let baseDay = r.day ?? cal.startOfDay(for: e.start)
            let hm = r.time ?? (hour: old.hour ?? 0, minute: old.minute ?? 0)
            start = cal.date(bySettingHour: hm.hour, minute: hm.minute, second: 0, of: baseDay) ?? e.start
        }
        let duration = newDuration ?? e.duration
        let end = start.addingTimeInterval(duration)

        let others = store.events.filter { $0.id != e.id }          // l'impegno non è in conflitto con sé stesso
        let clash = scheduler.conflicts(start: start, end: end, in: others)

        if clash.isEmpty {
            var c = changes
            let slot = TimeSlot(start: start, end: end)
            c.slot = slot
            say(String(localized: "Sposto «\(e.title)»: \(slotLabel(slot)). Confermi?"),
                [updateAction(e.id, c, label: String(localized: "Conferma")), cancelAction()])
        } else {
            let alts = scheduler.alternatives(duration: duration, near: start, events: others,
                                              now: .now, daysAhead: 7)
            if alts.isEmpty {
                say(String(localized: "Non trovo uno spazio libero per «\(e.title)» nei prossimi 7 giorni."))
            } else {
                let names = clash.map(\.title).joined(separator: ", ")
                say(String(localized: "Quell'orario è occupato da \(names). Ti propongo questi orari liberi per «\(e.title)»:"),
                    alts.map { slot in
                        var c = changes
                        c.slot = slot
                        return updateAction(e.id, c, label: slotLabel(slot))
                    } + [cancelAction()])
            }
        }
    }

    // MARK: - Esegue un pulsante

    func perform(_ action: ChatAction, in messageID: UUID, store: EventStore) {
        if let i = messages.firstIndex(where: { $0.id == messageID }) { messages[i].actions = [] }

        switch action.kind {
        case .add(let draft, let slot):
            store.add(Event(title: draft.title, category: draft.category,
                            start: slot.start, end: slot.end, invited: ["Tu"]))
            say(String(localized: "Fatto! Ho aggiunto «\(draft.title)» \(slotLabel(slot))"))

        case .delete(let id):
            guard let e = store.events.first(where: { $0.id == id }) else { return gone() }
            store.delete(id)
            if focusedEventID == id { focusedEventID = nil }
            say(String(localized: "Fatto! Ho eliminato «\(e.title)»."))

        case .update(let id, let changes):
            guard var e = store.events.first(where: { $0.id == id }) else { return gone() }
            if let t = changes.title, !t.isEmpty { e.title = t }
            if let c = changes.category { e.category = c }
            if let s = changes.slot { e.start = s.start; e.end = s.end }
            store.update(e)
            focusedEventID = id
            say(String(localized: "Fatto! Ho aggiornato «\(e.title)»: \(slotLabel(TimeSlot(start: e.start, end: e.end)))"))

        case .chooseTarget(let id, let request):
            guard let e = store.events.first(where: { $0.id == id }) else { return gone() }
            apply(request, to: e, store: store)

        case .dismiss:
            awaitingChange = false
            say(String(localized: "Va bene, non cambio nulla."))
        }
    }

    // MARK: - Domande sull'agenda

    /// "Che impegni ho oggi?"
    func showList(on day: Date, store: EventStore, echo: String? = nil) {
        if let echo { messages.append(ChatMessage(role: .user, text: echo)) }
        let events = store.events(on: day)
        let label = day.formatted(.dateTime.weekday(.wide).day().month(.wide))

        guard !events.isEmpty else {
            say(String(localized: "Non hai impegni in programma: \(label)."))
            return
        }
        let lines = events.map {
            "\($0.start.formatted(date: .omitted, time: .shortened))–\($0.end.formatted(date: .omitted, time: .shortened)) · \($0.title)"
        }.joined(separator: "\n")

        say(String(localized: "Impegni di \(label):") + "\n" + lines + "\n\n" + String(localized: "Tocca un impegno per modificarlo o eliminarlo."),
            events.map { ChatAction(label: $0.title, icon: "pencil",
                                    kind: .chooseTarget($0.id, ParsedRequest(action: .edit, title: ""))) })
    }

    /// "Quando sono libero?"
    func showFree(on day: Date, store: EventStore, echo: String? = nil) {
        if let echo { messages.append(ChatMessage(role: .user, text: echo)) }
        let slots = scheduler.freeSlots(on: day, in: store.events, minDuration: 30 * 60, after: .now)
        let label = day.formatted(.dateTime.weekday(.wide).day().month(.wide))

        if slots.isEmpty {
            say(String(localized: "Non hai spazi liberi di almeno 30 minuti."))
        } else {
            let list = slots.map {
                "\($0.start.formatted(date: .omitted, time: .shortened))–\($0.end.formatted(date: .omitted, time: .shortened))"
            }.joined(separator: "\n")
            say(String(localized: "Spazi liberi, \(label):") + "\n" + list)
        }
    }

    // MARK: - Utilità

    private func say(_ text: String, _ actions: [ChatAction] = []) {
        messages.append(ChatMessage(role: .assistant, text: text, actions: actions))
    }

    private func gone() { say(String(localized: "Questo impegno non esiste più.")) }

    private func eventLabel(_ e: Event) -> String {
        "\(e.title) · \(slotLabel(TimeSlot(start: e.start, end: e.end)))"
    }

    private func chooseAction(_ e: Event, _ r: ParsedRequest) -> ChatAction {
        ChatAction(label: eventLabel(e), icon: "calendar", kind: .chooseTarget(e.id, r))
    }

    private func addAction(_ d: EventDraft, _ s: TimeSlot) -> ChatAction {
        ChatAction(label: slotLabel(s), icon: "plus.circle.fill", kind: .add(d, s))
    }

    private func updateAction(_ id: Event.ID, _ c: EventChanges, label: String) -> ChatAction {
        ChatAction(label: label, icon: "checkmark.circle.fill", kind: .update(id, c))
    }

    private func cancelAction() -> ChatAction {
        ChatAction(label: String(localized: "Annulla"), icon: "xmark.circle", kind: .dismiss)
    }
}

#endif
