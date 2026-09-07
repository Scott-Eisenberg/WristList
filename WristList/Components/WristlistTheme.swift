//
//  WristlistTheme.swift
//  WristList
//

import SwiftUI

enum WristlistTheme {
    static let night = Color(red: 0.05, green: 0.04, blue: 0.09)
    static let plum = Color(red: 0.16, green: 0.08, blue: 0.25)
    static let coral = Color(red: 1.00, green: 0.32, blue: 0.36)
    static let purple = Color(red: 0.61, green: 0.35, blue: 1.00)
    static let amber = Color(red: 1.00, green: 0.67, blue: 0.28)
    static let cyan = Color(red: 0.23, green: 0.88, blue: 0.96)
    static let mint = Color(red: 0.35, green: 0.92, blue: 0.64)

    static func appBackground(for colorScheme: ColorScheme) -> LinearGradient {
        if colorScheme == .dark {
            LinearGradient(
                colors: [night, Color(red: 0.09, green: 0.06, blue: 0.14), Color(red: 0.14, green: 0.07, blue: 0.13)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            LinearGradient(
                colors: [Color(red: 1.00, green: 0.97, blue: 0.96), Color(red: 0.95, green: 0.92, blue: 1.00)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    static func cardFill(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.78)
    }

    static func cardStroke(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }

    static func primaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white : Color(red: 0.09, green: 0.07, blue: 0.12)
    }

    static func secondaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.68) : Color(red: 0.30, green: 0.25, blue: 0.34)
    }

    static func colors(for palette: FestivalPalette) -> [Color] {
        switch palette {
        case .sunset:
            [coral, amber, purple]
        case .violet:
            [purple, Color(red: 0.82, green: 0.30, blue: 0.92), coral]
        case .electric:
            [cyan, purple, coral]
        case .lagoon:
            [cyan, mint, purple]
        case .ember:
            [amber, coral, Color(red: 0.72, green: 0.20, blue: 0.50)]
        }
    }

    static func gradient(for palette: FestivalPalette) -> LinearGradient {
        LinearGradient(
            colors: colors(for: palette),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
