import SwiftUI
import Charts

#if os(iOS)

// MARK: - Resoconto settimanale

struct ReportView: View {
    @Environment(EventStore.self) private var store
    @State private var weekOffset = 0                 // 0 = questa settimana, -1 = la scorsa…
    @State private var metric = ReportMetric.done

    private var cal: Calendar { .current }

    private func weekStart(offset: Int) -> Date {
        let current = cal.dateInterval(of: .weekOfYear, for: .now)?.start ?? cal.startOfDay(for: .now)
        return cal.date(byAdding: .weekOfYear, value: offset, to: current) ?? current
    }

    var body: some View {
        let start = weekStart(offset: weekOffset)
        let report = ReportCalculator.report(weekStart: start, events: store.events, metric: metric)
        let previous = ReportCalculator.report(weekStart: weekStart(offset: weekOffset - 1), events: store.events, metric: metric)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header(start)

                    Picker("Vista", selection: $metric) {
                        Text("Svolte").tag(ReportMetric.done)
                        Text("Pianificate").tag(ReportMetric.planned)
                    }
                    .pickerStyle(.segmented)

                    totalCard(report, previous)

                    if report.total == 0 {
                        Text("Nessun impegno in questa settimana.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                    } else {
                        chartCard(report)
                        categoryCard(report, previous)
                    }
                }
                .padding()
            }
            .background(AppBackground())
            .hideTopBarBand()
            .navigationTitle("Resoconto")
        }
    }

    // MARK: Navigazione tra le settimane

    private func header(_ start: Date) -> some View {
        let end = cal.date(byAdding: .day, value: 6, to: start) ?? start
        let range = "\(start.formatted(.dateTime.day().month(.abbreviated))) – \(end.formatted(.dateTime.day().month(.abbreviated)))"
        return HStack {
            Button("Settimana precedente", systemImage: "chevron.left") { weekOffset -= 1 }
            Spacer()
            VStack(spacing: 2) {
                Text(range).font(.headline)
                Text("Settimana \(cal.component(.weekOfYear, from: start))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if weekOffset != 0 {
                Button("Oggi") { weekOffset = 0 }.font(.footnote.weight(.semibold))
            }
            Button("Settimana successiva", systemImage: "chevron.right") { weekOffset += 1 }
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.plain)
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 16).padding(.vertical, 12)
        .glass(22)
    }

    // MARK: Totale

    private func totalCard(_ report: WeekReport, _ previous: WeekReport) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(metric == .done ? LocalizedStringKey("Totale svolto") : LocalizedStringKey("Totale pianificato"))
                .font(.footnote).foregroundStyle(.secondary)
            Text(report.total.hm)
                .font(.system(size: 44, weight: .bold, design: .rounded))
            if let d = delta(report.total, previous.total) {
                HStack(spacing: 6) {
                    Text(d.text).foregroundStyle(d.color).font(.footnote.weight(.semibold))
                    Text("rispetto alla settimana scorsa").font(.footnote).foregroundStyle(.secondary)
                }
            }
            if let rate = report.completionRate {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Completamento").font(.footnote).foregroundStyle(.secondary)
                        Spacer()
                        Text(verbatim: "\(Int(rate * 100))%").font(.footnote.weight(.bold))
                    }
                    ProgressView(value: rate)
                        .tint(rate >= 0.8 ? Color.green : (rate >= 0.5 ? Color.orange : Color.red))
                }
                .padding(.top, 8)
            }
            if report.unverified > 0 {
                Label("\(report.unverified) da verificare", systemImage: "questionmark.circle")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.orange)
                    .padding(.top, 4)
            }
            if metric == .done {
                Text("Conta solo ciò che hai verificato.")
                    .font(.caption).foregroundStyle(.secondary).padding(.top, 2)
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).glass(26)
    }

    // MARK: Grafico: ore per giorno, impilate per categoria

    private struct DayPoint: Identifiable {
        let id = UUID()
        let day: Date
        let category: String
        let hours: Double
    }

    private func chartCard(_ report: WeekReport) -> some View {
        let points: [DayPoint] = (0..<7).flatMap { d -> [DayPoint] in
            let day = cal.date(byAdding: .day, value: d, to: report.weekStart) ?? report.weekStart
            return EventCategory.allCases.compactMap { c -> DayPoint? in
                let h = (report.daily[d][c] ?? 0) / 3600
                return h > 0 ? DayPoint(day: day, category: c.title, hours: h) : nil
            }
        }
        let end = cal.date(byAdding: .day, value: 7, to: report.weekStart) ?? report.weekStart

        return VStack(alignment: .leading, spacing: 10) {
            Text("Ore per giorno").font(.headline)
            Chart(points) { p in
                BarMark(x: .value("Giorno", p.day, unit: .day), y: .value("Ore", p.hours))
                    .foregroundStyle(by: .value("Categoria", p.category))
            }
            .chartForegroundStyleScale(domain: EventCategory.allCases.map { $0.title },
                                       range: EventCategory.allCases.map { $0.color })
            .chartXScale(domain: report.weekStart...end)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let h = value.as(Double.self) { Text(verbatim: "\(Int(h))h") }
                    }
                }
            }
            .chartLegend(position: .bottom, alignment: .leading)
            .frame(height: 200)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).glass(26)
    }

    // MARK: Elenco per categoria

    private func categoryCard(_ report: WeekReport, _ previous: WeekReport) -> some View {
        let rows = EventCategory.allCases
            .filter { (report.totals[$0] ?? 0) > 0 }
            .sorted { (report.totals[$0] ?? 0) > (report.totals[$1] ?? 0) }

        return VStack(alignment: .leading, spacing: 14) {
            Text("Per categoria").font(.headline)
            ForEach(rows) { c in
                let value = report.totals[c] ?? 0
                VStack(spacing: 6) {
                    HStack {
                        Circle().fill(c.color).frame(width: 10, height: 10)
                        Text(c.name).font(.subheadline.weight(.semibold))
                        Spacer()
                        if let d = delta(value, previous.totals[c] ?? 0) {
                            Text(d.text).font(.caption).foregroundStyle(d.color)
                        }
                        Text(value.hm).font(.subheadline.weight(.bold))
                    }
                    ProgressView(value: value, total: max(report.total, 1))
                        .tint(c.color)
                }
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).glass(26)
    }

    // MARK: Differenza con la settimana precedente

    private func delta(_ now: TimeInterval, _ before: TimeInterval) -> (text: String, color: Color)? {
        let d = now - before
        guard abs(d) >= 60 else { return nil }
        return ((d > 0 ? "▲ " : "▼ ") + abs(d).hm, d > 0 ? .green : .orange)
    }
}

#endif
