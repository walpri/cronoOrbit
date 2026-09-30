import SwiftUI

// MARK: - Anello 24h

/// Arco tra due orari espressi in minuti dalla mezzanotte (00:00 in alto, senso orario).
struct ArcShape: Shape {
    var from: Double
    var to: Double
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                 radius: min(rect.width, rect.height) / 2,
                 startAngle: .degrees(from / 1440 * 360 - 90),
                 endAngle: .degrees(to / 1440 * 360 - 90),
                 clockwise: false) // in SwiftUI "false" = senso orario visivo
        return p
    }
}

struct NowDot: View {
    let minutes: Double
    var body: some View {
        GeometryReader { g in
            let r = min(g.size.width, g.size.height) / 2
            let a = Angle.degrees(minutes / 1440 * 360 - 90).radians
            Circle().fill(.white)
                .overlay(Circle().stroke(.pink, lineWidth: 3))
                .frame(width: 14, height: 14)
                .position(x: g.size.width / 2 + r * cos(a), y: g.size.height / 2 + r * sin(a))
        }
    }
}

struct DayRing: View {
    /// Impegni del giorno, già ordinati per orario.
    let events: [Event]

    var body: some View {
        TimelineView(.everyMinute) { ctx in
            let now = Event.minutes(ctx.date)
            ZStack {
                Circle().stroke(.white.opacity(0.16), lineWidth: 34)
                ForEach(events) { e in
                    ArcShape(from: e.startMinutes, to: max(e.endMinutes, e.startMinutes + 30))
                        .stroke(LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                                style: StrokeStyle(lineWidth: 30, lineCap: .round))
                        .shadow(color: .blue.opacity(0.45), radius: 8)
                }
                NowDot(minutes: now)
                summary(now: now, date: ctx.date)
            }
            .padding(24)
            .aspectRatio(1, contentMode: .fit)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Impegni di oggi su un anello di 24 ore")
    }

    @ViewBuilder
    private func summary(now: Double, date: Date) -> some View {
        let current = events.first { $0.startMinutes <= now && now < $0.endMinutes }
        let next = events.first { $0.startMinutes > now }
        VStack(spacing: 4) {
            if let e = current {
                line(e.title, e.end.timeIntervalSince(date).hm, "Fino alle " + e.end.formatted(date: .omitted, time: .shortened))
            } else if let e = next {
                line(e.title, e.start.timeIntervalSince(date).hm, "Oggi alle " + e.start.formatted(date: .omitted, time: .shortened))
            } else {
                line("", "Libero", "Nessun altro impegno")
            }
        }
        .padding(.horizontal, 40)
    }

    private func line(_ top: String, _ big: String, _ bottom: String) -> some View {
        VStack(spacing: 4) {
            Text(top).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            Text(big).font(.system(size: 38, weight: .bold, design: .rounded)).minimumScaleFactor(0.6).lineLimit(1)
            Text(bottom).font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.85))
        }
    }
}
