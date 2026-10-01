import SwiftUI

#if os(iOS) // solo iPhone

// MARK: - Nuovo evento

struct NewEventSheet: View {
    @Environment(EventStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var start = Date.now.addingTimeInterval(3600)
    @State private var end = Date.now.addingTimeInterval(7200)
    @State private var allDay = false
    @State private var category = EventCategory.focus
    @State private var place = ""
    @State private var notes = ""
    @State private var invited = ""

    var body: some View {
        NavigationStack {
            Form {
                Section { TextField("Titolo", text: $title) }
                Section {
                    DatePicker("Inizio", selection: $start, displayedComponents: allDay ? .date : [.date, .hourAndMinute])
                    DatePicker("Fine", selection: $end, in: start..., displayedComponents: allDay ? .date : [.date, .hourAndMinute])
                    Toggle("Tutto il giorno", isOn: $allDay)
                }
                Section("Luogo") { TextField("Posizione", text: $place) }
                Section("Calendario") {
                    Picker("Categoria", selection: $category) {
                        ForEach(EventCategory.allCases) { Text($0.name).tag($0) }
                    }
                }
                Section("Note") { TextEditor(text: $notes).frame(minHeight: 80) }
                Section("Invitati") { TextField("Nomi separati da virgola", text: $invited) }
            }
            .scrollContentBackground(.hidden)
            .background(AppBackground())
            .navigationTitle("Nuovo evento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva", systemImage: "checkmark") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let cal = Calendar.current
        let s = allDay ? cal.startOfDay(for: start) : start
        let e = allDay ? cal.date(byAdding: .minute, value: 1439, to: s)! : max(end, start.addingTimeInterval(900))
        let names = invited.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        store.add(Event(title: title, category: category, start: s, end: e, place: place, notes: notes, invited: ["Tu"] + names))
        dismiss()
    }
}
#endif
