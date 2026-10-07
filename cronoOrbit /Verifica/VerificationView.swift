import SwiftUI

#if os(iOS)

// MARK: - Tutti gli impegni da verificare

struct VerificationView: View {
    @Environment(EventStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let pending = store.toVerify()
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if pending.isEmpty {
                        Text("Tutto verificato! Nessun impegno in sospeso.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    }
                    ForEach(pending) { e in
                        VerifyRow(event: e)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .glass(22)
                    }
                }
                .padding()
            }
            .background(AppBackground())
            .navigationTitle("Da verificare")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi", systemImage: "xmark") { dismiss() }
                }
            }
        }
    }
}

#endif
