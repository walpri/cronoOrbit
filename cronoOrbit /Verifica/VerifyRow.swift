import SwiftUI

#if os(iOS)

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
                ForEach([25, 50, 75], id: \.self) { pct in
                    let minutes = max(1, Int(event.duration / 60) * pct / 100)
                    Button { store.setCompletion(event.id, status: .partial, minutes: minutes) } label: {
                        Text(verbatim: "\(pct)% · \(minutes) min")
                    }
                }
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
                }
                Spacer()
            }
            OutcomeButtons(event: event)
        }
    }
}

#endif
