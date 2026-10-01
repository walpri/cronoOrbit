import SwiftUI

#if os(watchOS) // solo Apple Watch

// MARK: - Home Apple Watch (pensata per Series 11 da 46 mm, ma si adatta a tutti i formati)

struct WatchHomeView: View {
    @Environment(WatchStore.self) private var store

    var body: some View {
        let today = store.events(on: .now)
        NavigationStack {
            TabView {
                WatchRing(events: today)
                WatchEventList(events: today)
            }
            .tabViewStyle(.verticalPage)
            .containerBackground(Color(red: 0.09, green: 0.06, blue: 0.23).gradient, for: .tabView)
        }
    }
}

// MARK: Anello 24h

struct WatchRing: View {
    let events: [Event]

    var body: some View {
        TimelineView(.everyMinute) { ctx in
            let now = Event.minutes(ctx.date)
            ZStack {
                Circle().stroke(.primary.opacity(0.15), lineWidth: 14)
                ForEach(events) { e in
                    ArcShape(from: e.startMinutes, to: max(e.endMinutes, e.startMinutes + 30))
                        .stroke(LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round))
                }
                NowDot(minutes: now)
                center(now: now, date: ctx.date)
            }
            .padding(12)
            .aspectRatio(1, contentMode: .fit)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Impegni di oggi su un anello di 24 ore")
    }

    @ViewBuilder
    private func center(now: Double, date: Date) -> some View {
        let current = events.first { $0.startMinutes <= now && now < $0.endMinutes }
        let next = events.first { $0.startMinutes > now }
        VStack(spacing: 2) {
            if let e = current {
                text(e.title, e.end.timeIntervalSince(date).hm,
                     String(localized: "Fino alle \(e.end.formatted(date: .omitted, time: .shortened))"))
            } else if let e = next {
                text(e.title, e.start.timeIntervalSince(date).hm,
                     String(localized: "Oggi alle \(e.start.formatted(date: .omitted, time: .shortened))"))
            } else {
                text("", String(localized: "Libero"), String(localized: "Nessun altro impegno"))
            }
        }
        .padding(.horizontal, 28)
    }

    private func text(_ top: String, _ big: String, _ bottom: String) -> some View {
        VStack(spacing: 2) {
            Text(top).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            Text(big).font(.system(size: 26, weight: .bold, design: .rounded)).minimumScaleFactor(0.6).lineLimit(1)
            Text(bottom).font(.caption2.weight(.semibold)).foregroundStyle(.primary.opacity(0.85)).lineLimit(1).minimumScaleFactor(0.7)
        }
    }
}

// MARK: Elenco impegni

struct WatchEventList: View {
    let events: [Event]

    var body: some View {
        List {
            if events.isEmpty {
                Text("Giornata libera.").foregroundStyle(.secondary)
            }
            ForEach(events) { e in
                HStack(spacing: 8) {
                    Circle().fill(e.category.color).frame(width: 8, height: 8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(e.title).font(.headline).lineLimit(2)
                        Text("\(e.start.formatted(date: .omitted, time: .shortened)) – \(e.end.formatted(date: .omitted, time: .shortened))")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Impegni di oggi")
    }
}

#Preview {
    let s = WatchStore()
    s.events = EventStore.sample()
    return WatchHomeView().environment(s)
}
#endif
