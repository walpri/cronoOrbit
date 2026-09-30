import SwiftUI

// MARK: - Arco dell'evento

struct ArcShape: Shape {
    var from: Double
    var to: Double

    func path(in rect: CGRect) -> Path {
        var p = Path()

        p.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: min(rect.width, rect.height) / 2,
            startAngle: .degrees(from / 1440 * 360 - 90),
            endAngle: .degrees(to / 1440 * 360 - 90),
            clockwise: false
        )

        return p
    }
}

// MARK: - DayRing

struct DayRing: View {

    /// Impegni del giorno, già ordinati per orario.
    let events: [Event]

    var body: some View {

        // Aggiorniamo ogni secondo per avere un countdown realmente in tempo reale.
        TimelineView(.periodic(from: .now, by: 1)) { context in

            let now = context.date

            // Evento attualmente in corso
            let currentEvent = events.first {
                $0.start <= now && now < $0.end
            }

            // Prossimo evento non ancora iniziato
            let nextEvent = events.first {
                $0.start > now
            }

            ZStack {

                // =====================================================
                // ANELLO SEMI-TRASPARENTE DI SFONDO
                // =====================================================

                Circle()
                    .stroke(
                        .white.opacity(0.16),
                        lineWidth: 34
                    )

                // =====================================================
                // ANELLO BLU DELL'EVENTO
                // =====================================================

                if let event = currentEvent {

                    // Durata totale dell'evento
                    let totalDuration =
                        event.end.timeIntervalSince(event.start)

                    // Tempo trascorso dall'inizio
                    let elapsed =
                        now.timeIntervalSince(event.start)

                    // Percentuale completata.
                    // Viene bloccata tra 0% e 100%.
                    let progress = min(
                        max(elapsed / totalDuration, 0),
                        1
                    )

                    // Arco totale dell'evento
                    let totalArc = event.endMinutes - event.startMinutes

                    // Punto fino al quale deve arrivare il blu
                    let currentEnd =
                        event.startMinutes + totalArc * progress

                    ArcShape(
                        from: event.startMinutes,
                        to: currentEnd
                    )
                    .stroke(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(
                            lineWidth: 30,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
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
        .accessibilityLabel("Impegni di oggi su un anello di 24 ore")
    }

    // MARK: - Contenuto centrale

    @ViewBuilder
    private func centerContent(
        now: Date,
        currentEvent: Event?,
        nextEvent: Event?
    ) -> some View {

        if let event = currentEvent {

            // =====================================================
            // EVENTO IN CORSO
            // =====================================================

            let remaining =
                max(0, event.end.timeIntervalSince(now))

            VStack(spacing: 4) {

                Text(event.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text(
                    "Fino alle " +
                    event.end.formatted(
                        date: .omitted,
                        time: .shortened
                    )
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, 40)

        } else if let event = nextEvent {

            // =====================================================
            // PROSSIMO EVENTO
            // =====================================================

            VStack(spacing: 4) {

                Text("Prossimo evento")
                    .font(.caption)
                    .foregroundStyle(.black)

                Text(event.title)
                    .font(
                        .system(
                            size: 26,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Text(nextEventDateText(event, now: now))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
            }
            .padding(.horizontal, 40)

        } else {

            // =====================================================
            // NESSUN ALTRO EVENTO
            // =====================================================

            VStack(spacing: 4) {

                Text("Tempo libero")
                    .font(
                        .system(
                            size: 26,
                            weight: .bold,
                            design: .rounded
                        )
                    )

                Text("Nessun altro impegno")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Countdown

    private func formatCountdown(_ seconds: TimeInterval) -> String {

        let totalSeconds = max(0, Int(seconds.rounded(.down)))

        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            return "\(hours)h \(String(format: "%02d", minutes))m"
        } else {
            return "\(minutes)m \(String(format: "%02d", secs))s"
        }
    }

    // MARK: - Prossimo evento

    private func nextEventDateText(
        _ event: Event,
        now: Date
    ) -> String {

        let calendar = Calendar.current

        if calendar.isDate(event.start, inSameDayAs: now) {

            return "Oggi alle " +
                event.start.formatted(
                    date: .omitted,
                    time: .shortened
                )

        } else {

            return event.start.formatted(
                .dateTime
                    .weekday(.wide)
                    .day()
                    .month(.wide)
            ) +
            " alle " +
            event.start.formatted(
                date: .omitted,
                time: .shortened
            )
        }
    }
}
