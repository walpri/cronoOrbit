import SwiftUI

#if os(watchOS)

struct WatchHomeView: View {
    @Environment(WatchEventStore.self) private var store
    
    // Stati per popup e festeggiamenti su Watch
    @State private var eventToConfirm: Event?
    @State private var showCelebration = false
    @State private var currentQuote = ""
    /// Impegni di cui ho già chiesto l'esito: non richiedere se chiudi il popup senza rispondere
    @State private var askedIDs = Set<Event.ID>()

    var body: some View {
        NavigationStack {
            // Filtriamo per considerare solo gli eventi NON completati
            let today = store.todayEvents().filter { !$0.isCompleted }
            
            ScrollView {
                VStack(spacing: 12) {
                    WatchDayRing(events: today)
                        .frame(width: 150, height: 150)
                        .padding(.vertical, 4)

                    if today.isEmpty {
                        ContentUnavailableView(
                            "Tutto fatto!",
                            systemImage: "checkmark.circle.fill",
                            description: Text("Nessun altro impegno previsto")
                        )
                        .padding(.top, 8)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Oggi")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)

                            ForEach(today) { event in
                                NavigationLink(value: event.id) {
                                    WatchEventRow(event: event)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            .navigationTitle("CronoOrbit")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: UUID.self) { eventID in
                if let event = store.events.first(where: { $0.id == eventID }) {
                    WatchEventDetailView(event: event)
                }
            }
            // --- CHIUSURA POPUP SE RISPONDI DALL'IPHONE ---
            .onChange(of: store.events) { _, newEvents in
                if let current = eventToConfirm,
                   let updated = newEvents.first(where: { $0.id == current.id }),
                   updated.isCompleted {
                    eventToConfirm = nil
                }
            }
            // --- CONTROLLO EVENTI TERMINATI SU WATCH ---
            .task {
                while !Task.isCancelled {
                    checkCompletedEvents()
                    try? await Task.sleep(for: .seconds(10))
                }
            }
            // POPUP DI CONFERMA SULL'APPLE WATCH
            .sheet(item: $eventToConfirm) { event in
                VStack(spacing: 10) {
                    Text("Hai finito?")
                        .font(.headline)
                    Text(event.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    HStack {
                        Button("No") {
                            confirmCompletion(for: event, completed: false)
                        }
                        .buttonStyle(.bordered)

                        Button("Sì") {
                            confirmCompletion(for: event, completed: true)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
                .padding()
            }
            // SCHERMATA MOTIVAZIONALE APPLE WATCH
            .sheet(isPresented: $showCelebration) {
                VStack(spacing: 8) {
                    Text(verbatim: "🎉 🎉 🎉")
                        .font(.title)
                    Text(verbatim: currentQuote)
                        .font(.caption)
                        .multilineTextAlignment(.center)

                    Button("OK") {
                        showCelebration = false
                    }
                    .padding(.top, 4)
                }
                .padding()
            }
        }
    }

    private func checkCompletedEvents() {
        guard eventToConfirm == nil, !showCelebration else { return }
        let now = Date.now
        // Limita il controllo agli eventi terminati negli ultimi 15 minuti (900 secondi)
        let maxDelay: TimeInterval = 900

        if let ended = store.events.first(where: {
            $0.end <= now &&
            now.timeIntervalSince($0.end) <= maxDelay &&
            !$0.isCompleted &&
            !$0.isAllDay &&
            $0.trackingStart == nil &&
            !askedIDs.contains($0.id)
        }) {
            askedIDs.insert(ended.id)
            eventToConfirm = ended
        }
    }

    private func confirmCompletion(for event: Event, completed: Bool) {
        // "Sì" = svolto, "No" = non svolto. L'esito viaggia verso l'iPhone.
        if let update = store.complete(event.id, status: completed ? .done : .skipped) {
            WatchSessionManager.shared.send(update)
        }
        eventToConfirm = nil

        if completed {
            currentQuote = Event.motivationalQuotes.randomElement() ?? Event.motivationalQuotes[0]
            showCelebration = true
        }
    }
}

struct WatchEventRow: View {
    let event: Event

    var body: some View {
        HStack(spacing: 8) {
            Capsule()
                .fill(event.category.color)
                .frame(width: 4, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Text("\(event.start.formatted(date: .omitted, time: .shortened)) - \(event.end.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct WatchDayRing: View {
    let events: [Event]

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            let currentEvent = events.first {
                $0.trackingStart != nil && $0.completion == nil
            } ?? events.first {
                $0.start <= now && now < $0.end && $0.completion == nil
            }

            let nextEvent = events.first { $0.start > now }

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.25), lineWidth: 14)

                if let event = currentEvent {
                    let totalDuration = event.end.timeIntervalSince(event.start)
                    let elapsed = now.timeIntervalSince(event.start)
                    let progress = min(max(elapsed / totalDuration, 0), 1)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }

                VStack(spacing: 2) {
                    if let event = currentEvent {
                        let remaining = max(0, event.end.timeIntervalSince(now))
                        Text(event.title)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text(formatCountdown(remaining))
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .minimumScaleFactor(0.7)

                        Text("fino alle \(event.end.formatted(date: .omitted, time: .shortened))")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    } else if let event = nextEvent {
                        Text("Prossimo")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)

                        Text(event.title)
                            .font(.caption.weight(.semibold))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)

                        Text(event.start.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.cyan)
                    } else {
                        Text("Tempo libero")
                            .font(.caption.weight(.bold))
                        Text("Nessun impegno")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 12)
            }
        }
    }

    private func formatCountdown(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded(.down)))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0 ? "\(h)h \(m)m" : String(format: "%02d:%02d", m, s)
    }
}

#endif // os(watchOS)
