
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
            .navigationTitle(eventID == nil ? LocalizedStringKey("Nuovo evento") : LocalizedStringKey("Modifica evento"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi", systemImage: "xmark") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(
                        eventID == nil ? LocalizedStringKey("Salva") : LocalizedStringKey("Salva modifiche"),
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
            // Se sposti l'inizio oltre la fine, la fine si sposta con lui
            .onChange(of: start) {
                if end < start.addingTimeInterval(900) {
                    end = start.addingTimeInterval(3600)
                }
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
        allDay = event.isAllDay
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
            
            // Manteniamo l'ID dell'evento esistente e passiamo dall'API del repository
            // così l'evento viene anche persistito su disco.
            var updated = store.events[index]
            updated.title = title
            updated.category = category
            updated.start = s
            updated.end = e
            updated.place = place
            updated.notes = notes
            updated.invited = people
            store.update(updated)
            
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

