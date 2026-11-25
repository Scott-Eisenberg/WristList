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
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                .frame(width: 44, height: 44)
                .background(WristlistTheme.fieldFill(for: colorScheme), in: Circle())
                .overlay(alignment: .bottom) {
                    Circle()
                        .trim(from: 0.60, to: 0.92)
                        .stroke(WristlistTheme.brand, lineWidth: 2)
                        .rotationEffect(.degrees(8))
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
        let accent = WristlistTheme.accent(for: palette)
        let secondary = WristlistTheme.secondaryAccent(for: palette)

        ZStack {
            Circle()
                .fill(accent)

            Rectangle()
                .fill(secondary.opacity(0.82))
                .frame(width: size * 1.15, height: size * 0.36)
                .rotationEffect(.degrees(-18))
                .offset(x: size * 0.10, y: size * 0.18)

            Text(initials)
                .font(.system(size: fontSize, weight: .black, design: .serif))
                .foregroundStyle(WristlistTheme.contrastText(for: palette))
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            Circle()
                .strokeBorder(Color.white.opacity(0.34), lineWidth: 1)
        }
        .accessibilityHidden(true)
    }
}

struct WristbandTag: View {
    let text: String
    let palette: FestivalPalette

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(WristlistTheme.accent(for: palette))
                .frame(width: 14, height: 2)

            Text(text.uppercased())
                .font(WristlistTheme.kickerFont)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
        }
        .accessibilityLabel(text)
    }
}

struct ScoreBadge: View {
    let score: Double
    let palette: FestivalPalette
    var label: String = "Overall score"

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .center, spacing: 7) {
            Rectangle()
                .fill(score == 0 ? WristlistTheme.secondaryText(for: colorScheme).opacity(0.35) : WristlistTheme.accent(for: palette))
                .frame(width: 4, height: 42)

            VStack(alignment: .leading, spacing: 0) {
                Text(score, format: .number.precision(.fractionLength(1)))
                    .font(WristlistTheme.ratingFont)
                    .monospacedDigit()
                    .foregroundStyle(score == 0 ? WristlistTheme.secondaryText(for: colorScheme) : WristlistTheme.primaryText(for: colorScheme))

                Text("/10")
                    .font(WristlistTheme.kickerFont)
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
            }
        }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) \(score, specifier: "%.1f") out of 10")
    }
}

struct FestivalArtworkView: View {
    let festival: WLFestival

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { proxy in
            let accent = WristlistTheme.accent(for: festival.palette)
            let secondary = WristlistTheme.secondaryAccent(for: festival.palette)
            let foreground = WristlistTheme.contrastText(for: festival.palette)
            let cityCode = String(festival.city.prefix(3)).uppercased()

            ZStack(alignment: .bottomLeading) {
                accent

                Rectangle()
                    .fill(secondary)
                    .frame(width: proxy.size.width * 1.34, height: proxy.size.height * 0.34)
                    .rotationEffect(.degrees(-13))
                    .offset(x: -proxy.size.width * 0.16, y: -proxy.size.height * 0.24)

                HStack(spacing: proxy.size.width * 0.035) {
                    ForEach(0..<6, id: \.self) { index in
                        Rectangle()
                            .fill(foreground.opacity(index.isMultiple(of: 2) ? 0.20 : 0.09))
                    }
                }
                .frame(width: proxy.size.width * 0.36)
                .padding(.vertical, proxy.size.height * 0.11)
                .frame(maxWidth: .infinity, alignment: .trailing)

                Text(cityCode)
                    .font(.system(size: max(24, proxy.size.width * 0.40), weight: .black, design: .serif))
                    .foregroundStyle(foreground.opacity(0.18))
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .offset(x: proxy.size.width * 0.30, y: proxy.size.height * 0.04)

                VStack(alignment: .leading, spacing: 4) {
                    Text(festival.startDate, format: .dateTime.month(.abbreviated).year())
                        .font(.system(size: max(9, proxy.size.width * 0.075), weight: .black))
                        .foregroundStyle(foreground.opacity(0.78))
                        .textCase(.uppercase)

                    Text(festival.name.uppercased())
                        .font(.system(size: max(12, proxy.size.width * 0.118), weight: .black, design: .serif))
                        .foregroundStyle(foreground)
                        .lineLimit(3)
                        .minimumScaleFactor(0.48)
                }
                .padding(max(8, proxy.size.width * 0.08))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: WristlistTheme.cornerSmall, style: .continuous))
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
        VStack(alignment: .leading, spacing: 7) {
            if let subtitle {
                Text(subtitle.uppercased())
                    .font(WristlistTheme.kickerFont)
                    .tracking(1.2)
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(WristlistTheme.sectionTitleFont)
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)

                Spacer(minLength: 8)

                if let actionTitle, let action {
                    Button(actionTitle.uppercased(), action: action)
                        .font(WristlistTheme.kickerFont)
                        .tracking(1.0)
                        .foregroundStyle(WristlistTheme.brand)
                        .accessibilityLabel(actionTitle)
                }
            }
        }
    }
}

