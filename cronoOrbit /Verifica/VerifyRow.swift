import SwiftUI

#if os(iOS)

// MARK: - Opzioni di "In parte"
// In corso: conta il tempo trascorso fino a ora. Finito: scegli quanta parte hai svolto.

struct PartialOptions: View {
    @Environment(EventStore.self) private var store
    let event: Event

    var body: some View {
        let now = Date.now
        if event.start <= now && now < event.end {
            let from = event.trackingStart ?? event.start
            let elapsed = max(1, Int(now.timeIntervalSince(from) / 60))
            Button { store.setCompletion(event.id, status: .partial) } label: {
                Text("Fino a ora · \(elapsed) min")
            }
        } else {
            ForEach([25, 50, 75], id: \.self) { pct in
                let minutes = max(1, Int(event.duration / 60) * pct / 100)
                Button { store.setCompletion(event.id, status: .partial, minutes: minutes) } label: {
                    Text(verbatim: "\(pct)% · \(minutes) min")
                }
            }
        }
    }
}

// MARK: - Tre risposte rapide: Fatto / In parte / Non fatto

struct OutcomeButtons: View {
    @Environment(EventStore.self) private var store
    
    @EnvironmentObject var progress: ProgressManager
    
    let event: Event

    var body: some View {
        HStack(spacing: 8) {
            Button {
                           store.setCompletion(event.id, status: .done)
                          
                           progress.completeEvent(category: event.category.title) 
                       } label: {
                           chip("Fatto", "checkmark.circle.fill", .green)
                       }

            Menu {
                // quanta parte dell'impegno hai svolto
                PartialOptions(event: event)
            } label: {
                chip("In parte", "circle.lefthalf.filled", .orange)
            }

            Button { store.setCompletion(event.id, status: .skipped) } label: {
                chip("Non fatto", "xmark.circle.fill", .red)
            }
        }
        .buttonStyle(.plain)
    }

    private func chip(_ title: LocalizedStringKey, _ icon: String, _ color: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(color.opacity(0.15), in: Capsule())
    }
}

// MARK: - Conto alla rovescia dei 15 minuti

struct VerifyDeadlineLabel: View {
    let event: Event

    var body: some View {
        if event.completion == nil && event.trackingStart == nil && !event.isAllDay && event.end <= Date.now {
            TimelineView(.periodic(from: .now, by: 1)) { ctx in
                let left = event.verifyDeadline.timeIntervalSince(ctx.date)
                if left > 0 {
                    Label("Scade tra \(mmss(left))", systemImage: "hourglass")
                        .font(.caption.weight(.semibold)).foregroundStyle(.orange)
                } else {
                    Label("Scaduta: non conta per le medaglie", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.semibold)).foregroundStyle(.red)
                }
            }
        }
    }

    private func mmss(_ t: TimeInterval) -> String {
        let s = max(0, Int(t))
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

// MARK: - Menu rapido di verifica (icona nella riga dell'impegno)

struct VerifyMenu: View {
    @Environment(EventStore.self) private var store
    let event: Event

    var body: some View {
        Menu {
            if Date.now < event.end {
                Button { store.startTracking(event.id) } label: { Label("Avvia", systemImage: "play.fill") }
            }
            Button { store.setCompletion(event.id, status: .done) } label: {
                Label("Fatto", systemImage: "checkmark.circle")
            }
            Menu("In parte", systemImage: "circle.lefthalf.filled") {
                PartialOptions(event: event)
            }
            Button(role: .destructive) { store.setCompletion(event.id, status: .skipped) } label: {
                Label("Non fatto", systemImage: "xmark.circle")
            }
        } label: {
            let expired = event.isVerificationExpired()
            Image(systemName: expired ? "exclamationmark.triangle.fill" : "checkmark.seal")
                .font(.title3)
                .foregroundStyle(expired ? Color.red : (event.isAwaitingVerification() ? Color.orange : Color.accentColor))
                .frame(width: 32, height: 32)
        }
    }
}

// MARK: - Riga "Da verificare"

struct VerifyRow: View {
    let event: Event

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Circle().fill(event.category.color).frame(width: 10, height: 10)
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title).font(.subheadline.weight(.semibold))
                    Text(slotLabel(TimeSlot(start: event.start, end: event.end)))
                        .font(.footnote).foregroundStyle(.secondary)
                    VerifyDeadlineLabel(event: event)
                }
                Spacer()
            }
            OutcomeButtons(event: event)
        }
    }
}

#endif
