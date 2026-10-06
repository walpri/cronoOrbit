import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

#if os(iOS)

// MARK: - Assistente AI (Apple Foundation Models: gira sul dispositivo, gratis e senza chiavi)
// L'AI capisce la frase dell'utente. Orari, conflitti e modifiche li gestisce il codice (`Scheduler`),
// così l'AI non può sbagliare un orario né eliminare nulla senza la tua conferma.

enum AssistantAction { case add, edit, delete, list, free }

struct ParsedRequest {
    var action: AssistantAction
    var title: String                       // add: titolo nuovo · edit/delete: parole chiave dell'impegno esistente
    var targetDay: Date? = nil              // edit/delete: giorno dell'impegno esistente
    var newTitle: String? = nil             // edit: nuovo titolo
    var category: EventCategory? = nil      // nil = non indicata
    var duration: TimeInterval? = nil       // nil = non indicata
    var day: Date? = nil                    // giorno richiesto (nuovo)
    var time: (hour: Int, minute: Int)? = nil
    var shift: TimeInterval? = nil          // edit: sposta l'inizio avanti/indietro ("posticipa di mezz'ora")
    var durationDelta: TimeInterval? = nil  // edit: allunga/accorcia di tot
    var altTitle: String? = nil             // parole chiave alternative per trovare l'impegno
}

enum AssistantError: Error { case unavailable }

@MainActor
final class AssistantService {

    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            if case .available = SystemLanguageModel.default.availability { return true }
        }
        #endif
        return false
    }

    func parse(_ text: String, now: Date = .now) async throws -> ParsedRequest {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) { return try await parseWithModel(text, now: now) }
        #endif
        throw AssistantError.unavailable
    }
}

#if canImport(FoundationModels)

@available(iOS 26, *)
@Generable
struct GeneratedRequest {
    @Guide(description: "Azione: add = aggiungere un nuovo impegno, edit = modificare o spostare un impegno esistente, delete = eliminare un impegno esistente",
           .anyOf(["add", "edit", "delete"]))
    var action: String
    @Guide(description: "Se add: titolo breve del nuovo impegno. Se edit o delete: poche parole chiave dell'impegno ESISTENTE (es. palestra). Stessa lingua dell'utente")
    var title: String
    @Guide(description: "Solo per edit o delete: giorno dell'impegno esistente nel formato yyyy-MM-dd, vuoto se non indicato")
    var targetDate: String
    @Guide(description: "Solo per edit: nuovo titolo se l'utente chiede di rinominare, altrimenti vuoto")
    var newTitle: String
    @Guide(description: "Categoria indicata, oppure nessuna", .anyOf(["Focus", "Salute", "Lavoro", "Sociale", "nessuna"]))
    var category: String
    @Guide(description: "Durata in minuti. 0 se non specificata", .range(0...480))
    var durationMinutes: Int
    @Guide(description: "Giorno richiesto (nuovo giorno) nel formato yyyy-MM-dd, vuoto se non indicato")
    var date: String
    @Guide(description: "Ora richiesta (nuova ora) nel formato HH:mm a 24 ore, vuota se non indicata")
    var time: String
}

@available(iOS 26, *)
extension AssistantService {
    func parseWithModel(_ text: String, now: Date) async throws -> ParsedRequest {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd (EEEE) HH:mm"

        let session = LanguageModelSession(instructions: """
        Sei l'assistente di un'app calendario. Capisci se l'utente vuole aggiungere (add), modificare o spostare (edit) \
        oppure eliminare (delete) un impegno.
        Adesso è \(f.string(from: now)).
        Trasforma "oggi", "domani", "dopodomani" e i giorni della settimana in una data yyyy-MM-dd rispetto a adesso.
        Per edit e delete "title" contiene solo le parole chiave dell'impegno già esistente, "targetDate" è il suo giorno.
        Per edit "date" e "time" sono il NUOVO giorno e la NUOVA ora, "durationMinutes" è la nuova durata.
        Lascia vuoti i campi non indicati. durationMinutes = 0 se non indicata. category = nessuna se non indicata.
        """)
        let g = try await session.respond(to: text, generating: GeneratedRequest.self).content

        let cal = Calendar.current
        var day = Self.parseDay(g.date)
        if let d = day, d < cal.startOfDay(for: now) { day = nil }   // ignora date nel passato

        let action: AssistantAction = g.action == "edit" ? .edit : (g.action == "delete" ? .delete : .add)
        let newTitle = g.newTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        return ParsedRequest(
            action: action,
            title: g.title.trimmingCharacters(in: .whitespacesAndNewlines),
            targetDay: Self.parseDay(g.targetDate),
            newTitle: newTitle.isEmpty ? nil : newTitle,
            category: EventCategory(rawValue: g.category),
            duration: g.durationMinutes > 0 ? TimeInterval(g.durationMinutes * 60) : nil,
            day: day,
            time: Self.parseTime(g.time))
    }

    static func parseDay(_ s: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: s.trimmingCharacters(in: .whitespaces))
    }

    static func parseTime(_ s: String) -> (hour: Int, minute: Int)? {
        let p = s.split(separator: ":").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        guard p.count == 2, (0..<24).contains(p[0]), (0..<60).contains(p[1]) else { return nil }
        return (p[0], p[1])
    }
}

#endif
#endif
