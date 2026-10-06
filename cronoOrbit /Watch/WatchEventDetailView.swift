import SwiftUI

#if os(watchOS)

struct WatchEventDetailView: View {
    let event: Event

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                
                HStack {
                    Circle()
                        .fill(event.category.color)
                        .frame(width: 8, height: 8)
                    Text(event.category.name)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(event.category.color)
                }

                Text(event.title)
                    .font(.title3.weight(.bold))

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Label("\(event.start.formatted(date: .omitted, time: .shortened)) - \(event.end.formatted(date: .omitted, time: .shortened))", systemImage: "clock")
                    
                    if !event.place.isEmpty {
                        Label(event.place, systemImage: "location")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if !event.notes.isEmpty {
                    Divider()
                    Text("Note")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(event.notes)
                        .font(.caption)
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("Dettaglio")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#endif
