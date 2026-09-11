//
//  UserProfileDetailView.swift
//  WristList
//

import SwiftData
import SwiftUI

struct UserProfileDetailView: View {
    let userID: String
    let displayName: String
    let username: String
    let initials: String
    let palette: FestivalPalette
    let bio: String
    let isCurrentUser: Bool

    @Environment(\.colorScheme) private var colorScheme
    @Query private var reviews: [WLReview]
    @Query private var festivals: [WLFestival]
    @Query private var profiles: [WLProfile]

    init(review: WLReview) {
        self.userID = review.userID
        self.displayName = review.userName
        self.username = review.userHandle
        self.initials = review.userInitials
        self.palette = review.userPalette
        self.bio = review.isCurrentUser ? "Your local festival history and reviews." : "Festival notes, rankings, and saved weekends from \(review.userName)."
        self.isCurrentUser = review.isCurrentUser
    }

    init(profile: WLProfile) {
        self.userID = profile.id
        self.displayName = profile.displayName
        self.username = profile.username
        self.initials = profile.avatarInitials
        self.palette = profile.palette
        self.bio = profile.bio
        self.isCurrentUser = true
    }

    init(searchResult: UserSearchResult) {
        self.userID = searchResult.id
        self.displayName = searchResult.displayName
        self.username = searchResult.username
        self.initials = searchResult.initials
        self.palette = searchResult.palette
        self.bio = searchResult.bio
        self.isCurrentUser = searchResult.isCurrentUser
    }

    private var profileReviews: [WLReview] {
        Self.reviewsForProfile(
            userID: userID,
            displayName: displayName,
            username: username,
            isCurrentUser: isCurrentUser,
            reviews: reviews
        )
    }

    private var currentProfile: WLProfile? {
        profiles.first { $0.id == WristlistDataController.currentUserID } ?? profiles.first
    }

    static func reviewsForProfile(
        userID: String,
        displayName: String,
        username: String,
        isCurrentUser: Bool,
        reviews: [WLReview]
    ) -> [WLReview] {
        let normalizedUsername = FestivalSearchService.normalizedSearchText(username)
        let normalizedDisplayName = FestivalSearchService.normalizedSearchText(displayName)

        return reviews
            .filter { review in
                guard isCurrentUser || review.isVisibleToFriends else {
                    return false
                }

                if !userID.isEmpty {
                    return review.userID == userID
                }

                return FestivalSearchService.normalizedSearchText(review.userHandle) == normalizedUsername ||
                    FestivalSearchService.normalizedSearchText(review.userName) == normalizedDisplayName
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    AvatarCircle(initials: initials, palette: palette, size: 82, fontSize: 28)
                        .accessibilityLabel("Profile picture for \(displayName)")

                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayName)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                            .lineLimit(2)
                        Text(username)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(WristlistTheme.brand)
                    }

                    Text(bio)
                        .font(.body)
                        .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 10) {
                        ProfileMetricCard(value: "\(profileReviews.count)", label: "Reviews", systemImage: "text.bubble", palette: palette)
                        ProfileMetricCard(value: "\(Set(profileReviews.map(\.festivalID)).count)", label: "Festivals", systemImage: "music.mic", palette: .sunset)
                    }
                }
                .padding(16)
                .background(WristlistTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(WristlistTheme.cardStroke(for: colorScheme), lineWidth: 1)
                }

                SectionTitleView(title: isCurrentUser ? "Your Recent Reviews" : "Recent Reviews")

                if profileReviews.isEmpty {
                    EmptyStateView(title: "No reviews yet", message: "Reviews from this profile will appear here.", systemImage: "text.bubble")
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(profileReviews) { review in
                            if let festival = festivals.first(where: { $0.id == review.festivalID }) {
                                ReviewCardView(review: review, festival: festival, profile: currentProfile)
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
        .background(WristlistTheme.appBackground(for: colorScheme).ignoresSafeArea())
        .navigationTitle(displayName)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}

#Preview("User Detail") {
    let container = PreviewContainerFactory.makeContainer()
    let context = container.mainContext
    let reviews = (try? context.fetch(FetchDescriptor<WLReview>())) ?? []

    NavigationStack {
        if let review = reviews.first {
            UserProfileDetailView(review: review)
        }
    }
    .modelContainer(container)
    .preferredColorScheme(.dark)
}
