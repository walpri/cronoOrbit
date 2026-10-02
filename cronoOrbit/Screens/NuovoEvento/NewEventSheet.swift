
import SwiftUI

#if os(iOS)

struct NewEventSheet: View {
    
    @Environment(EventStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    // Se nil → nuovo evento
    // Se valorizzato → modifica evento esistente
    let eventID: Event.ID?
    
    @State private var title = ""
    @State private var start = Date.now.addingTimeInterval(3600)
    @State private var end = Date.now.addingTimeInterval(7200)
    @State private var allDay = false
    @State private var category = EventCategory.focus
    @State private var place = ""
    @State private var notes = ""
    @State private var invited = ""
    
    init(eventID: Event.ID? = nil) {
        self.eventID = eventID
    }
    
    var body: some View {
        NavigationStack {
            
            Form {
                
                Section {
                    TextField("Titolo", text: $title)
                }
                
                Section {
                    DatePicker(
                        "Inizio",
                        selection: $start,
                        displayedComponents: allDay
                        ? .date
                        : [.date, .hourAndMinute]
                    )
                    
                    DatePicker(
                        "Fine",
                        selection: $end,
                        in: start...,
                        displayedComponents: allDay
                        ? .date
                        : [.date, .hourAndMinute]
                    )
                    
                    Toggle("Tutto il giorno", isOn: $allDay)
                }
                
                Section("Luogo") {
                    TextField("Posizione", text: $place)
                }
                
                Section("Calendario") {
                    Picker("Categoria", selection: $category) {
                        ForEach(EventCategory.allCases) {
                            Text($0.name).tag($0)
                        }
                    }
                }
                
                Section("Note") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
                
                Section("Invitati") {
                    TextField(
                        "Nomi separati da virgola",
                        text: $invited
                    )
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppBackground())
            .navigationTitle(eventID == nil ? "Nuovo evento" : "Modifica evento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi", systemImage: "xmark") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(
                        eventID == nil ? "Salva" : "Salva modifiche",
                        systemImage: "checkmark"
                    ) {
                        save()
                    }
                    .disabled(
                        title.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    )
                }
            }
            .onAppear {
                loadExistingEvent()
            }
        }
    }
    
    // MARK: - Carica evento da modificare
    
    private func loadExistingEvent() {
        
        guard let eventID,
              let event = store.events.first(
                where: { $0.id == eventID }
              )
        else {
            return
        }
        
        title = event.title
        start = event.start
        end = event.end
        category = event.category
        place = event.place
        notes = event.notes
        
        invited = event.invited
            .filter { $0 != "Tu" }
            .joined(separator: ", ")
    }
    
    // MARK: - Salvataggio
    
    private func save() {
        
        let cal = Calendar.current
        
        let s = allDay
        ? cal.startOfDay(for: start)
        : start
        
        let e = allDay
        ? cal.date(
            byAdding: .minute,
            value: 1439,
            to: s
        )!
        : max(
            end,
            start.addingTimeInterval(900)
        )
        
        let names = invited
            .split(separator: ",")
            .map {
                $0.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            }
            .filter {
                !$0.isEmpty
            }
        
        let people = ["Tu"] + names
        
        if let eventID,
           let index = store.events.firstIndex(
                where: { $0.id == eventID }
           ) {
            
            // Manteniamo l'ID dell'evento esistente
            store.events[index].title = title
            store.events[index].category = category
            store.events[index].start = s
            store.events[index].end = e
            store.events[index].place = place
            store.events[index].notes = notes
            store.events[index].invited = people
            
        } else {
            
            store.add(
                Event(
                    title: title,
                    category: category,
                    start: s,
                    end: e,
                    place: place,
                    notes: notes,
                    invited: people
                )
            )
        }
        
        dismiss()
    }
}

#endif

