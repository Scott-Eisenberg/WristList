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

                    VStack(spacing: 8) {
                        Text(title)
                            .font(.title2.weight(.bold))
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
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
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
