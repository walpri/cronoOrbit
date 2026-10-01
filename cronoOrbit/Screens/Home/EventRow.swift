/*
import SwiftUI

struct EventRow: View {

    let event: Event

    @State private var showEdit = false

    @Environment(EventStore.self) private var store

    var body: some View {

        NavigationLink(value: event.id) {

            HStack(spacing: 14) {

                Circle()
                    .fill(event.category.color)
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {

                    Text(event.title)
                        .font(.subheadline.weight(.semibold))

                    Text("\(event.start.formatted(date: .omitted, time: .shortened)) – \(event.end.formatted(date: .omitted, time: .shortened)) · \(event.duration.hm)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .glass(22, interactive: true)
        }
        .buttonStyle(.plain)

        // 👈 STRISCIANDO DA SINISTRA VERSO DESTRA
        // compare MODIFICA
        .swipeActions(edge: .leading, allowsFullSwipe: false) {

            Button {
                showEdit = true
            } label: {
                Label("Modifica", systemImage: "pencil")
            }
            .tint(.blue)
        }

        // 👉 STRISCIANDO DA DESTRA VERSO SINISTRA
        // compare ELIMINA
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {

            Button(role: .destructive) {
                store.delete(event.id)
            } label: {
                Label("Elimina", systemImage: "trash")
            }
        }

        // Schermata di modifica
        .sheet(isPresented: $showEdit) {
            EditEventSheet(event: event)
        }
    }
}
 */
