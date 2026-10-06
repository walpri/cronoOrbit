import Foundation

#if os(iOS)

// MARK: - Comprensione "di base" delle frasi, senza AI (italiano e inglese)
// Serve in tre casi: AI non disponibile, AI che sbaglia il tipo di azione, AI che dà errore.
// Capisce verbo (aggiungi / sposta / elimina…), giorno, ora, durata, spostamenti ("posticipa di mezz'ora").

enum LocalParser {

    // MARK: Regex helpers

    /// Minuscolo e senza accenti ("Lunedì" -> "lunedi")
    private static func normalize(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }

    private struct Match { let groups: [String?]; let range: NSRange }

    private static func matches(_ pattern: String, in s: String) -> [Match] {
        guard let re = try? NSRegularExpression(pattern: pattern) else { return [] }
        let ns = s as NSString
        return re.matches(in: s, range: NSRange(location: 0, length: ns.length)).map { m in
            Match(groups: (0..<m.numberOfRanges).map { i in
                let r = m.range(at: i)
                return r.location == NSNotFound ? nil : ns.substring(with: r)
            }, range: m.range)
        }
    }

    private static func blank(_ ranges: [NSRange], in s: inout String) {
        var ns = s as NSString
        for r in ranges.sorted(by: { $0.location > $1.location }) {
            ns = ns.replacingCharacters(in: r, with: " ") as NSString
        }
        s = ns as String
    }

    private static func previousWord(before location: Int, in s: String) -> String {
        let head = (s as NSString).substring(to: location)
        return head.split(separator: " ").last.map(String.init) ?? ""
    }

    // MARK: Dati di supporto

    private enum Verb { case none, delete, edit, rename, lengthen, shorten, later, earlier }

    private static let verbPrefixes: [(Verb, [String])] = [
        (.delete,   ["elimin", "cancell", "rimuov", "togli", "delet", "remov", "cancel"]),
        (.rename,   ["rinomin", "renam"]),
        (.lengthen, ["allung", "prolung", "estend", "extend", "lengthen"]),
        (.shorten,  ["accorc", "riduc", "shorten", "reduc"]),
        (.later,    ["posticip", "ritard", "riman", "postpon", "delay"]),
        (.earlier,  ["anticip", "advanc"]),
        (.edit,     ["spost", "modific", "cambi", "aggiorn", "durar", "move", "moving", "resched", "chang", "edit", "updat"])
    ]

    private static let addVerbs: Set<String> = [
        "aggiungi", "aggiungere", "metti", "mettere", "segna", "segnare", "inserisci", "inserire",
        "crea", "creare", "fissa", "fissare", "programma", "programmare", "prenota", "prenotare",
        "ricordami", "add", "create", "schedule", "book", "put", "set", "new", "nuovo", "nuova"
    ]

    private static let fillers: Set<String> = [
        "il", "lo", "la", "le", "gli", "i", "l'", "un", "una", "uno", "un'",
        "di", "del", "dello", "della", "dei", "degli", "delle", "dell'",
        "a", "al", "allo", "alla", "ai", "agli", "alle", "all'", "in", "nel", "nella", "nell'",
        "su", "sul", "sulla", "sull'", "per", "con", "da", "dal", "dalla", "dalle", "fino",
        "e", "ed", "ma", "mi", "ti", "fai", "fare", "make", "puoi", "potresti", "vorrei", "voglio", "favore", "please",
        "the", "my", "to", "of", "at", "on", "for", "by", "and", "can", "you", "could", "from", "until",
        "impegno", "evento", "appuntamento", "titolo", "nome", "orario", "durata", "title", "name", "event", "appointment"
    ]

    private static let freeCues = ["quando sono libero", "sono libero", "ho tempo", "tempo libero", "spazi liberi", "spazio libero",
                                    "when am i free", "am i free", "free time", "free slots"]
    private static let listPhrases = ["che impegni", "quali impegni", "cosa ho", "cos'ho", "cosa c'e", "in programma",
                                      "what do i have", "what's on", "whats on", "am i busy", "sono impegnat",
                                      "my schedule", "my agenda", "la mia agenda", "il mio programma"]
    private static let listNouns = ["impegni", "appuntamenti", "agenda", "schedule", "plans", "calendario"]

    private static let numberWords: [String: Double] = ["due": 2, "two": 2, "tre": 3, "three": 3, "quattro": 4, "four": 4]

    private static let weekdays: [String: Int] = [
        "domenica": 1, "sunday": 1, "lunedi": 2, "monday": 2, "martedi": 3, "tuesday": 3,
        "mercoledi": 4, "wednesday": 4, "giovedi": 5, "thursday": 5, "venerdi": 6, "friday": 6,
        "sabato": 7, "saturday": 7
    ]

    private static let itMonths = ["gennaio", "febbraio", "marzo", "aprile", "maggio", "giugno",
                                   "luglio", "agosto", "settembre", "ottobre", "novembre", "dicembre"]
    private static let enMonths = ["january", "february", "march", "april", "may", "june",
                                   "july", "august", "september", "october", "november", "december"]

