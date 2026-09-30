import SwiftUI

// MARK: - Premi

struct RewardsView: View {
    @Environment(EventStore.self) private var store

    var body: some View {
        let done = store.events.filter { $0.end < .now }.count
        let sport = store.events.filter { $0.category == .health }.count
        let focus = store.events.filter { $0.category == .focus }.count
        // Regole di esempio: sostituiscile con la tua logica
        let medals: [(String, String, Bool)] = [
            ("Studio", "Image", done >= 2),
            ("Sport", "dumbbell.fill", sport >= 1),
            ("Deep focus", "scope", focus >= 2)
        ]
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Il prossimo premio").font(.headline)
                        Text("Completa altri impegni Focus: il prossimo traguardo ti aspetta.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading).glass(26)

                    Text("I tuoi obiettivi").font(.headline).padding(.top, 8)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(medals, id: \.0) { m in
                            VStack(spacing: 10) {
                                Text(m.0.uppercased()).font(.subheadline.weight(.bold))
                                Image(m.1).font(.system(size: 30)).foregroundStyle(.white)
                                    .frame(width: 74, height: 74)
                                    .shadow(color: .black.opacity(0.25), radius: 8, y: 6)
                                    .saturation(m.2 ? 1 : 0).opacity(m.2 ? 1 : 0.6)
                                Text(m.2 ? "Obiettivo raggiunto" : "Da conquistare").font(.footnote)
                            }
                            .padding(16).frame(maxWidth: .infinity).glass(26)
                        }
                    }
                }
                .padding()
            }
            .background(AppBackground())
            .hideTopBarBand()
            .navigationTitle("Premi")
        }
    }
}
