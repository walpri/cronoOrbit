import SwiftUI

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

/// Il vetro si vede solo se dietro c'è qualcosa di colorato.
struct AppBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.09, green: 0.06, blue: 0.23)
            RadialGradient(colors: [.orange.opacity(0.8), .clear], center: .topLeading, startRadius: 0, endRadius: 380)
            RadialGradient(colors: [.pink.opacity(0.7), .clear], center: .topTrailing, startRadius: 0, endRadius: 340)
            RadialGradient(colors: [.cyan.opacity(0.6), .clear], center: .bottomLeading, startRadius: 0, endRadius: 380)
            RadialGradient(colors: [.indigo.opacity(0.8), .clear], center: .bottomTrailing, startRadius: 0, endRadius: 380)
        }
        .ignoresSafeArea()
    }
}
