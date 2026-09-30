import SwiftUI

// MARK: - Settimana

struct WeekView: View {
    @Environment(EventStore.self) private var store
    @State private var selected = Date.now

    private var days: [Date] {
        let cal = Calendar.current
        let start = cal.dateInterval(of: .weekOfYear, for: .now)!.start
        return (0..<7).map { cal.date(byAdding: .day, value: $0, to: start)! }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            Text(selected.formatted(.dateTime.month(.wide))).font(.footnote).foregroundStyle(.secondary)
                            Text(selected.formatted(.dateTime.day())).font(.system(size: 44, weight: .bold))
                            Text(selected.formatted(.dateTime.weekday(.wide))).font(.footnote).foregroundStyle(.yellow)
                        }
                        Spacer()
                        Text("Settimana \(Calendar.current.component(.weekOfYear, from: selected))")
                            .font(.caption).padding(.horizontal, 12).padding(.vertical, 4).glass(20)
                    }

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
                                        Capsule().fill(.yellow).frame(height: 2)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    let list = store.events(on: selected)
                    VStack(alignment: .leading, spacing: 16) {
                        if list.isEmpty { Text("Giornata libera.").foregroundStyle(.secondary) }
                        ForEach(list) { e in
                            NavigationLink(value: e.id) {
                                HStack(spacing: 12) {
                                    Text(e.start.formatted(date: .omitted, time: .shortened))
                                        .font(.footnote).foregroundStyle(.secondary).frame(width: 48, alignment: .leading)
                                    Capsule().fill(e.category.color).frame(width: 3)
                                    VStack(alignment: .leading) {
                                        Text(e.title).font(.subheadline.weight(.semibold))
                                        Text(e.category.rawValue).font(.footnote).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16).frame(maxWidth: .infinity, alignment: .leading).glass(26)

                    Text("Panoramica").font(.headline).padding(.top, 6)
                    HStack(spacing: 6) {
                        ForEach(days, id: \.self) { d in
                            VStack(spacing: 6) {
                                Capsule()
                                    .fill(store.events(on: d).first?.category.color ?? Color.white.opacity(0.3))
                                    .frame(height: 6)
                                Text(d.formatted(.dateTime.weekday(.narrow))).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(16).glass(26)
                }
                .padding()
            }
            .background(AppBackground())
            .navigationTitle("La tua settimana")
            .navigationDestination(for: Event.ID.self) { EventDetailView(id: $0) }
        }
    }
}
