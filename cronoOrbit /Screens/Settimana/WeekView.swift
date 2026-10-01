import SwiftUI

// MARK: - Settimana / Mese

struct WeekView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case week = "Settimana", month = "Mese"
        var id: String { rawValue }
        var name: LocalizedStringKey { self == .week ? "Settimana" : "Mese" }
    }

    @Environment(EventStore.self) private var store
    @State private var selected = Date.now
    @State private var mode = Mode.week

    private var days: [Date] {
        let cal = Calendar.current
        let start = cal.dateInterval(of: .weekOfYear, for: .now)!.start
        return (0..<7).map { cal.date(byAdding: .day, value: $0, to: start)! }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Picker("Vista", selection: $mode) {
                        ForEach(Mode.allCases) { Text($0.name).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    if mode == .week {
                        weekHeader
                        dayStrip
                    } else {
                        MonthGridView(selected: $selected)
                        Text(selected.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                            .font(.headline).padding(.top, 6)
                    }

                    eventsCard

                    if mode == .week { overview }
                }
                .padding()
            }
            .background(AppBackground())
            .hideTopBarBand()
            .navigationTitle(mode == .week ? LocalizedStringKey("La tua settimana") : LocalizedStringKey("Il tuo mese"))
            .navigationDestination(for: Event.ID.self) { EventDetailView(id: $0) }
        }
    }

    // MARK: Parti della schermata

    private var weekHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text(selected.formatted(.dateTime.month(.wide))).font(.footnote).foregroundStyle(.secondary)
                Text(selected.formatted(.dateTime.day())).font(.system(size: 44, weight: .bold))
                Text(selected.formatted(.dateTime.weekday(.wide))).font(.footnote).foregroundStyle(.orange)
            }
            Spacer()
            Text("Settimana \(Calendar.current.component(.weekOfYear, from: selected))")
                .font(.caption).padding(.horizontal, 12).padding(.vertical, 4).glass(20)
        }
    }

    private var dayStrip: some View {
        HStack {
            ForEach(days, id: \.self) { d in
                Button { selected = d } label: {
                    VStack(spacing: 2) {
                        Text(d.formatted(.dateTime.weekday(.abbreviated))).font(.caption)
                        Text(d.formatted(.dateTime.day())).font(.subheadline.weight(.bold))
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                    .overlay(alignment: .bottom) {
                        if Calendar.current.isDate(d, inSameDayAs: selected) {
                            Capsule().fill(.orange).frame(height: 2)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var eventsCard: some View {
        let list = store.events(on: selected)
        return VStack(alignment: .leading, spacing: 16) {
            if list.isEmpty { Text("Giornata libera.").foregroundStyle(.secondary) }
            ForEach(list) { e in
                NavigationLink(value: e.id) {
                    HStack(spacing: 12) {
                        Text(e.start.formatted(date: .omitted, time: .shortened))
                            .font(.footnote).foregroundStyle(.secondary).frame(width: 48, alignment: .leading)
                        Capsule().fill(e.category.color).frame(width: 3)
                        VStack(alignment: .leading) {
                            Text(e.title).font(.subheadline.weight(.semibold))
                            Text(e.category.name).font(.footnote).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading).glass(26)
    }

    private var overview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Panoramica").font(.headline).padding(.top, 6)
            HStack(spacing: 6) {
                ForEach(days, id: \.self) { d in
                    VStack(spacing: 6) {
                        Capsule()
                            .fill(store.events(on: d).first?.category.color ?? Color.primary.opacity(0.15))
                            .frame(height: 6)
                        Text(d.formatted(.dateTime.weekday(.narrow))).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(16).glass(26)
        }
    }
}
