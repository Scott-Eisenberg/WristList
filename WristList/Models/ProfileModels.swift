//
//  ProfileModels.swift
//  WristList
//

import Foundation

struct ProfileMetrics: Hashable {
    let festivalsRanked: Int
    let citiesVisited: Int
    let averageRating: Double
    let savedFestivals: Int
    let wantToAttend: Int

    static let empty = ProfileMetrics(
        festivalsRanked: 0,
        citiesVisited: 0,
        averageRating: 0,
        savedFestivals: 0,
        wantToAttend: 0
    )
}

struct TasteSignal: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let systemImage: String
    let palette: FestivalPalette
}

struct CityFestivalStat: Identifiable, Hashable {
    let id: String
    let city: String
    let count: Int
    let topFestivalName: String
    let palette: FestivalPalette
}

struct FriendFestivalMatch: Identifiable, Hashable {
    let id: String
    let name: String
    let initials: String
    let matchPercent: Int
    let sharedFavorites: String
    let palette: FestivalPalette
}

struct UserSearchResult: Identifiable, Hashable {
    let id: String
    let displayName: String
    let username: String
    let initials: String
    let palette: FestivalPalette
    let bio: String
    let locationText: String
    let festivalText: String
    let reviewCount: Int
    let matchPercent: Int?
    let isCurrentUser: Bool

    var subtitle: String {
        guard !locationText.isEmpty else {
            return username
        }

        guard !username.isEmpty else {
            return locationText
        }

        return "\(username) / \(locationText)"
    }

    var detailText: String {
        festivalText.isEmpty ? bio : festivalText
    }

    var accessoryText: String {
        if let matchPercent {
            return "\(matchPercent)%"
        }

        return reviewCount == 1 ? "1 review" : "\(reviewCount) reviews"
    }
}

enum UserSearchService {
    static func results(
        profiles: [WLProfile],
        reviews: [WLReview],
        festivals: [WLFestival],
        friendMatches: [FriendFestivalMatch],
        query: String
    ) -> [UserSearchResult] {
        let normalizedQuery = FestivalSearchService.normalizedSearchText(query)
        guard !normalizedQuery.isEmpty else { return [] }

        let festivalsByID = Dictionary(uniqueKeysWithValues: festivals.map { ($0.id, $0) })
        let reviewsByUserID = Dictionary(grouping: reviews, by: \.userID)
        var resultsByID: [String: UserSearchResult] = [:]

        for profile in profiles {
            let candidateReviews = reviewsByUserID[profile.id] ?? reviews.filter { $0.userName == profile.displayName }
            let profileReviews = visibleReviews(from: candidateReviews, userID: profile.id)
            resultsByID[profile.id] = UserSearchResult(
                id: profile.id,
                displayName: profile.displayName,
                username: profile.username,
                initials: profile.avatarInitials,
                palette: profile.palette,
                bio: profile.bio,
                locationText: profile.homeCity,
                festivalText: festivalText(from: profileReviews, festivalsByID: festivalsByID),
                reviewCount: profileReviews.count,
                matchPercent: nil,
                isCurrentUser: profile.id == WristlistDataController.currentUserID
            )
        }

        for (userID, userReviews) in reviewsByUserID {
            let visibleUserReviews = visibleReviews(from: userReviews, userID: userID)
            guard let firstReview = visibleUserReviews.sorted(by: { $0.createdAt > $1.createdAt }).first else { continue }
            let existingResult = resultsByID[userID]
            resultsByID[userID] = UserSearchResult(
                id: userID,
                displayName: existingResult?.displayName ?? firstReview.userName,
                username: existingResult?.username ?? firstReview.userHandle,
                initials: existingResult?.initials ?? firstReview.userInitials,
                palette: existingResult?.palette ?? firstReview.userPalette,
                bio: existingResult?.bio ?? "Festival notes, rankings, and saved weekends from \(firstReview.userName).",
                locationText: existingResult?.locationText ?? "",
                festivalText: festivalText(from: visibleUserReviews, festivalsByID: festivalsByID),
                reviewCount: visibleUserReviews.count,
                matchPercent: existingResult?.matchPercent,
                isCurrentUser: firstReview.isCurrentUser || userID == WristlistDataController.currentUserID
            )
        }

        for match in friendMatches {
            let existingResult = resultsByID[match.id]
            let existingFestivalText = existingResult?.festivalText ?? ""
            resultsByID[match.id] = UserSearchResult(
                id: match.id,
                displayName: existingResult?.displayName ?? match.name,
                username: existingResult?.username ?? "Friend match",
                initials: existingResult?.initials ?? match.initials,
                palette: existingResult?.palette ?? match.palette,
                bio: existingResult?.bio ?? "Festival match based on similar rankings and saved weekends.",
                locationText: existingResult?.locationText ?? "",
                festivalText: existingFestivalText.isEmpty ? match.sharedFavorites : existingFestivalText,
                reviewCount: existingResult?.reviewCount ?? 0,
                matchPercent: match.matchPercent,
                isCurrentUser: existingResult?.isCurrentUser ?? false
            )
        }

        return resultsByID.values
            .filter { matches($0, normalizedQuery: normalizedQuery) }
            .sorted { first, second in
                let firstScore = score(for: first, normalizedQuery: normalizedQuery)
                let secondScore = score(for: second, normalizedQuery: normalizedQuery)

                if firstScore == secondScore {
                    return first.displayName.localizedStandardCompare(second.displayName) == .orderedAscending
                }

                return firstScore > secondScore
            }
    }

    private static func visibleReviews(from reviews: [WLReview], userID: String) -> [WLReview] {
        if userID == WristlistDataController.currentUserID {
            return reviews
        }

        return reviews.filter(\.isVisibleToFriends)
    }

    private static func festivalText(from reviews: [WLReview], festivalsByID: [String: WLFestival]) -> String {
        var seenFestivalIDs = Set<String>()
        let festivalNames = reviews
            .sorted { $0.createdAt > $1.createdAt }
            .compactMap { review -> String? in
                guard seenFestivalIDs.insert(review.festivalID).inserted else {
                    return nil
                }
                return festivalsByID[review.festivalID]?.name
            }

        return festivalNames.prefix(3).joined(separator: " + ")
    }

    private static func matches(_ result: UserSearchResult, normalizedQuery: String) -> Bool {
        let searchableText = [
            result.displayName,
            result.username,
            result.bio,
            result.locationText,
            result.festivalText
        ]
        .map(FestivalSearchService.normalizedSearchText)
        .joined(separator: " ")

        if searchableText.contains(normalizedQuery) {
            return true
        }

        let queryTokens = normalizedQuery.split(separator: " ").map(String.init)
        return queryTokens.allSatisfy { searchableText.contains($0) }
    }

    private static func score(for result: UserSearchResult, normalizedQuery: String) -> Int {
        let normalizedName = FestivalSearchService.normalizedSearchText(result.displayName)
        let normalizedUsername = FestivalSearchService.normalizedSearchText(result.username)
        var score = 0

        if normalizedName == normalizedQuery || normalizedUsername == normalizedQuery {
            score += 100
        }

        if normalizedName.hasPrefix(normalizedQuery) || normalizedUsername.hasPrefix(normalizedQuery) {
            score += 50
        }

        score += min(result.reviewCount, 5) * 2
        score += (result.matchPercent ?? 0) / 10

        return score
    }
}
