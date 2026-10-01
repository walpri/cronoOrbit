import SwiftUI

// MARK: - Vista mese

struct MonthGridView: View {
    @Environment(EventStore.self) private var store
    @Binding var selected: Date
    @State private var month = Calendar.current.dateInterval(of: .month, for: .now)!.start

    private var cal: Calendar { .current }

    /// Celle della griglia: prima i vuoti fino al primo giorno del mese, poi i giorni.
    private var cells: [Date?] {
        let range = cal.range(of: .day, in: .month, for: month)!
        let offset = (cal.component(.weekday, from: month) - cal.firstWeekday + 7) % 7
        var out: [Date?] = Array(repeating: nil, count: offset)
        out += range.map { Optional(cal.date(byAdding: .day, value: $0 - 1, to: month)!) }
        return out
    }

    /// Iniziali dei giorni, partendo dal primo giorno della settimana del dispositivo.
    private var weekdaySymbols: [String] {
        let s = cal.veryShortStandaloneWeekdaySymbols
        let shift = cal.firstWeekday - 1
        return Array(s[shift...] + s[..<shift])
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(month.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)
                Spacer()
                Button("Mese precedente", systemImage: "chevron.left") { shift(-1) }
                Button("Mese successivo", systemImage: "chevron.right") { shift(1) }
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.plain)
            .font(.subheadline.weight(.semibold))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 6) {
                ForEach(weekdaySymbols.indices, id: \.self) { i in
                    Text(weekdaySymbols[i]).font(.caption).foregroundStyle(.secondary)
                }
                ForEach(cells.indices, id: \.self) { i in
                    if let d = cells[i] { dayCell(d) } else { Color.clear.frame(height: 44) }
                }
            }
        }
        .padding(16).frame(maxWidth: .infinity).glass(26)
        .onAppear { month = cal.dateInterval(of: .month, for: selected)!.start }
    }

    private func dayCell(_ d: Date) -> some View {
        let isSelected = cal.isDate(d, inSameDayAs: selected)
        let isToday = cal.isDateInToday(d)
        let colors = store.events(on: d).prefix(3).map(\.category.color)

        return Button { selected = d } label: {
            VStack(spacing: 3) {
                Text(d.formatted(.dateTime.day()))
                    .font(.subheadline.weight(isSelected || isToday ? .bold : .regular))
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                    .frame(width: 32, height: 32)
                    .background {
                        if isSelected { Circle().fill(.orange) }
                        else if isToday { Circle().strokeBorder(.orange, lineWidth: 1.5) }
                    }
                HStack(spacing: 3) {
                    ForEach(colors.indices, id: \.self) { i in
                        Circle().fill(colors[i]).frame(width: 5, height: 5)
                    }
                }
                .frame(height: 5)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func shift(_ value: Int) {
        month = cal.date(byAdding: .month, value: value, to: month)!
    }
}
