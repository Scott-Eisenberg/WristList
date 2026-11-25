import SwiftUI

extension View {
    @ViewBuilder
    func journalWindowSize() -> some View {
        #if os(macOS)
        self.frame(minWidth: 360, idealWidth: 1120, minHeight: 640, idealHeight: 840)
        #else
        self
        #endif
    }

    @ViewBuilder
    func journalNavigationStyle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    func journalReordering(_ editing: Bool) -> some View {
        #if os(iOS)
        self.environment(\.editMode, .constant(editing ? .active : .inactive))
        #else
        self
        #endif
    }
}

enum JournalStyle {
    static let paper = Color(red: 0.98, green: 0.97, blue: 0.95)
    static let ink = Color(red: 0.12, green: 0.12, blue: 0.14)
    static let muted = Color(red: 0.39, green: 0.38, blue: 0.41)
    static let coral = Color(red: 1, green: 0.36, blue: 0.28)
    static let violet = Color(red: 0.37, green: 0.19, blue: 0.83)
    static let line = Color.black.opacity(0.10)
}

struct JournalHeading: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.largeTitle.bold()).tracking(-1)
            Text(subtitle).font(.subheadline).foregroundStyle(JournalStyle.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct JournalScore: View {
    let score: Double
    var body: some View {
        Text(score, format: .number.precision(.fractionLength(1)))
            .font(.headline.monospacedDigit())
            .foregroundStyle(JournalStyle.violet)
            .padding(10)
            .background(JournalStyle.violet.opacity(0.08), in: Circle())
            .accessibilityLabel("Rating \(score.formatted(.number.precision(.fractionLength(1)))) out of 10")
    }
}

struct JournalArtwork: View {
    let festival: WLFestival
    var height: CGFloat = 200

    var body: some View {
        GeometryReader { geometry in
            if let photo = FestivalPhoto.catalog[festival.id] {
                Image(photo.asset)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottom)
                    .clipped()
                    .accessibilityLabel("Archive photograph of \(festival.name)")
            } else {
                Rectangle().fill(Color(red: 0.90, green: 0.90, blue: 0.87))
                    .overlay {
                        Text("Photo unavailable")
                            .font(.caption).foregroundStyle(JournalStyle.muted)
                    }
            }
        }
        .frame(height: height)
    }
}

struct JournalFriendLine: View {
    let festival: WLFestival
    var body: some View {
        Text(festival.friendNames.isEmpty ? "No friend activity yet" :
                "\(festival.friendNames.prefix(2).joined(separator: " & ")) \(festival.timing == .past ? "went" : "are going")")
            .font(.caption).foregroundStyle(JournalStyle.muted)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct JournalRecommendation: View {
    let festival: WLFestival
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !festival.friendNames.isEmpty, let reason = FestivalRecommendation.reason(for: festival) {
                Text("\(festival.friendNames.prefix(2).joined(separator: " & ")) recommend it for")
                    .font(.caption.weight(.semibold))
                Text(reason).font(.subheadline).foregroundStyle(JournalStyle.muted)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                JournalFriendLine(festival: festival)
            }
        }
    }
}

struct JournalFestivalRow: View {
    let festival: WLFestival
    var score: Double?
    var body: some View {
        HStack(spacing: 16) {
            JournalArtwork(festival: festival, height: 80)
                .frame(width: 72).clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(festival.name).font(.headline)
                Text(festival.cityState).font(.caption).foregroundStyle(JournalStyle.muted)
                Text(festival.dateRangeText).font(.caption).foregroundStyle(JournalStyle.muted)
                Text(festival.genres.prefix(2).joined(separator: " · "))
                    .font(.caption2).foregroundStyle(JournalStyle.muted)
                JournalFriendLine(festival: festival)
            }
            Spacer(minLength: 0)
            if let score {
                JournalScore(score: score)
            } else if festival.isSaved {
                Image(systemName: "bookmark.fill").foregroundStyle(JournalStyle.violet)
                    .accessibilityLabel("Saved")
            }
        }
        .padding(.vertical, 12)
        .foregroundStyle(JournalStyle.ink)
        .contentShape(Rectangle())
    }
}

struct JournalFeatureCard: View {
    let festival: WLFestival
    var score: Double?
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            JournalArtwork(festival: festival, height: compact ? 184 : 300)
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(festival.name).font(compact ? .title3.bold() : .title2.bold())
                            .fixedSize(horizontal: false, vertical: true)
                        Text(festival.cityState).font(.subheadline)
                        Text(festival.dateRangeText).font(.subheadline)
                    }
                    Spacer(minLength: 0)
                    if let score {
                        VStack(spacing: 4) {
                            JournalScore(score: score)
                            Text("Your score").font(.caption2).foregroundStyle(JournalStyle.muted)
                        }
                    } else if festival.isSaved {
                        Image(systemName: "bookmark.fill").foregroundStyle(JournalStyle.violet)
                            .accessibilityLabel("Saved")
                    }
                }
                Text(festival.genres.prefix(3).joined(separator: " · "))
                    .font(.caption).foregroundStyle(JournalStyle.muted)
                Divider()
                JournalRecommendation(festival: festival)
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(JournalStyle.line, lineWidth: 1))
        .foregroundStyle(JournalStyle.ink)
        .contentShape(Rectangle())
    }
}
