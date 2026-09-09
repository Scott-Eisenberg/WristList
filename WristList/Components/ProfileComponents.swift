//
//  ProfileComponents.swift
//  WristList
//

import SwiftUI

struct ProfileHeaderCard: View {
    let profile: WLProfile
    let metrics: ProfileMetrics
    let onEdit: () -> Void
    let onSettings: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 18) {
            ZStack(alignment: .topTrailing) {
                WristlistTheme.gradient(for: profile.palette)
                    .frame(height: 124)
                    .overlay {
                        HStack(spacing: 10) {
                            ForEach(0..<8, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(Color.white.opacity(index.isMultiple(of: 2) ? 0.28 : 0.12))
                                    .frame(width: 22, height: 132)
                                    .rotationEffect(.degrees(Double(index - 4) * 4))
                            }
                        }
                        .offset(y: 8)
                    }

                HeaderIconButton(systemImage: "gearshape", accessibilityLabel: "Open settings", action: onSettings)
                    .padding(12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(alignment: .bottomLeading) {
                AvatarCircle(initials: profile.avatarInitials, palette: profile.palette, size: 86, fontSize: 28)
                    .overlay {
                        Circle().strokeBorder(Color.white.opacity(0.78), lineWidth: 3)
                    }
                    .shadow(color: WristlistTheme.coral.opacity(0.26), radius: 18, y: 10)
                    .offset(x: 18, y: 42)
                    .accessibilityLabel("Profile picture placeholder with initials \(profile.avatarInitials)")
            }
            .padding(.bottom, 34)

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile.displayName)
                            .font(.system(.title, design: .rounded).weight(.black))
                            .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)

                        Text(profile.username)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(WristlistTheme.coral)
                    }

                    Spacer(minLength: 8)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(metrics.averageRating, format: .number.precision(.fractionLength(1)))
                            .font(.headline.weight(.black))
                            .monospacedDigit()
                            .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                        Text("avg rating")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Average rating \(metrics.averageRating, specifier: "%.1f") out of 10")
                }

                Text(profile.bio)
                    .font(.body)
                    .lineSpacing(2)
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    Label(profile.homeCity, systemImage: "mappin.and.ellipse")
                    Label("\(profile.currentStreak) week streak", systemImage: "flame.fill")
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                .lineLimit(2)
                .minimumScaleFactor(0.80)

                HStack(spacing: 10) {
                    SocialCountView(value: profile.followers, label: "Followers")
                    Divider()
                        .frame(height: 24)
                        .overlay(WristlistTheme.cardStroke(for: colorScheme))
                    SocialCountView(value: profile.following, label: "Following")
                    Spacer()
                    Button("Edit") { onEdit() }
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 44)
                        .background(WristlistTheme.gradient(for: .violet), in: Capsule())
                        .accessibilityLabel("Edit profile")
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(WristlistTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(WristlistTheme.cardStroke(for: colorScheme), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }
}

struct SocialCountView: View {
    let value: Int
    let label: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value, format: .number)
                .font(.headline.weight(.black))
                .monospacedDigit()
                .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label.lowercased())")
    }
}

struct ProfileStatsGrid: View {
    let metrics: ProfileMetrics

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ProfileMetricCard(value: "\(metrics.festivalsRanked)", label: "Ranked", systemImage: "list.number", palette: .sunset)
            ProfileMetricCard(value: "\(metrics.citiesVisited)", label: "Cities", systemImage: "map", palette: .lagoon)
            ProfileMetricCard(value: String(format: "%.1f", metrics.averageRating), label: "Avg score", systemImage: "star.fill", palette: .violet)
            ProfileMetricCard(value: "\(metrics.wantToAttend)", label: "Want to go", systemImage: "sparkles", palette: .electric)
        }
    }
}

struct ProfileMetricCard: View {
    let value: String
    let label: String
    let systemImage: String
    let palette: FestivalPalette

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(WristlistTheme.gradient(for: palette), in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.title3.weight(.black))
                    .monospacedDigit()
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                Text(label)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(minHeight: 62)
        .background(WristlistTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(WristlistTheme.cardStroke(for: colorScheme), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }
}

struct TasteSignalCard: View {
    let signal: TasteSignal

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: signal.systemImage)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(WristlistTheme.gradient(for: signal.palette), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(signal.title)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Text(signal.detail)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.white.opacity(colorScheme == .dark ? 0.06 : 0.56), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(signal.title), \(signal.detail)")
    }
}

