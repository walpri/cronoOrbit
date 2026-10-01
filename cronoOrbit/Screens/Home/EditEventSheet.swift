/*
import SwiftUI

struct EditEventSheet: View {

    let event: Event

    @Environment(EventStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var start: Date
    @State private var end: Date
    @State private var category: EventCategory
    @State private var place: String
    @State private var notes: String
    @State private var invited: String

    init(event: Event) {

        self.event = event

        _title = State(initialValue: event.title)
        _start = State(initialValue: event.start)
        _end = State(initialValue: event.end)
        _category = State(initialValue: event.category)
        _place = State(initialValue: event.place)
        _notes = State(initialValue: event.notes)
        _invited = State(initialValue: event.invited
            .filter { $0 != "Tu" }
            .joined(separator: ", "))
    }

    var body: some View {

        NavigationStack {

            Form {

                // TITOLO
                Section {

                    TextField(
                        "Titolo",
                        text: $title
                    )
                }

                // DATA E ORA
                Section {

                    DatePicker(
                        "Inizio",
                        selection: $start,
                        displayedComponents: [
                            .date,
                            .hourAndMinute
                        ]
                    )

                    DatePicker(
                        "Fine",
                        selection: $end,
                        in: start...,
                        displayedComponents: [
                            .date,
                            .hourAndMinute
                        ]
                    )
                }

                // LUOGO
                Section("Luogo") {

                    TextField(
                        "Posizione",
                        text: $place
                    )
                }

                // CATEGORIA
                Section("Calendario") {

                    Picker(
                        "Categoria",
                        selection: $category
                    ) {

                        ForEach(EventCategory.allCases) { category in

                            Text(category.rawValue)
                                .tag(category)
                        }
                    }
                }

                // NOTE
                Section("Note") {

                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }

                // INVITATI
                Section("Invitati") {

                    TextField(
                        "Nomi separati da virgola",
                        text: $invited
                    )
                }
            }

            .scrollContentBackground(.hidden)
            .background(AppBackground())

            .navigationTitle("Modifica evento")
            .navigationBarTitleDisplayMode(.inline)

            .toolbar {

                // CHIUDI
                ToolbarItem(placement: .cancellationAction) {

                    Button(
                        "Chiudi",
                        systemImage: "xmark"
                    ) {
                        dismiss()
                    }
                }

                // SALVA
                ToolbarItem(placement: .confirmationAction) {

                    Button(
                        "Salva",
                        systemImage: "checkmark"
                    ) {
                        save()
                    }
                    .disabled(
                        title
                            .trimmingCharacters(
                                in: .whitespaces
                            )
                            .isEmpty
                    )
                }
            }
        }
    }

    private func save() {

        let names = invited
            .split(separator: ",")
            .map {
                $0.trimmingCharacters(
                    in: .whitespaces
                )
            }
            .filter {
                !$0.isEmpty
            }

        let updatedEvent = Event(
            id: event.id,
            title: title,
            category: category,
            start: start,
            end: max(
                end,
                start.addingTimeInterval(900)
            ),
            place: place,
            notes: notes,
            invited: ["Tu"] + names,
            reminderMinutes: event.reminderMinutes
        )

        store.update(updatedEvent)

        dismiss()
    }
}
 */
