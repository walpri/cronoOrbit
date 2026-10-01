import SwiftUI

// MARK: - Dettaglio evento

struct EventDetailView: View {
    let id: Event.ID
    @Environment(EventStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if let e = store.events.first(where: { $0.id == id }) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 10) {
                        Label(e.category.name, systemImage: "circle.fill")
                            .font(.caption.weight(.semibold)).foregroundStyle(e.category.color)
                        Text(e.title).font(.title.bold())
                        if !e.notes.isEmpty { Text(e.notes).font(.subheadline).foregroundStyle(.secondary) }
                    }
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading).glass(26)

                    VStack(alignment: .leading, spacing: 14) {
                        info("calendar", "Data e ora", "\(e.start.formatted(.dateTime.weekday(.wide).day().month(.wide))) · \(e.start.formatted(date: .omitted, time: .shortened))–\(e.end.formatted(date: .omitted, time: .shortened))")
                        info("mappin.and.ellipse", "Luogo", e.place.isEmpty ? String(localized: "Nessun luogo") : e.place)
                        info("bell", "Promemoria", String(localized: "\(e.reminderMinutes) minuti prima"))
                    }
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading).glass(26)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Invitati").font(.footnote).foregroundStyle(.secondary)
                        HStack {
                            ForEach(e.invited, id: \.self) { n in
                                Text(String(n.prefix(1))).font(.caption.bold())
                                    .frame(width: 30, height: 30).background(.primary.opacity(0.15), in: Circle())
                                    .accessibilityLabel(n)
                            }
                        }
                    }
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading).glass(26)

                    Button(role: .destructive) { store.delete(id); dismiss() } label: {
                        Label("Elimina evento", systemImage: "trash")
                            .frame(maxWidth: .infinity, alignment: .leading).padding(16)
                    }
                    .glass(22, interactive: true)
                }
                .padding()
            }
            .background(AppBackground())
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func info(_ icon: String, _ title: LocalizedStringKey, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon).frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.footnote).foregroundStyle(.secondary)
                Text(value).font(.subheadline.weight(.semibold))
            }
        }
    }
}
