import SwiftUI

#if os(iOS) // solo iPhone

struct RootView: View {
    var body: some View {
        TabView { // su iOS 26 la tab bar è automaticamente Liquid Glass
            Tab("Home", systemImage: "house") { HomeView() }
            Tab("Settimana", systemImage: "calendar") { WeekView() }
            Tab("Premi", systemImage: "medal") { RewardsView() }
            Tab("Assistente", systemImage: "sparkles") { AssistantView() }
            Tab("Resoconto", systemImage: "chart.bar.xaxis") { ReportView() }
        }
    }
}
#endif
