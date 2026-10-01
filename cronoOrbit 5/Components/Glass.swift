import SwiftUI

#if os(iOS) // solo iPhone

// MARK: - Liquid Glass (iOS 26) con fallback su Material

extension View {
    @ViewBuilder
    func glass(_ radius: CGFloat = 26, interactive: Bool = false) -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(interactive ? .regular.interactive() : .regular,
                             in: .rect(cornerRadius: radius))
        } else {
            self
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(.white.opacity(0.3)))
        }
    }
}

extension View {
    /// Toglie la banda che appare sotto la barra del titolo quando il contenuto scorre.
    @ViewBuilder
    func hideTopBarBand() -> some View {
        if #available(iOS 26, *) {
            self.scrollEdgeEffectHidden(true, for: .top)
                .toolbarBackground(.hidden, for: .navigationBar)
        } else {
            self.toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

/// Il vetro si vede solo se dietro c'è qualcosa di colorato.
struct AppBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let dark = scheme == .dark
        ZStack {
            dark ? Color(red: 0.09, green: 0.06, blue: 0.23) : Color(red: 0.96, green: 0.95, blue: 1.0)
            RadialGradient(colors: [.orange.opacity(dark ? 0.8 : 0.35), .clear], center: .topLeading, startRadius: 0, endRadius: 380)
            RadialGradient(colors: [.pink.opacity(dark ? 0.7 : 0.30), .clear], center: .topTrailing, startRadius: 0, endRadius: 340)
            RadialGradient(colors: [.cyan.opacity(dark ? 0.6 : 0.30), .clear], center: .bottomLeading, startRadius: 0, endRadius: 380)
            RadialGradient(colors: [.indigo.opacity(dark ? 0.8 : 0.30), .clear], center: .bottomTrailing, startRadius: 0, endRadius: 380)
        }
        .ignoresSafeArea()
    }
}
#endif
