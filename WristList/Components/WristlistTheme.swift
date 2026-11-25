//
//  WristlistTheme.swift
//  WristList
//

import SwiftUI

enum WristlistTheme {
    static let ink = Color(red: 0.08, green: 0.08, blue: 0.07)
    static let deepInk = Color(red: 0.04, green: 0.04, blue: 0.035)
    static let paper = Color(red: 0.96, green: 0.95, blue: 0.90)
    static let warmPaper = Color(red: 1.00, green: 0.985, blue: 0.93)
    static let agedPaper = Color(red: 0.91, green: 0.90, blue: 0.84)
    static let charcoal = Color(red: 0.14, green: 0.145, blue: 0.13)
    static let graphite = Color(red: 0.23, green: 0.235, blue: 0.21)
    static let brand = Color(red: 0.72, green: 0.14, blue: 0.08)
    static let brandDark = Color(red: 0.34, green: 0.055, blue: 0.04)
    static let scoreGreen = Color(red: 0.11, green: 0.49, blue: 0.35)
    static let coral = Color(red: 0.91, green: 0.18, blue: 0.08)
    static let purple = Color(red: 0.30, green: 0.20, blue: 0.44)
    static let amber = Color(red: 0.76, green: 0.48, blue: 0.12)
    static let cyan = Color(red: 0.06, green: 0.39, blue: 0.46)
    static let mint = Color(red: 0.13, green: 0.42, blue: 0.31)
    static let acid = Color(red: 0.86, green: 0.92, blue: 0.33)
    static let clay = Color(red: 0.62, green: 0.28, blue: 0.20)
    static let plum = Color(red: 0.48, green: 0.28, blue: 0.54)
    static let lagoon = Color(red: 0.03, green: 0.35, blue: 0.35)

    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 14
    static let spacingL: CGFloat = 20
    static let spacingXL: CGFloat = 28

    static let cornerTight: CGFloat = 3
    static let cornerSmall: CGFloat = 6
    static let cornerMedium: CGFloat = 8

    static var mastheadFont: Font {
        .system(size: 42, weight: .black, design: .serif)
    }

    static var pageTitleFont: Font {
        .system(size: 34, weight: .black, design: .serif)
    }

    static var festivalTitleFont: Font {
        .system(size: 26, weight: .black, design: .serif)
    }

    static var sectionTitleFont: Font {
        .system(size: 20, weight: .black, design: .serif)
    }

    static var kickerFont: Font {
        .system(size: 11, weight: .black, design: .default)
    }

    static var metadataFont: Font {
        .system(size: 13, weight: .semibold, design: .default)
    }

    static var ratingFont: Font {
        .system(size: 28, weight: .black, design: .serif)
    }

    static func appBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? deepInk : paper
    }

    static func cardFill(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? charcoal : warmPaper
    }

    static func cardStroke(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.16)
    }

    static func primaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 0.95, green: 0.96, blue: 0.94) : ink
    }

    static func secondaryText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.64) : Color(red: 0.38, green: 0.42, blue: 0.40)
    }

    static func tertiaryFill(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.07) : Color.black.opacity(0.055)
    }

    static func fieldFill(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.055) : Color.white.opacity(0.58)
    }

    static func divider(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.16) : Color.black.opacity(0.18)
    }

    static func contrastText(for palette: FestivalPalette) -> Color {
        switch palette {
        case .sunset, .ember:
            deepInk
        case .violet, .electric, .lagoon:
            .white
        }
    }

    static func accent(for palette: FestivalPalette) -> Color {
        colors(for: palette).first ?? brand
    }

    static func secondaryAccent(for palette: FestivalPalette) -> Color {
        switch palette {
        case .sunset:
            acid
        case .violet:
            clay
        case .electric:
            acid
        case .lagoon:
            amber
        case .ember:
            plum
        }
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

    static func gradient(for palette: FestivalPalette) -> Color {
        colors(for: palette).first ?? brand
    }
}
