//
//  WristlistTheme.swift
//  WristList
//

import SwiftUI

enum WristlistTheme {
    static let ink = Color(red: 0.08, green: 0.09, blue: 0.09)
    static let deepInk = Color(red: 0.04, green: 0.05, blue: 0.05)
    static let paper = Color(red: 0.97, green: 0.98, blue: 0.96)
    static let warmPaper = Color(red: 1.00, green: 0.99, blue: 0.96)
    static let brand = Color(red: 0.04, green: 0.36, blue: 0.34)
    static let brandDark = Color(red: 0.02, green: 0.22, blue: 0.21)
    static let scoreGreen = Color(red: 0.12, green: 0.55, blue: 0.38)
    static let coral = Color(red: 0.88, green: 0.22, blue: 0.12)
    static let purple = Color(red: 0.38, green: 0.28, blue: 0.56)
    static let amber = Color(red: 0.84, green: 0.53, blue: 0.16)
    static let cyan = Color(red: 0.12, green: 0.46, blue: 0.55)
    static let mint = Color(red: 0.22, green: 0.55, blue: 0.40)

    static func appBackground(for colorScheme: ColorScheme) -> LinearGradient {
        if colorScheme == .dark {
            LinearGradient(
                colors: [deepInk, deepInk],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            LinearGradient(
                colors: [paper, paper],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    static func cardFill(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 0.10, green: 0.12, blue: 0.12) : warmPaper
    }

    static func cardStroke(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.10)
    }

    static func primaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 0.95, green: 0.96, blue: 0.94) : ink
    }

    static func secondaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.64) : Color(red: 0.38, green: 0.42, blue: 0.40)
    }

    static func tertiaryFill(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04)
    }

    static func colors(for palette: FestivalPalette) -> [Color] {
        switch palette {
        case .sunset:
            [coral]
        case .violet:
            [purple]
        case .electric:
            [cyan]
        case .lagoon:
            [mint]
        case .ember:
            [amber]
        }
    }

    static func gradient(for palette: FestivalPalette) -> LinearGradient {
        let color = colors(for: palette).first ?? brand
        return LinearGradient(
            colors: [color, color],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
