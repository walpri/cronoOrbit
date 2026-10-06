import SwiftUI

// MARK: - DayRing

struct DayRing: View {
    
    /// Eventi del giorno
    let events: [Event]
    
    var body: some View {
        
        // Aggiornamento molto frequente per rendere
        // il movimento del ring fluido.
        TimelineView(
            .animation(minimumInterval: 1.0 / 30.0)
        ) { context in
            
            let now = context.date
            
            // Evento attualmente in corso
            let currentEvent = events.first {
                $0.start <= now && now < $0.end
            }
            
            // Primo evento che deve ancora iniziare
            let nextEvent = events.first {
                $0.start > now
            }
            
            ZStack {
                
                // =====================================================
                // ANELLO SEMI-TRASPARENTE FISSO
                // =====================================================
                
                Circle()
                    .stroke(
                        Color.gray.opacity(0.20),
                        lineWidth: 34
                    )
                
                
                // =====================================================
                // ANELLO BLU PROGRESSIVO
                // =====================================================
                
                if let event = currentEvent {
                    
                    // Durata totale dell'evento
                    let totalDuration =
                        event.end.timeIntervalSince(event.start)
                    
                    // Tempo trascorso dall'inizio
                    let elapsed =
                        now.timeIntervalSince(event.start)
                    
                    // Percentuale completata
                    let progress = min(
                        max(elapsed / totalDuration, 0),
                        1
                    )
                    
                    // =================================================
                    // IL BLU PARTE DALL'INIZIO DELL'EVENTO
                    // E PERCORRE PROGRESSIVAMENTE TUTTO IL RING
                    // =================================================
                    
                    Circle()
                        .trim(
                            from: 0,
                            to: progress
                        )
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .cyan,
                                    .blue
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(
                                lineWidth: 30,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .rotationEffect(.degrees(-90))
                        .shadow(
                            color: .blue.opacity(0.45),
                            radius: 8
                        )
                }
                
                
                // =====================================================
                // TESTO CENTRALE
                // =====================================================
                
                centerContent(
                    now: now,
                    currentEvent: currentEvent,
                    nextEvent: nextEvent
                )
            }
            .padding(24)
            .aspectRatio(1, contentMode: .fit)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Impegni di oggi su un anello di 24 ore"
        )
    }
    
    
    // MARK: - Contenuto centrale
    
    @ViewBuilder
    private func centerContent(
        now: Date,
        currentEvent: Event?,
        nextEvent: Event?
    ) -> some View {
        
        // =========================================================
        // EVENTO IN CORSO
        // =========================================================
        
        if let event = currentEvent {
            
            let remaining =
                max(
                    0,
                    event.end.timeIntervalSince(now)
                )
            
            VStack(spacing: 5) {
                
                Text(event.title)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Text(formatCountdown(remaining))
                    .font(
                        .system(
                            size: 38,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                
                Text(
                    "Fino alle \(event.end.formatted(date: .omitted, time: .shortened))"
                )
                .font(
                    .subheadline.weight(.semibold)
                )
                .foregroundStyle(.primary)
            }
            .padding(.horizontal, 40)
            
            
        // =========================================================
        // NESSUN EVENTO IN CORSO → PROSSIMO EVENTO
        // =========================================================
        
        } else if let event = nextEvent {
            
            VStack(spacing: 5) {
                
                Text("Prossimo evento")
                    .font(.caption)
                    .foregroundStyle(.primary)
                
                Text(event.title)
                    .font(
                        .system(
                            size: 26,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                
                Text(
                    nextEventDateText(
                        event,
                        now: now
                    )
                )
                .font(
                    .subheadline.weight(.semibold)
                )
                .foregroundStyle(.primary)
            }
            .padding(.horizontal, 40)
            
            
        // =========================================================
        // NESSUN ALTRO EVENTO
        // =========================================================
        
        } else {
            
            VStack(spacing: 5) {
                
                Text("Tempo libero")
                    .font(
                        .system(
                            size: 26,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.primary)
                
                Text("Nessun altro impegno")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    
    // MARK: - Countdown
    
    private func formatCountdown(
        _ seconds: TimeInterval
    ) -> String {
        
        let totalSeconds =
            max(
                0,
                Int(seconds.rounded(.down))
            )
        
        let hours =
            totalSeconds / 3600
        
        let minutes =
            (totalSeconds % 3600) / 60
        
        let secs =
            totalSeconds % 60
        
        if hours > 0 {
            
            return "\(hours)h " +
            String(
                format: "%02d",
                minutes
            ) +
            "m"
            
        } else {
            
            return "\(minutes)m " +
            String(
                format: "%02d",
                secs
            ) +
            "s"
        }
    }
    
    
    // MARK: - Prossimo evento
    
    private func nextEventDateText(
        _ event: Event,
        now: Date
    ) -> String {
        
        let calendar =
            Calendar.current
        
        // Se è oggi → solo orario
        if calendar.isDate(
            event.start,
            inSameDayAs: now
        ) {
            
            return event.start.formatted(
                date: .omitted,
                time: .shortened
            )
            
        } else {
            
            // Se è un altro giorno →
            // data + orario
            
            return event.start.formatted(
                .dateTime
                    .weekday(.wide)
                    .day()
                    .month(.wide)
            )
            +
            " · "
            +
            event.start.formatted(
                date: .omitted,
                time: .shortened
            )
        }
    }
}
