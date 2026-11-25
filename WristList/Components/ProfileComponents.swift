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
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                AvatarCircle(initials: profile.avatarInitials, palette: profile.palette, size: 78, fontSize: 25)
                    .accessibilityLabel("Profile picture placeholder with initials \(profile.avatarInitials)")

                Spacer(minLength: 16)

                HeaderIconButton(systemImage: "gearshape", accessibilityLabel: "Open settings", action: onSettings)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(profile.displayName)
                    .font(WristlistTheme.pageTitleFont)
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                    .lineLimit(2)
                    .minimumScaleFactor(0.70)

                HStack(spacing: 11) {
                    Text(profile.username)
                        .foregroundStyle(WristlistTheme.brand)
                    Text(profile.homeCity)
                    Text("\(profile.currentStreak) week streak")
                }
                .font(WristlistTheme.metadataFont)
                .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                .lineLimit(2)
                .minimumScaleFactor(0.78)
            }

            Text(profile.bio)
                .font(.body)
                .lineSpacing(3)
                .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .bottom, spacing: 18) {
                SocialCountView(value: profile.followers, label: "Followers")
                SocialCountView(value: profile.following, label: "Following")
                SocialCountView(value: metrics.festivalsRanked, label: "Ranked")

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(metrics.averageRating, format: .number.precision(.fractionLength(1)))
                        .font(.system(size: 30, weight: .black, design: .serif))
                        .monospacedDigit()
                        .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                    Text("AVG")
                        .font(WristlistTheme.kickerFont)
                        .tracking(1)
                        .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Average rating \(metrics.averageRating, specifier: "%.1f") out of 10")
            }

            Button("Edit Profile", action: onEdit)
                .buttonStyle(SecondaryActionButtonStyle())
                .accessibilityLabel("Edit profile")
        }
        .padding(.top, 6)
        .accessibilityElement(children: .contain)
    }
}

struct SocialCountView: View {
    let value: Int
    let label: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value, format: .number)
                .font(.system(size: 19, weight: .black, design: .serif))
                .monospacedDigit()
                .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
            Text(label.uppercased())
                .font(WristlistTheme.kickerFont)
                .tracking(0.7)
                .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label.lowercased())")
    }
}

struct ProfileStatsGrid: View {
    let metrics: ProfileMetrics

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            ProfileMetricCard(value: "\(metrics.savedFestivals)", label: "Saved", systemImage: "bookmark", palette: .sunset)
            ProfileMetricCard(value: "\(metrics.citiesVisited)", label: "Cities", systemImage: "map", palette: .lagoon)
            ProfileMetricCard(value: "\(metrics.wantToAttend)", label: "Want", systemImage: "sparkles", palette: .electric)
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
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(WristlistTheme.accent(for: palette))
                .frame(height: 18, alignment: .leading)

            Text(value)
                .font(.system(size: 24, weight: .black, design: .serif))
                .monospacedDigit()
                .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))

            Text(label.uppercased())
                .font(WristlistTheme.kickerFont)
                .tracking(0.7)
                .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }
}

struct TasteSignalCard: View {
    let signal: TasteSignal

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: signal.systemImage)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(WristlistTheme.accent(for: signal.palette))
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(signal.title)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(signal.detail)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            EditorialDivider()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(signal.title), \(signal.detail)")
    }
}

struct RankedFestivalRowView: View {
    let festival: WLFestival
    let canMoveUp: Bool
    let canMoveDown: Bool
    var moveUp: (() -> Void)? = nil
    var moveDown: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    @MainActor
    private var attendedText: String {
        festival.attendedDate.map(DateFormatting.monthYear) ?? festival.dateRangeText
    }

    private var rankText: String {
        festival.personalRank > 0 ? String(format: "#%02d", festival.personalRank) : "--"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                Text(rankText)
                    .font(.system(size: 26, weight: .black, design: .serif))
                    .monospacedDigit()
                    .foregroundStyle(WristlistTheme.accent(for: festival.palette))
                    .frame(width: 58, alignment: .leading)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(festival.name.uppercased())
                                .font(.system(size: 22, weight: .black, design: .serif))
                                .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                                .lineLimit(2)
                                .minimumScaleFactor(0.68)

                            Text("\(festival.cityState) / \(attendedText)")
                                .font(WristlistTheme.metadataFont)
                                .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                                .lineLimit(2)
                        }

