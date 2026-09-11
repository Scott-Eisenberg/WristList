//
//  ProfileView.swift
//  WristList
//

import SwiftData
import SwiftUI

struct ProfileView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Query private var festivals: [WLFestival]
    @Query private var reviews: [WLReview]
    @Query private var profiles: [WLProfile]

    @State private var selectedList: ProfileFestivalListFilter = .ranked
    @State private var isShowingEditProfile = false
    @State private var isShowingSettings = false
    @State private var userSearchText = ""

    private var profile: WLProfile? {
        profiles.first { $0.id == WristlistDataController.currentUserID } ?? profiles.first
    }

    private var isSearchingUsers: Bool {
        !FestivalSearchService.normalizedSearchText(userSearchText).isEmpty
    }

    private var userSearchResults: [UserSearchResult] {
        UserSearchService.results(
            profiles: profiles,
            reviews: reviews,
            festivals: festivals,
            friendMatches: SampleProfileData.friendMatches(),
            query: userSearchText
        )
    }

    private var currentUserReviews: [WLReview] {
        reviews
            .filter(\.isCurrentUser)
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var rankedFestivals: [WLFestival] {
        RankingService.rankedFestivals(from: festivals)
    }

    private var savedFestivals: [WLFestival] {
        festivals.filter(\.isSaved).sorted { $0.updatedAt > $1.updatedAt }
    }

    private var wantToAttendFestivals: [WLFestival] {
        festivals.filter { $0.status == .wantToGo }.sorted { $0.startDate < $1.startDate }
    }

    private var metrics: ProfileMetrics {
        let attended = festivals.filter { $0.status == .attended }
        let averageRating = currentUserReviews.map(\.overallScore).average
        return ProfileMetrics(
            festivalsRanked: attended.count,
            citiesVisited: Set(attended.map(\.cityState)).count,
            averageRating: averageRating,
            savedFestivals: savedFestivals.count,
            wantToAttend: wantToAttendFestivals.count
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    if isSearchingUsers {
                        UserSearchResultsSection(results: userSearchResults)
                    } else {
                        if let profile {
                            ProfileHeaderCard(profile: profile, metrics: metrics, onEdit: { isShowingEditProfile = true }, onSettings: { isShowingSettings = true })
                        } else {
                            EmptyStateView(title: "Profile loading", message: "Your local profile is being prepared.", systemImage: "person.crop.circle")
                        }

                        ProfileStatsGrid(metrics: metrics)

                        TasteProfileSection(signals: SampleProfileData.tasteSignals(festivals: festivals, reviews: reviews))

                        FestivalListSection(
                            selectedList: $selectedList,
                            rankedFestivals: rankedFestivals,
                            savedFestivals: savedFestivals,
                            wantToAttendFestivals: wantToAttendFestivals
                        )

                        RecentReviewsSection(reviews: currentUserReviews, festivals: festivals, profile: profile)

                        CityCoverageSection(cityStats: SampleProfileData.cityStats(from: festivals))

                        WristbandMemoriesSection(memories: SampleProfileData.wristbandMemories(from: festivals))

                        FriendMatchesSection(matches: SampleProfileData.friendMatches())
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .background(WristlistTheme.appBackground(for: colorScheme).ignoresSafeArea())
            .navigationTitle("Profile")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .searchable(text: $userSearchText, prompt: "Search users, handles, festivals")
        }
        .sheet(isPresented: $isShowingEditProfile) {
            if let profile {
                EditProfileView(profile: profile)
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
    }
}

private struct UserSearchResultsSection: View {
    let results: [UserSearchResult]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitleView(title: "People", subtitle: "\(results.count) matching users")

            if results.isEmpty {
                EmptyStateView(
                    title: "No users found",
                    message: "Try a name, handle, city, or festival from your local activity.",
                    systemImage: "person.crop.circle.badge.questionmark"
                )
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(results) { result in
                        NavigationLink {
                            UserProfileDetailView(searchResult: result)
                        } label: {
                            UserSearchResultRow(result: result)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct UserSearchResultRow: View {
    let result: UserSearchResult

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            AvatarCircle(initials: result.initials, palette: result.palette, size: 46, fontSize: 14)

            VStack(alignment: .leading, spacing: 4) {
                Text(result.displayName)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(result.subtitle)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                    .lineLimit(1)

                Text(result.detailText)
                    .font(.caption)
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Text(result.accessoryText)
                .font(.caption.weight(.black))
                .foregroundStyle(WristlistTheme.scoreGreen)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .padding(12)
        .background(WristlistTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(WristlistTheme.cardStroke(for: colorScheme), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(result.displayName), \(result.subtitle), \(result.detailText)")
    }
}

private enum ProfileFestivalListFilter: String, CaseIterable, Identifiable {
    case ranked = "Ranked"
    case saved = "Saved"
    case want = "Want"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .ranked:
            "Your personal festival ranking"
        case .saved:
            "Festivals saved for later"
        case .want:
            "Weekends on your radar"
        }
    }
}

private struct TasteProfileSection: View {
    let signals: [TasteSignal]

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitleView(title: "Taste Profile", subtitle: "What your ranking history says about your festival style")

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(signals) { signal in
                    TasteSignalCard(signal: signal)
                }
            }
        }
    }
}

private struct FestivalListSection: View {
    @Binding var selectedList: ProfileFestivalListFilter
    let rankedFestivals: [WLFestival]
    let savedFestivals: [WLFestival]
    let wantToAttendFestivals: [WLFestival]

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitleView(title: "Festival Lists", subtitle: selectedList.subtitle)

            Picker("Festival list", selection: $selectedList) {
                ForEach(ProfileFestivalListFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Choose festival list")

            VStack(spacing: 10) {
                switch selectedList {
                case .ranked:
                    if rankedFestivals.isEmpty {
                        EmptyStateView(title: "No ranked festivals", message: "Log an attended festival to start ranking your wristband history.", systemImage: "list.number")
                    } else {
                        ForEach(Array(rankedFestivals.prefix(5).enumerated()), id: \.element.id) { index, festival in
                            NavigationLink {
                                FestivalDetailView(festival: festival)
                            } label: {
                                RankedFestivalRowView(festival: festival, canMoveUp: index > 0, canMoveDown: index < min(rankedFestivals.count, 5) - 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                case .saved:
                    profileRows(festivals: savedFestivals, emptyTitle: "No saved festivals", emptyMessage: "Tap Save from Discover or Festival Details to build your planning queue.")
                case .want:
                    profileRows(festivals: wantToAttendFestivals, emptyTitle: "No want-to-go festivals", emptyMessage: "Mark upcoming festivals as Want to Go from the log flow.")
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.88), value: selectedList)
        }
    }

    @ViewBuilder
    private func profileRows(festivals: [WLFestival], emptyTitle: String, emptyMessage: String) -> some View {
        if festivals.isEmpty {
            EmptyStateView(title: emptyTitle, message: emptyMessage, systemImage: "bookmark")
        } else {
            ForEach(festivals.prefix(5)) { festival in
                NavigationLink {
                    FestivalDetailView(festival: festival)
                } label: {
                    FestivalCompactRow(festival: festival, trailingText: festival.status.title)
                        .padding(12)
                        .background(WristlistTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct RecentReviewsSection: View {
    let reviews: [WLReview]
    let festivals: [WLFestival]
    let profile: WLProfile?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitleView(title: "Recent Reviews", subtitle: "Your latest festival notes")

            if reviews.isEmpty {
                EmptyStateView(title: "No reviews yet", message: "Log an attended festival to publish your first review.", systemImage: "text.bubble")
            } else {
                ForEach(reviews.prefix(2)) { review in
                    if let festival = festivals.first(where: { $0.id == review.festivalID }) {
                        ReviewCardView(review: review, festival: festival, profile: profile)
                    }
                }
            }
        }
    }
}

private struct CityCoverageSection: View {
    let cityStats: [CityFestivalStat]

    private var maxCount: Int {
        cityStats.map(\.count).max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitleView(title: "City Coverage", subtitle: "Where your wristbands are stacking up")

            if cityStats.isEmpty {
                EmptyStateView(title: "No city stats", message: "Attended festivals will build your city coverage over time.", systemImage: "map")
            } else {
                VStack(spacing: 10) {
                    ForEach(cityStats) { stat in
                        CityCoverageCard(stat: stat, maxCount: maxCount)
                    }
                }
            }
        }
    }
}

private struct WristbandMemoriesSection: View {
    let memories: [WristbandMemory]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitleView(title: "Wristband Memories", subtitle: "Recent highlights from your festival history")

            if memories.isEmpty {
                EmptyStateView(title: "No memories yet", message: "Your top attended festivals will appear here after logging reviews.", systemImage: "ticket")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(memories) { memory in
                            WristbandMemoryCard(memory: memory)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 2)
                }
                .padding(.horizontal, -18)
            }
        }
    }
}

private struct FriendMatchesSection: View {
    let matches: [FriendFestivalMatch]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitleView(title: "Festival Matches", subtitle: "Friends with similar rankings and saved weekends")

            VStack(spacing: 10) {
                ForEach(matches) { match in
                    FriendMatchCard(match: match)
                }
            }
        }
    }
}

private extension Array where Element == Double {
    var average: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}

#Preview("Profile Dark") {
    ProfileView()
        .modelContainer(PreviewContainerFactory.makeContainer())
        .preferredColorScheme(.dark)
}

#Preview("Profile Light") {
    ProfileView()
        .modelContainer(PreviewContainerFactory.makeContainer())
        .preferredColorScheme(.light)
}
