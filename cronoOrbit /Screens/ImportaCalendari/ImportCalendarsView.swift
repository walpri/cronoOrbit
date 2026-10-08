import SwiftUI
import EventKit
import UIKit

#if os(iOS) // solo iPhone

// MARK: - Importa calendari

struct ImportCalendarsView: View {
    @Environment(EventStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var importer = CalendarImporter()
    @State private var selected = Set<String>()        // calendarIdentifier scelti
    @State private var days = 90
    @State private var category = EventCategory.work
    @State private var importedCount: Int?

    var body: some View {
        NavigationStack {
            Group {
                switch importer.status {
                case .fullAccess:    picker
                case .notDetermined: intro
                default:             denied
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)   // ← nuova riga
            .scrollContentBackground(.hidden)
            .background(AppBackground())
            .navigationTitle("Importa calendari")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi", systemImage: "xmark") { dismiss() }
                }
            }
            .task { if importer.hasAccess { importer.loadCalendars() } }
        }
    }

    // 1) Permesso non ancora chiesto
    private var intro: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus").font(.system(size: 52))
            Text("Porta i tuoi impegni qui").font(.title2.bold())
            Text("Collega i calendari già presenti sul telefono (iCloud, Google, Outlook). Li leggiamo soltanto, non modifichiamo nulla.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button("Consenti accesso") { Task { await importer.requestAccess() } }
                .buttonStyle(.borderedProminent)
        }
        .padding(24).glass(30).padding()
    }

    // 2) Permesso negato / limitato
    private var denied: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.slash").font(.system(size: 44))
            Text("Accesso ai calendari non consentito").font(.headline)
            Text("Attivalo da Impostazioni > cronoOrbit > Calendari.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Link("Apri Impostazioni", destination: URL(string: UIApplication.openSettingsURLString)!)
                .buttonStyle(.borderedProminent)
        }
        .padding(24).glass(30).padding()
    }

    private var picker: some View {
        let groups = Dictionary(grouping: importer.calendars, by: { $0.source.title })
        return Form {
            ForEach(groups.keys.sorted(), id: \.self) { source in
                Section(source) {
                    ForEach(groups[source] ?? [], id: \.calendarIdentifier) { c in
                        Toggle(isOn: binding(for: c.calendarIdentifier)) {
                            Label { Text(c.title) } icon: {
                                Circle().fill(Color(cgColor: c.cgColor)).frame(width: 12, height: 12)
                            }
                        }
                    }
                }
            }
            Section("Opzioni") {
                Picker("Periodo", selection: $days) {
                    Text("30 giorni").tag(30)
                    Text("3 mesi").tag(90)
                    Text("1 anno").tag(365)
                }
                Picker("Categoria", selection: $category) {
                    ForEach(EventCategory.allCases) { Text($0.name).tag($0) }
                }
            }
            Section {
                Button("Importa \(selected.count) calendari", systemImage: "square.and.arrow.down") { runImport() }
                    .disabled(selected.isEmpty)
                if let n = importedCount {
                    Label(n == 0 ? String(localized: "Nessun nuovo evento") : String(localized: "\(n) eventi importati"), systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
        }
    }

    private func binding(for id: String) -> Binding<Bool> {
        Binding(get: { selected.contains(id) },
                set: { isOn in
                    if isOn { selected.insert(id) } else { selected.remove(id) }
                    importedCount = nil
                })
    }

    private func runImport() {
        let chosen = importer.calendars.filter { selected.contains($0.calendarIdentifier) }
        let new = importer.events(from: chosen, days: days, category: category)
        importedCount = store.importEvents(new)
    }
}
#endif