    // MARK: Parsing

    static func parse(_ text: String, now: Date = .now) -> ParsedRequest {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)

        var s = " " + normalize(text)
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "'", with: "' ") + " "

        var time: (hour: Int, minute: Int)?
        var duration: TimeInterval = 0
        var deltaPrep = false

        // 1) "dalle 15 alle 17"
        if let m = matches(#"\b(?:dalle|dall'|from)\s*(\d{1,2})(?:[:.](\d{2}))?\s*(?:alle|all'|a|to|until|-)\s*(\d{1,2})(?:[:.](\d{2}))?"#, in: s).first {
            let h1 = Int(m.groups[1] ?? "") ?? 0, m1 = Int(m.groups[2] ?? "") ?? 0
            let h2 = Int(m.groups[3] ?? "") ?? 0, m2 = Int(m.groups[4] ?? "") ?? 0
            if (0..<24).contains(h1), (0..<60).contains(m1) { time = (h1, m1) }
            let diff = (h2 * 60 + m2) - (h1 * 60 + m1)
            if diff > 0 { duration += TimeInterval(diff * 60) }
            blank([m.range], in: &s)
        }

        // 2) Ora: "alle 15", "alle 15:30", "at 3 pm", "ore 18"
        if time == nil,
           let m = matches(#"(?<![a-z])(?:alle ore|alle|all'|ore|at)\s*(\d{1,2})(?:[:.](\d{2}))?(?:\s*(am|pm)\b)?"#, in: s).first {
            var h = Int(m.groups[1] ?? "") ?? -1
            let mi = Int(m.groups[2] ?? "") ?? 0
            if m.groups[3] == "pm", h < 12 { h += 12 }
            if m.groups[3] == "am", h == 12 { h = 0 }
            if (0..<24).contains(h), (0..<60).contains(mi) {
                time = (h, mi)
                blank([m.range], in: &s)
            }
        }
        if time == nil, let m = matches(#"\b(\d{1,2}):(\d{2})\b"#, in: s).first,
           let h = Int(m.groups[1] ?? ""), let mi = Int(m.groups[2] ?? ""), (0..<24).contains(h), (0..<60).contains(mi) {
            time = (h, mi)
            blank([m.range], in: &s)
        }

        // 3) Durata: "mezz'ora", "un'ora", "due ore", "2 ore", "90 minuti"
        let durationRules: [(String, ([String?]) -> TimeInterval)] = [
            (#"mezz'?\s?ora|mezzora|half an hour|half hour"#, { _ in 1800 }),
            (#"\bun'?\s?ora\b|\ban hour\b|\bone hour\b"#, { _ in 3600 }),
            (#"\b(due|tre|quattro|two|three|four)\s+(?:ore|hours)\b"#, { g in (numberWords[g[1] ?? ""] ?? 0) * 3600 }),
            (#"(\d+(?:[.,]\d+)?)\s*(?:h|ore|ora|hours?|hrs?)\b"#, { g in (Double((g[1] ?? "").replacingOccurrences(of: ",", with: ".")) ?? 0) * 3600 }),
            (#"(\d+)\s*(?:min|minuti|minuto|minutes?)\b"#, { g in (Double(g[1] ?? "") ?? 0) * 60 })
        ]
        for (pattern, value) in durationRules {
            let ms = matches(pattern, in: s)
            guard !ms.isEmpty else { continue }
            for m in ms {
                let d = value(m.groups)
                if d > 0 {
                    duration += d
                    if ["di", "by"].contains(previousWord(before: m.range.location, in: s)) { deltaPrep = true }
                }
            }
            blank(ms.map { $0.range }, in: &s)
        }

        // 4) Giorni: oggi, domani, giovedì, "5 ottobre", "05/10"
        struct DayHit { let date: Date; let loc: Int; let prev: String }
        var hits: [DayHit] = []
        var dayRanges: [NSRange] = []
        var evening = false

        let dayWords = #"\b(dopodomani|domani|oggi|stasera|questa sera|today|tomorrow|tonight|this evening|lunedi|martedi|mercoledi|giovedi|venerdi|sabato|domenica|monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b"#
        for m in matches(dayWords, in: s) {
            let w = m.groups[1] ?? ""
            var date: Date?
            switch w {
            case "oggi", "today": date = today
            case "stasera", "questa sera", "tonight", "this evening": date = today; evening = true
            case "domani", "tomorrow": date = cal.date(byAdding: .day, value: 1, to: today)
            case "dopodomani": date = cal.date(byAdding: .day, value: 2, to: today)
            default:
                if let wd = weekdays[w] {
                    date = (1...7).compactMap { cal.date(byAdding: .day, value: $0, to: today) }
                        .first { cal.component(.weekday, from: $0) == wd }
                }
            }
            if let date {
                hits.append(DayHit(date: date, loc: m.range.location, prev: previousWord(before: m.range.location, in: s)))
                dayRanges.append(m.range)
            }
        }
        let monthPattern = #"\b(\d{1,2})\s+("# + (itMonths + enMonths).joined(separator: "|") + #")\b"#
        for m in matches(monthPattern, in: s) {
            let name = m.groups[2] ?? ""
            let idx = (itMonths.firstIndex(of: name) ?? enMonths.firstIndex(of: name) ?? -1) + 1
            if let d = Int(m.groups[1] ?? ""), idx > 0, let date = makeDate(day: d, month: idx, now: now, cal: cal) {
                hits.append(DayHit(date: date, loc: m.range.location, prev: previousWord(before: m.range.location, in: s)))
                dayRanges.append(m.range)
            }
        }
        for m in matches(#"\b(\d{1,2})/(\d{1,2})\b"#, in: s) {
            if let d = Int(m.groups[1] ?? ""), let mo = Int(m.groups[2] ?? ""), (1...12).contains(mo),
               let date = makeDate(day: d, month: mo, now: now, cal: cal) {
                hits.append(DayHit(date: date, loc: m.range.location, prev: previousWord(before: m.range.location, in: s)))
                dayRanges.append(m.range)
            }
        }
        hits.sort { $0.loc < $1.loc }
        blank(dayRanges, in: &s)

        // 5) Verbo (nelle prime parole)
        var words = s.split(separator: " ").map(String.init)
        var verb = Verb.none
        for (i, w) in words.prefix(4).enumerated() {
            if let found = verbPrefixes.first(where: { $0.1.contains { w.hasPrefix($0) } })?.0 {
                verb = found
                words.remove(at: i)
                break
            }
        }

        // 6) Rinomina: "… X in Y"
        var newTitle: String?
        let wantsRename = verb == .rename
            || (verb == .edit && words.contains { ["titolo", "nome", "title", "name"].contains($0) })
        if wantsRename,
           let idx = words.lastIndex(where: { ["in", "to", "come", "as"].contains($0) }),
           idx > 0, idx < words.count - 1 {
            newTitle = makeTitle(from: Array(words[(idx + 1)...]))
            words = Array(words[..<idx])
        }

        // 6b) Domande: "che impegni ho domani?", "quando sono libero?"
        var question: AssistantAction?
        if verb == .none {
            let n = normalize(text).replacingOccurrences(of: "’", with: "'")
            if freeCues.contains(where: { n.contains($0) }) {
                question = .free
            } else if listPhrases.contains(where: { n.contains($0) })
                        || (listNouns.contains(where: { n.contains($0) }) && !addVerbs.contains(words.first ?? "")) {
                question = .list
            }
        }

        // 7) Titolo o parole chiave
        let isAdd = verb == .none && question == nil
        let title: String
        if isAdd {
            title = makeTitle(from: words)
        } else {
            title = words.filter { !fillers.contains($0) }.joined(separator: " ")
        }

        // 8) Composizione in base al verbo
        var req = ParsedRequest(action: question ?? (isAdd ? .add : (verb == .delete ? .delete : .edit)), title: title)
        req.newTitle = newTitle
        if let t = time { req.time = t } else if isAdd && evening { req.time = (hour: 20, minute: 0) }

        switch req.action {
        case .add, .list, .free:
            req.day = hits.first?.date
        case .delete:
            req.targetDay = hits.first?.date
        case .edit:
            if hits.count >= 2 {
                req.targetDay = hits[0].date
                req.day = hits[1].date
            } else if let h = hits.first {
                if ["di", "del", "dello", "della", "dell'", "of"].contains(h.prev) { req.targetDay = h.date }
                else { req.day = h.date }
            }
        }

        if duration > 0 {
            switch verb {
            case .later:    req.shift = duration
            case .earlier:  req.shift = -duration
            case .lengthen: if deltaPrep { req.durationDelta = duration } else { req.duration = duration }
            case .shorten:  if deltaPrep { req.durationDelta = -duration } else { req.duration = duration }
            default:        req.duration = duration
            }
        }
        return req
    }

    // MARK: Utilità

    private static func makeDate(day: Int, month: Int, now: Date, cal: Calendar) -> Date? {
        let year = cal.component(.year, from: now)
        guard var d = cal.date(from: DateComponents(year: year, month: month, day: day)) else { return nil }
        if d < cal.startOfDay(for: now) {
            d = cal.date(from: DateComponents(year: year + 1, month: month, day: day)) ?? d
        }
        return d
    }

    /// Titolo leggibile: toglie verbi e preposizioni a inizio e fine, prima lettera maiuscola.
    private static func makeTitle(from words: [String]) -> String {
        var w = words
        func isNoise(_ x: String) -> Bool { fillers.contains(x) || addVerbs.contains(x) }
        while let f = w.first, isNoise(f) { w.removeFirst() }
        while let l = w.last, isNoise(l) { w.removeLast() }
        let t = w.joined(separator: " ").replacingOccurrences(of: "' ", with: "'")
        return t.prefix(1).uppercased() + t.dropFirst()
    }
}

#endif
