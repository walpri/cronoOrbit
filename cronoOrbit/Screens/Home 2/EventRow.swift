
import SwiftUI

#if os(iOS)

struct EventRow: View {
    
    @Environment(EventStore.self) private var store
    
    let event: Event
    
    @State private var showEdit = false

    /// Esito della verifica: spunta, mezzo cerchio, croce o punto rosso se è in corso
    @ViewBuilder
    private var statusIcon: some View {
        if event.trackingStart != nil {
            Image(systemName: "record.circle").foregroundStyle(.red)
        } else if let c = event.completion {
            switch c.status {
            case .done:    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            case .partial: Image(systemName: "circle.lefthalf.filled").foregroundStyle(.orange)
            case .skipped: Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
            }
        }
    }
    
    var body: some View {
        
        NavigationLink(value: event.id) {
            
            HStack(spacing: 14) {
                
                Circle()
                    .fill(event.category.color)
                    .frame(width: 10, height: 10)
                
                VStack(alignment: .leading, spacing: 2) {
                    
                    Text(event.title)
                        .font(.subheadline.weight(.semibold))
                    
                    Text(
                        "\(event.start.formatted(date: .omitted, time: .shortened)) – \(event.end.formatted(date: .omitted, time: .shortened)) · \(event.duration.hm)"
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                
                Spacer(minLength: 0)
                
                statusIcon
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .glass(22, interactive: true)
        }
        .buttonStyle(.plain)
        
        // MARK: Swipe verso sinistra
        
        .swipeActions(
            edge: .trailing,
            allowsFullSwipe: true
        ) {
            
            Button(role: .destructive) {
                store.delete(event.id)
            } label: {
                Label(
                    "Elimina",
                    systemImage: "trash"
                )
            }
        }
        
        // MARK: Swipe verso destra
        
        .swipeActions(
            edge: .leading,
            allowsFullSwipe: false
        ) {
            
            Button {
                showEdit = true
            } label: {
                Label(
                    "Modifica",
                    systemImage: "pencil"
                )
            }
            .tint(.blue)
        }
        
        .sheet(isPresented: $showEdit) {
            NewEventSheet(eventID: event.id)
        }
    }
}

#endif

