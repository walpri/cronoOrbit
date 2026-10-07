import SwiftUI

#if os(iOS)

// MARK: - Assistente

struct AssistantView: View {
    @Environment(EventStore.self) private var store
    @State private var vm = AssistantViewModel()
    @State private var input = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(vm.messages) { bubble($0).id($0.id) }
                        if vm.isWorking { ProgressView().padding(.leading) }
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.immediately)                        // trascina la chat: la tastiera scende
                .simultaneousGesture(TapGesture().onEnded { inputFocused = false })   // tocca la chat: la tastiera scende
                .onChange(of: vm.messages.count) {
                    if let last = vm.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
            .background(AppBackground())
            .hideTopBarBand()
            .navigationTitle("Assistente")
            .safeAreaInset(edge: .bottom) { inputBar }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Chiudi tastiera", systemImage: "keyboard.chevron.compact.down") { inputFocused = false }
                        .labelStyle(.iconOnly)
                }
            }
        }
    }

    // MARK: Messaggi

    private func bubble(_ m: ChatMessage) -> some View {
        VStack(alignment: m.role == .user ? .trailing : .leading, spacing: 8) {
            if m.role == .user {
                Text(m.text)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(.orange, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                Text(m.text)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .glass(20)
            }
            ForEach(m.actions) { action in
                Button { vm.perform(action, in: m.id, store: store) } label: {
                    Label(action.label, systemImage: action.icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(action.destructive ? Color.red : Color.primary)
                        .padding(.horizontal, 14).padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .glass(18, interactive: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: m.role == .user ? .trailing : .leading)
    }

    // MARK: Barra di input

    private var inputBar: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    chip("Che impegni ho oggi?") {
                        vm.showList(on: Calendar.current.startOfDay(for: .now), store: store,
                                    echo: String(localized: "Che impegni ho oggi?"))
                    }
                    chip("Quando sono libero oggi?") {
                        vm.showFree(on: Calendar.current.startOfDay(for: .now), store: store,
                                    echo: String(localized: "Quando sono libero oggi?"))
                    }
                    chip("Quando sono libero domani?") {
                        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now)) ?? .now
                        vm.showFree(on: tomorrow, store: store, echo: String(localized: "Quando sono libero domani?"))
                    }
                    if !AssistantService.isAvailable { durationMenu }
                }
            }
            HStack(spacing: 8) {
                TextField("Scrivi un impegno…", text: $input, axis: .vertical)
                    .lineLimit(1...3)
                    .submitLabel(.send)
                    .focused($inputFocused)
                    .onSubmit(send)
                Button("Invia", systemImage: "arrow.up.circle.fill", action: send)
                    .labelStyle(.iconOnly)
                    .font(.title2)
                    .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || vm.isWorking)
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .glass(26)
        }
        .padding(.horizontal).padding(.bottom, 8)
    }

    private func chip(_ title: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 12).padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .glass(16, interactive: true)
    }

    private var durationMenu: some View {
        Menu {
            Picker("Durata", selection: $vm.defaultMinutes) {
                ForEach([30, 60, 90, 120], id: \.self) { Text("\($0) min").tag($0) }
            }
        } label: {
            Label("\(vm.defaultMinutes) min", systemImage: "clock")
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 12).padding(.vertical, 8)
        }
        .glass(16, interactive: true)
    }

    private func send() {
        let text = input
        input = ""
        Task { await vm.send(text, store: store) }
    }
}

#endif
