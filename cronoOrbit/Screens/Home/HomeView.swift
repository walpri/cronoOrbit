import SwiftUI
import WatchConnectivity

#if os(iOS) // solo iPhone

// MARK: - Home

struct HomeView: View {
    @Environment(EventStore.self) private var store
    @State private var showNew = false
    @State private var showImport = false
    
    // Stati per la conferma e i festeggiamenti
    @State private var eventToConfirm: Event?
    @State private var showCelebration = false
    @State private var currentQuote = ""

    var body: some View {
        // Mostra solo gli eventi di oggi NON ancora completati
        let today = store.events(on: .now).filter { !$0.isCompleted }
        
        NavigationStack {
            ZStack {
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
                            Text("Nessun impegno rimasto. Tocca + per aggiungerne uno.").foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                }
                
                // Effetto coriandoli a schermo intero
                if showCelebration {
                    ConfettiView()
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
            }
            .background(AppBackground())
            .hideTopBarBand()
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
            
            // --- CHIUSURA POPUP SE RISPONDI DALL'APPLE WATCH ---
            .onChange(of: store.events) { _, newEvents in
                if let current = eventToConfirm,
                   let updated = newEvents.first(where: { $0.id == current.id }),
                   updated.isCompleted {
                    eventToConfirm = nil
                }
            }
            // --- CONTROLLO EVENTI TERMINATI ---
            .task {
                while !Task.isCancelled {
                    checkCompletedEvents()
                    try? await Task.sleep(nanoseconds: 5_000_000_000) // Controlla ogni 5 secondi
                }
            }
            // POPUP DI CONFERMA PER IPHONE
            .alert("Attività completata?", isPresented: Binding(
                get: { eventToConfirm != nil },
                set: { if !$0 { eventToConfirm = nil } }
            ), presenting: eventToConfirm) { event in
                Button("Sì, completata! 🎉") {
                    confirmCompletion(for: event, completed: true)
                }
                Button("No / Salta", role: .cancel) {
                    confirmCompletion(for: event, completed: false)
                }
            } message: { event in
                Text("Hai terminato l'attività \"\(event.title)\"?")
            }
            // SHEET MOTIVAZIONALE
            .sheet(isPresented: $showCelebration) {
                VStack(spacing: 20) {
                    Text("🎉")
                        .font(.system(size: 80))
                    Text("Grande Traguardo!")
                        .font(.largeTitle.bold())
                    Text(currentQuote)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    Button("Continua") {
                        showCelebration = false
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
                }
                .presentationDetents([.medium])
            }
        }
    }

    private func checkCompletedEvents() {
        let now = Date.now
        // Considera solo eventi terminati negli ultimi 15 minuti (900 secondi)
        let maxDelay: TimeInterval = 900
        
        if let ended = store.events.first(where: {
            $0.end <= now &&
            now.timeIntervalSince($0.end) <= maxDelay &&
            !$0.isCompleted
        }) {
            if eventToConfirm == nil && !showCelebration {
                eventToConfirm = ended
            }
        }
    }

    private func confirmCompletion(for event: Event, completed: Bool) {
        if let index = store.events.firstIndex(where: { $0.id == event.id }) {
            store.events[index].isCompleted = true
            PhoneConnectivity.shared.send(store.events) // Invia lo stato aggiornato all'Apple Watch
        }
        
        if completed {
            currentQuote = Event.motivationalQuotes.randomElement() ?? "Ottimo lavoro!"
            withAnimation {
                showCelebration = true
            }
        }
        eventToConfirm = nil
    }
}

// MARK: - Vista Coriandoli (Confetti)
struct ConfettiView: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<40, id: \.self) { _ in
                    Circle()
                        .fill([Color.red, Color.blue, Color.green, Color.yellow, Color.pink, Color.purple].randomElement()!)
                        .frame(width: CGFloat.random(in: 6...12))
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: animate ? geo.size.height + 20 : -20
                        )
                        .animation(
                            Animation.linear(duration: Double.random(in: 2...4))
                                .repeatCount(1, autoreverses: false)
                                .delay(Double.random(in: 0...1)),
                            value: animate
                        )
                }
            }
        }
        .onAppear { animate = true }
    }
}

#endif // os(iOS)