struct CategoryScoreView: View {
    let score: ReviewCategoryScore
    let palette: FestivalPalette

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(score.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: 8)

                Text(score.score, format: .number.precision(.fractionLength(1)))
                    .font(.subheadline.weight(.black))
                    .monospacedDigit()
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(WristlistTheme.divider(for: colorScheme))

                    Rectangle()
                        .fill(WristlistTheme.accent(for: palette))
                        .frame(width: max(8, proxy.size.width * min(score.score / 10, 1)))
                }
            }
            .frame(height: 4)
        }
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
        VStack(alignment: .leading, spacing: 16) {
            Rectangle()
                .fill(WristlistTheme.brand)
                .frame(width: 72, height: 3)

            HStack(alignment: .top, spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 23, weight: .black))
                    .foregroundStyle(WristlistTheme.brand)
                    .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 7) {
                    Text(title)
                        .font(WristlistTheme.sectionTitleFont)
                        .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))

                    Text(message)
                        .font(.subheadline)
                        .lineSpacing(2)
                        .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                        .fixedSize(horizontal: false, vertical: true)

                    if let actionTitle, let action {
                        Button(actionTitle, action: action)
                            .buttonStyle(PrimaryActionButtonStyle())
                            .padding(.top, 4)
                    }
                }
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }
}

struct FestivalStatusBadge: View {
    let status: AttendanceStatus
    let palette: FestivalPalette

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Label(status.title.uppercased(), systemImage: status.systemImage)
            .font(WristlistTheme.kickerFont)
            .tracking(0.7)
            .lineLimit(1)
            .minimumScaleFactor(0.76)
            .foregroundStyle(status == .none ? WristlistTheme.secondaryText(for: colorScheme) : WristlistTheme.accent(for: palette))
            .accessibilityLabel(status.title)
    }
}

struct FestivalCompactRow: View {
    let festival: WLFestival
    var trailingText: String?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .center, spacing: 13) {
            FestivalArtworkView(festival: festival)
                .frame(width: 58, height: 72)

            VStack(alignment: .leading, spacing: 6) {
                Text(festival.name)
                    .font(.system(size: 18, weight: .black, design: .serif))
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)

                Text("\(festival.cityState) / \(festival.dateRangeText)")
                    .font(WristlistTheme.metadataFont)
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)

                HStack(spacing: 10) {
                    ForEach(festival.genres.prefix(2), id: \.self) { genre in
                        WristbandTag(text: genre, palette: festival.palette)
                    }
                }
            }

            Spacer(minLength: 8)

            if let trailingText {
                Text(trailingText)
                    .font(.system(size: 15, weight: .black, design: .serif))
                    .monospacedDigit()
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(festival.name), \(festival.cityState), \(festival.dateRangeText)")
    }
}

struct EditorialDivider: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Rectangle()
            .fill(WristlistTheme.divider(for: colorScheme))
            .frame(height: 1)
            .accessibilityHidden(true)
    }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.black))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50)
            .padding(.horizontal, 16)
            .background(isEnabled ? WristlistTheme.brand : WristlistTheme.secondaryText(for: colorScheme).opacity(0.32))
            .clipShape(RoundedRectangle(cornerRadius: WristlistTheme.cornerSmall, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

struct SecondaryActionButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.black))
            .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
            .frame(maxWidth: .infinity)
            .frame(minHeight: 46)
            .padding(.horizontal, 14)
            .background(WristlistTheme.fieldFill(for: colorScheme))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(WristlistTheme.divider(for: colorScheme))
                    .frame(height: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: WristlistTheme.cornerSmall, style: .continuous))
            .opacity(configuration.isPressed ? 0.74 : 1)
    }
}