struct RankedFestivalRowView: View {
    let festival: WLFestival
    let canMoveUp: Bool
    let canMoveDown: Bool
    var moveUp: (() -> Void)?
    var moveDown: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 2) {
                Text("#")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                Text("\(festival.personalRank)")
                    .font(.title3.weight(.black))
                    .monospacedDigit()
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
            }
            .frame(width: 34)
            .accessibilityHidden(true)

            FestivalArtworkView(festival: festival)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(festival.name)
                        .font(.headline.weight(.black))
                        .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Spacer(minLength: 4)

                    Text(festival.communityRating, format: .number.precision(.fractionLength(1)))
                        .font(.subheadline.weight(.black))
                        .monospacedDigit()
                        .foregroundStyle(WristlistTheme.coral)
                }

                Text("\(festival.cityState) · \(festival.attendedDate.map(DateFormatting.monthYear) ?? festival.dateRangeText)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                    .lineLimit(1)

                Text(festival.summary)
                    .font(.caption)
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                    .lineLimit(2)

                HStack(spacing: 8) {
                    FestivalStatusBadge(status: festival.status, palette: festival.palette)

                    if let moveUp, let moveDown {
                        Spacer(minLength: 4)
                        rankButton(systemImage: "chevron.up", isEnabled: canMoveUp, action: moveUp)
                        rankButton(systemImage: "chevron.down", isEnabled: canMoveDown, action: moveDown)
                    }
                }
            }
        }
        .padding(12)
        .background(WristlistTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(WristlistTheme.cardStroke(for: colorScheme), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rank \(festival.personalRank), \(festival.name), rating \(festival.communityRating, specifier: "%.1f") out of 10, \(festival.cityState)")
    }

    private func rankButton(systemImage: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.caption.weight(.black))
                .frame(width: 32, height: 32)
                .background(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.56), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.35)
        .accessibilityLabel(systemImage == "chevron.up" ? "Move festival up" : "Move festival down")
    }
}

struct CityCoverageCard: View {
    let stat: CityFestivalStat
    let maxCount: Int

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(stat.city)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                Spacer()
                Text("\(stat.count)")
                    .font(.subheadline.weight(.black))
                    .monospacedDigit()
                    .foregroundStyle(WristlistTheme.coral)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(WristlistTheme.cardStroke(for: colorScheme))

                    Capsule()
                        .fill(WristlistTheme.gradient(for: stat.palette))
                        .frame(width: max(10, proxy.size.width * CGFloat(stat.count) / CGFloat(max(maxCount, 1))))
                }
            }
            .frame(height: 6)

            Text("Top: \(stat.topFestivalName)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                .lineLimit(1)
        }
        .padding(12)
        .background(Color.white.opacity(colorScheme == .dark ? 0.06 : 0.56), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(stat.city), \(stat.count) festivals, top festival \(stat.topFestivalName)")
    }
}

struct WristbandMemoryCard: View {
    let memory: WristbandMemory

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(memory.year)
                .font(.caption.weight(.black))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(WristlistTheme.gradient(for: memory.palette), in: Capsule())

            Text(memory.festivalName)
                .font(.headline.weight(.black))
                .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                .lineLimit(1)

            Text(memory.moment)
                .font(.caption)
                .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                .lineLimit(3)
        }
        .padding(14)
        .frame(width: 184, height: 134, alignment: .topLeading)
        .background(WristlistTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(WristlistTheme.cardStroke(for: colorScheme), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(memory.year), \(memory.festivalName), \(memory.moment)")
    }
}

struct FriendMatchCard: View {
    let match: FriendFestivalMatch

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            AvatarCircle(initials: match.initials, palette: match.palette, size: 42, fontSize: 13)

            VStack(alignment: .leading, spacing: 2) {
                Text(match.name)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                Text(match.sharedFavorites)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text("\(match.matchPercent)%")
                .font(.headline.weight(.black))
                .monospacedDigit()
                .foregroundStyle(WristlistTheme.coral)
        }
        .padding(12)
        .background(WristlistTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(WristlistTheme.cardStroke(for: colorScheme), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(match.name), \(match.matchPercent) percent festival match, shared favorites \(match.sharedFavorites)")
    }
}
