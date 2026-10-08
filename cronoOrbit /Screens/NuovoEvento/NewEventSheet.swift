import SwiftUI
import UniformTypeIdentifiers

struct NewEventSheet: View {
    @Environment(EventStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    let eventID: Event.ID?
    
    @State private var title = ""
    @State private var start = Date.now.addingTimeInterval(3600)
    @State private var end = Date.now.addingTimeInterval(7200)
    @State private var allDay = false
    @State private var category = EventCategory.focus
    @State private var place = ""
    @State private var notes = ""
    
    // Variabili per i contatti
    @State private var invitedFriends: [String] = []
    
    // Interruttori per i popup
    @State private var showContactPicker = false
        
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
                    DatePicker("Inizio", selection: $start, displayedComponents: allDay ? .date : [.date, .hourAndMinute])
                    DatePicker("Fine", selection: $end, in: start..., displayedComponents: allDay ? .date : [.date, .hourAndMinute])
                    Toggle("Tutto il giorno", isOn: $allDay)
                }
                
                Section("Luogo") {
                    TextField("Posizione", text: $place)
                }
                
                Section("Categoria") {
                    Picker("Categoria", selection: $category) {
                        ForEach(EventCategory.allCases) { Text($0.name).tag($0) }
                    }
                }
                
                #if os(iOS)
                Section("Note") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
                #endif
                

                Section(header: Text("Invitati")) {
                    
                    // 1. Mostra gli amici che hai già selezionato
                    ForEach(invitedFriends, id: \.self) { nome in
                        HStack {
                            Text(String(nome.prefix(1)))
                                .font(.caption.bold())
                                .frame(width: 30, height: 30)
                                .background(Color.primary.opacity(0.15), in: Circle())
                            
                            Text(nome)
                            
                            Spacer()
                            
                            #if os(iOS)
                            if let fileURL = generateICSFile(for: title, start: start, end: end, place: place, notes: notes) {
                                // Pulsante di condivisione WhatsApp/iMessage
                                ShareLink(item: fileURL) {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(.blue)
                                        .padding(6)
                                        .background(Color.blue.opacity(0.1), in: Circle())
                                }
                                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                            #endif
                        }
                    }
                    
                    Button {
                        showContactPicker = true
                    } label: {
                        Label("Scegli Contatto", systemImage: "person.crop.circle.badge.plus")
                    }
                }

                
            }
            .scrollContentBackground(.hidden)
            .background {
                #if os(iOS)
                AppBackground()
                #else
                Color.clear
                #endif
            }
            .navigationTitle(eventID == nil ? LocalizedStringKey("Nuovo evento") : LocalizedStringKey("Modifica evento"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi", systemImage: "xmark") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(eventID == nil ? LocalizedStringKey("Salva") : LocalizedStringKey("Salva modifiche"), systemImage: "checkmark") {
                        save()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                loadExistingEvent()
            }
            .onChange(of: start) {
                if end < start.addingTimeInterval(900) {
                    end = start.addingTimeInterval(3600)
                }
            }
            
            .sheet(isPresented: $showContactPicker) {
                #if os(iOS)
                // Usiamo un array vuoto per le mail visto che ora inviamo via WhatsApp
                ContactPicker(selectedContacts: $invitedFriends, selectedEmails: .constant([]))
                    .ignoresSafeArea()
                #else
                Text("Rubrica non supportata su Apple Watch")
                #endif
            }
           
        }
    }
    
    // MARK: - Creazione del File .ICS (Magia dei Calendari)
    
    // MARK: - Generatore File Calendario (.ics)
    
    private func generateICSFile(for title: String, start: Date, end: Date, place: String, notes: String) -> URL? {
        // Se il titolo è vuoto, non creare il file
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return nil }
        
        let cal = Calendar.current
        let s = allDay ? cal.startOfDay(for: start) : start
        let e = allDay ? cal.date(byAdding: .minute, value: 1439, to: s)! : max(end, start.addingTimeInterval(900))
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        let icsContent = """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//CronoOrbit//App//IT
        BEGIN:VEVENT
        DTSTAMP:\(dateFormatter.string(from: Date()))
        DTSTART:\(dateFormatter.string(from: s))
        DTEND:\(dateFormatter.string(from: e))
        SUMMARY:\(title)
        LOCATION:\(place)
        DESCRIPTION:\(notes)
        END:VEVENT
        END:VCALENDAR
        """
        
        let cleanTitle = title.replacingOccurrences(of: " ", with: "_")
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(cleanTitle).ics")
        
        do {
            try icsContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Errore creazione file ICS: \(error)")
            return nil
        }
    }

    
    // MARK: - Funzioni di Supporto
    
    private func loadExistingEvent() {
        guard let eventID, let event = store.events.first(where: { $0.id == eventID }) else { return }
        title = event.title
        start = event.start
        end = event.end
        allDay = event.isAllDay
        category = event.category
        place = event.place
        notes = event.notes
        invitedFriends = event.invited.filter { $0 != "Tu" }
    }
    
    private func save() {
        let cal = Calendar.current
        let s = allDay ? cal.startOfDay(for: start) : start
        let e = allDay ? cal.date(byAdding: .minute, value: 1439, to: s)! : max(end, start.addingTimeInterval(900))
        let people = ["Tu"] + invitedFriends
        
        if let eventID, let index = store.events.firstIndex(where: { $0.id == eventID }) {
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
            store.add(Event(title: title, category: category, start: s, end: e, place: place, notes: notes, invited: people))
        }
        dismiss()
    }
}



