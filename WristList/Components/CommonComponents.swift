//
//  CommonComponents.swift
//  WristList
//

import SwiftUI

struct HeaderIconButton: View {
    let systemImage: String
    let accessibilityLabel: String
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                .frame(width: 44, height: 44)
                .background(WristlistTheme.cardFill(for: colorScheme), in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(WristlistTheme.cardStroke(for: colorScheme), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

struct AvatarButton: View {
    let initials: String
    let palette: FestivalPalette
    let accessibilityLabel: String
    let action: () -> Void

    init(initials: String, palette: FestivalPalette, accessibilityLabel: String = "Open profile", action: @escaping () -> Void) {
        self.initials = initials
        self.palette = palette
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            AvatarCircle(initials: initials, palette: palette, size: 44, fontSize: 14)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

struct AvatarCircle: View {
    let initials: String
    let palette: FestivalPalette
    let size: CGFloat
    let fontSize: CGFloat

    var body: some View {
        Text(initials)
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(WristlistTheme.gradient(for: palette), in: Circle())
            .overlay {
                Circle()
                    .strokeBorder(Color.white.opacity(0.30), lineWidth: 1)
            }
            .accessibilityHidden(true)
    }
}

struct WristbandTag: View {
    let text: String
    let palette: FestivalPalette

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(WristlistTheme.colors(for: palette).first ?? WristlistTheme.brand)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(WristlistTheme.tertiaryFill(for: colorScheme), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(WristlistTheme.cardStroke(for: colorScheme), lineWidth: 1)
            }
            .accessibilityLabel(text)
    }
}

struct ScoreBadge: View {
    let score: Double
    let palette: FestivalPalette
    var label: String = "Overall score"

    var body: some View {
        VStack(spacing: 0) {
            Text(score, format: .number.precision(.fractionLength(1)))
                .font(.system(size: 21, weight: .black, design: .rounded))
                .monospacedDigit()
            Text("/10")
                .font(.caption2.weight(.bold))
                .opacity(0.78)
        }
        .foregroundStyle(.white)
        .frame(width: 56, height: 50)
        .background(WristlistTheme.scoreGreen, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityLabel("\(label) \(score, specifier: "%.1f") out of 10")
    }
}

struct FestivalArtworkView: View {
    let festival: WLFestival

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let accent = WristlistTheme.colors(for: festival.palette).first ?? WristlistTheme.brand

        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(accent.opacity(colorScheme == .dark ? 0.28 : 0.16))

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(accent.opacity(colorScheme == .dark ? 0.45 : 0.26), lineWidth: 1)

            HStack(spacing: 5) {
                ForEach(0..<5, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(index.isMultiple(of: 2) ? accent : accent.opacity(0.46))
                        .frame(width: 9)
                }
            }
            .padding(.vertical, 14)

            VStack {
                Spacer()
                HStack {
                    Image(systemName: "ticket")
                        .font(.caption.weight(.black))
                    Spacer()
                    Text(festival.startDate, format: .dateTime.month(.abbreviated))
                        .font(.caption2.weight(.black))
                        .textCase(.uppercase)
                }
                .foregroundStyle(accent)
                .padding(8)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Festival artwork for \(festival.name) in \(festival.cityState)")
    }
}

struct SectionTitleView: View {
    let title: String
    var subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))

                if let subtitle {
                    Text(subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                }
            }

            Spacer(minLength: 8)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(WristlistTheme.brand)
                    .accessibilityLabel(actionTitle)
            }
        }
    }
}

struct CategoryScoreView: View {
    let score: ReviewCategoryScore
    let palette: FestivalPalette

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(score.name)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: 4)

                Text(score.score, format: .number.precision(.fractionLength(1)))
                    .font(.caption.weight(.black))
                    .monospacedDigit()
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(WristlistTheme.cardStroke(for: colorScheme))

                    Capsule()
                        .fill(WristlistTheme.gradient(for: palette))
                        .frame(width: max(8, proxy.size.width * min(score.score / 10, 1)))
                }
            }
            .frame(height: 5)
        }
        .padding(10)
        .background(WristlistTheme.tertiaryFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(score.name) score \(score.score, specifier: "%.1f") out of 10")
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    var actionTitle: String?
    var action: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(WristlistTheme.brand, in: Circle())

            VStack(spacing: 6) {
                Text(title)
                    .font(.headline.weight(.black))
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                Text(message)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(WristlistTheme.brand, in: Capsule())
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(WristlistTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(WristlistTheme.cardStroke(for: colorScheme), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }
}

struct FestivalStatusBadge: View {
    let status: AttendanceStatus
    let palette: FestivalPalette

    var body: some View {
        Label(status.title, systemImage: status.systemImage)
            .font(.caption.weight(.black))
            .lineLimit(1)
            .minimumScaleFactor(0.80)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(WristlistTheme.gradient(for: palette), in: Capsule())
            .accessibilityLabel(status.title)
    }
}

struct FestivalCompactRow: View {
    let festival: WLFestival
    var trailingText: String?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            FestivalArtworkView(festival: festival)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(festival.name)
                    .font(.headline.weight(.black))
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                    .lineLimit(1)
                    .minimumScaleFactor(0.80)

                Text("\(festival.cityState) · \(festival.dateRangeText)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                    .lineLimit(1)

                Text(festival.genres.prefix(3).joined(separator: " / "))
                    .font(.caption)
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if let trailingText {
                Text(trailingText)
                    .font(.subheadline.weight(.black))
                    .monospacedDigit()
                    .foregroundStyle(WristlistTheme.scoreGreen)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(festival.name), \(festival.cityState), \(festival.dateRangeText)")
    }
}