                        Spacer(minLength: 8)

                        ScoreBadge(score: festival.communityRating, palette: festival.palette, label: "Community rating")
                    }

                    Text(festival.summary)
                        .font(.subheadline)
                        .lineSpacing(2)
                        .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                        .lineLimit(3)

                    HStack(spacing: 12) {
                        FestivalStatusBadge(status: festival.status, palette: festival.palette)

                        if let moveUp, let moveDown {
                            Spacer(minLength: 4)
                            rankButton(systemImage: "chevron.up", isEnabled: canMoveUp, action: moveUp)
                            rankButton(systemImage: "chevron.down", isEnabled: canMoveDown, action: moveDown)
                        }
                    }
                }
            }
            .padding(.vertical, 16)

            EditorialDivider()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rank \(festival.personalRank), \(festival.name), rating \(festival.communityRating, specifier: "%.1f") out of 10, \(festival.cityState)")
    }

    private func rankButton(systemImage: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.caption.weight(.black))
                .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                .frame(width: 32, height: 32)
                .background(WristlistTheme.fieldFill(for: colorScheme), in: Circle())
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(stat.city)
                    .font(.headline.weight(.black))
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                Spacer()
                Text("\(stat.count)")
                    .font(.system(size: 20, weight: .black, design: .serif))
                    .monospacedDigit()
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(WristlistTheme.divider(for: colorScheme))

                    Rectangle()
                        .fill(WristlistTheme.accent(for: stat.palette))
                        .frame(width: max(10, proxy.size.width * CGFloat(stat.count) / CGFloat(max(maxCount, 1))))
                }
            }
            .frame(height: 5)

            Text("Top: \(stat.topFestivalName)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                .lineLimit(1)
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(stat.city), \(stat.count) festivals, top festival \(stat.topFestivalName)")
    }
}

struct WristbandMemoryCard: View {
    let memory: WristbandMemory

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(memory.year)
                    .font(.system(size: 22, weight: .black, design: .serif))
                    .monospacedDigit()
                    .foregroundStyle(WristlistTheme.accent(for: memory.palette))

                Spacer(minLength: 10)

                Rectangle()
                    .fill(WristlistTheme.accent(for: memory.palette))
                    .frame(width: 34, height: 3)
            }

            Text(memory.festivalName.uppercased())
                .font(.system(size: 18, weight: .black, design: .serif))
                .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                .lineLimit(2)
                .minimumScaleFactor(0.76)

            Text(memory.moment)
                .font(.caption)
                .lineSpacing(2)
                .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                .lineLimit(3)
        }
        .padding(14)
        .frame(width: 192, height: 142, alignment: .topLeading)
        .background(WristlistTheme.fieldFill(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: WristlistTheme.cornerSmall, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: WristlistTheme.cornerSmall, style: .continuous)
                .strokeBorder(WristlistTheme.divider(for: colorScheme), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(memory.year), \(memory.festivalName), \(memory.moment)")
    }
}

struct FriendMatchCard: View {
    let match: FriendFestivalMatch

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            AvatarCircle(initials: match.initials, palette: match.palette, size: 42, fontSize: 13)

            VStack(alignment: .leading, spacing: 3) {
                Text(match.name)
                    .font(.headline.weight(.black))
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                Text(match.sharedFavorites)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 0) {
                Text("\(match.matchPercent)")
                    .font(.system(size: 28, weight: .black, design: .serif))
                    .monospacedDigit()
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                Text("% MATCH")
                    .font(WristlistTheme.kickerFont)
                    .tracking(0.7)
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
            }
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            EditorialDivider()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(match.name), \(match.matchPercent) percent festival match, shared favorites \(match.sharedFavorites)")
    }
}
