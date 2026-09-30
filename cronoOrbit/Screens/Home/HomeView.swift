import SwiftUI

// MARK: - Home

struct HomeView: View {
    @Environment(EventStore.self) private var store
    @State private var showNew = false
    @State private var showImport = false

    var body: some View {
        let today = store.events(on: .now)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    VStack {
                        Text("Il tuo tempo").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                        DayRing(events: today)
                    }
                    .padding(16).frame(maxWidth: .infinity).glass(36)

                    Text("Impegni di oggi").font(.headline).padding(.top, 8)
                    ForEach(today) { EventRow(event: $0) }
                    if today.isEmpty {
                        Text("Nessun impegno. Tocca + per aggiungerne uno.").foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .background(AppBackground())
            .navigationTitle(Date.now.formatted(.dateTime.weekday(.wide).day()))
            .navigationDestination(for: Event.ID.self) { EventDetailView(id: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Importa calendari", systemImage: "square.and.arrow.down") { showImport = true }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Aggiungi impegno", systemImage: "plus") { showNew = true }
                }
            }
            .sheet(isPresented: $showNew) { NewEventSheet() }
            .sheet(isPresented: $showImport) { ImportCalendarsView() }
        }
    }
}
