//
//  PlaceholderTabView.swift
//  WristList
//

import SwiftUI

struct PlaceholderTabView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let palette: FestivalPalette

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                WristlistTheme.appBackground(for: colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: systemImage)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 82, height: 82)
                        .background(WristlistTheme.gradient(for: palette), in: Circle())
                        .shadow(color: WristlistTheme.colors(for: palette).first?.opacity(0.30) ?? .clear, radius: 24, y: 12)

                    VStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))

                        Text(subtitle)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                            .frame(maxWidth: 320)
                    }
                }
                .padding(28)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview("Discover Placeholder") {
    PlaceholderTabView(
        title: "Discover",
        subtitle: "Search festivals, compare lineups, and find the next weekend worth planning around.",
        systemImage: "magnifyingglass",
        palette: .violet
    )
    .preferredColorScheme(.dark)
}
