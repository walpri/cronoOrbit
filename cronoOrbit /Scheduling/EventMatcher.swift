import Foundation

/// Trova nell'agenda l'impegno a cui si riferisce l'utente ("la palestra", "lo studio di domani"…).
enum EventMatcher {
    private static let stopwords: Set<String> = [
        "con", "per", "del", "della", "dello", "dei", "degli", "delle", "gli", "una", "uno",
        "alle", "alla", "allo", "nel", "nella", "sul", "sulla", "che", "mio", "mia", "miei",
        "the", "and", "for", "my"
    ]

    static func normalize(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }

    static func tokens(_ s: String) -> [String] {
        normalize(s)
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
            .filter { $0.count >= 3 && !stopwords.contains($0) }
    }

    /// Distanza di Levenshtein (per tollerare piccoli refusi: "palstra" ~ "palestra")
    static func distance(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var prev = Array(0...b.count)
        for i in 1...a.count {
            var cur = [i] + Array(repeating: 0, count: b.count)
            for j in 1...b.count {
                cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1))
            }
            prev = cur
        }
        return prev[b.count]
    }

    /// Gli impegni che corrispondono meglio alle parole chiave (max `limit`), i più vicini nel tempo per primi.
    static func find(_ query: String, day: Date?, in events: [Event],
                     now: Date = .now, limit: Int = 5) -> [Event] {
        let cal = Calendar.current
        var pool = events
        if let day { pool = pool.filter { cal.isDate($0.start, inSameDayAs: day) } }

        let words = tokens(query)
        if words.isEmpty {
            return day == nil ? [] : Array(pool.sorted { $0.start < $1.start }.prefix(limit))
        }

        let scored: [(event: Event, score: Int)] = pool.map { e in
            let title = normalize(e.title)
            let titleWords = tokens(e.title)
            var score = 0
            for w in words {
                let stem = w.count >= 5 ? String(w.dropLast()) : w      // "palestre" ~ "palestra"
                if title.contains(stem) {
                    score += 2
                } else if w.count >= 4,
                          titleWords.contains(where: { $0.count >= 4 && distance(w, $0) <= (w.count >= 7 ? 2 : 1) }) {
                    score += 1                                          // refuso
                }
            }
            return (e, score)
        }.filter { $0.score > 0 }

        guard let best = scored.map({ $0.score }).max() else { return [] }
        let top = scored.filter { $0.score == best }.map { $0.event }
        let startOfToday = cal.startOfDay(for: now)
        let upcoming = top.filter { $0.end >= startOfToday }
        let chosen = upcoming.isEmpty ? top : upcoming
        return Array(chosen.sorted { $0.start < $1.start }.prefix(limit))
    }

    /// I prossimi impegni non ancora finiti (per far scegliere all'utente quando non si trova nulla).
    static func upcoming(in events: [Event], now: Date = .now, limit: Int = 8) -> [Event] {
        Array(events.filter { $0.end >= now }.sorted { $0.start < $1.start }.prefix(limit))
    }
}
