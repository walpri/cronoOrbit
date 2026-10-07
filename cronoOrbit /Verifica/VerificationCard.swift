import SwiftUI

#if os(iOS)

// MARK: - Scheda "Verifica" nel dettaglio di un impegno: Avvia/Termina oppure esito manuale

struct VerificationCard: View {
    @Environment(EventStore.self) private var store
    let event: Event

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Verifica").font(.footnote).foregroundStyle(.secondary)

            if let started = event.trackingStart {
                tracking(since: started)
            } else if let c = event.completion {
                result(c)
            } else {
                actions
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).glass(26)
    }

    // In corso: cronometro e "Termina"
    private func tracking(since started: Date) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Tempo trascorso").font(.footnote).foregroundStyle(.secondary)
                TimelineView(.periodic(from: .now, by: 1)) { ctx in
                    Text(clock(ctx.date.timeIntervalSince(started)))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
            }
            Spacer()
            Button { store.stopTracking(event.id) } label: {
                Label("Termina", systemImage: "stop.fill")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14).padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .glass(18, interactive: true)
        }
    }

    // Esito già registrato
    private func result(_ c: EventCompletion) -> some View {
        let planned = Int(event.duration / 60)
        let (icon, color, title): (String, Color, LocalizedStringKey) = {
            switch c.status {
            case .done:    return ("checkmark.circle.fill", .green, "Svolto")
            case .partial: return ("circle.lefthalf.filled", .orange, "Svolto in parte")
            case .skipped: return ("xmark.circle.fill", .red, "Non svolto")
            }
        }()
        return HStack(spacing: 12) {
            Image(systemName: icon).font(.title2).foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text("\(c.actualMinutes) min su \(planned) min").font(.footnote).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Ripristina") { store.clearCompletion(event.id) }
                .font(.footnote.weight(.semibold))
        }
    }

    // Ancora senza esito
    @ViewBuilder
    private var actions: some View {
        let now = Date.now
        if now >= event.start.addingTimeInterval(-30 * 60) && now < event.end && !event.isAllDay {
            Button { store.startTracking(event.id) } label: {
                Label("Avvia", systemImage: "play.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .glass(18, interactive: true)
        }
        if now >= event.start {
            OutcomeButtons(event: event)
        } else {
            Text("Potrai verificarlo quando inizia.").font(.footnote).foregroundStyle(.secondary)
        }
    }

    private func clock(_ t: TimeInterval) -> String {
        let s = max(0, Int(t))
        return String(format: "%d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
    }
}

#endif
