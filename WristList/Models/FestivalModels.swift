//
//  FestivalModels.swift
//  WristList
//

import Foundation
import SwiftData

enum FestivalPalette: String, CaseIterable, Identifiable, Codable, Hashable {
    case sunset
    case violet
    case electric
    case lagoon
    case ember

    var id: String { rawValue }
}

enum AttendanceStatus: String, CaseIterable, Identifiable, Codable, Hashable {
    case none
    case saved
    case wantToGo
    case attended

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none:
            "Not listed"
        case .saved:
            "Saved"
        case .wantToGo:
            "Want to Go"
        case .attended:
            "Attended"
        }
    }

    var systemImage: String {
        switch self {
        case .none:
            "plus"
        case .saved:
            "bookmark.fill"
        case .wantToGo:
            "sparkles"
        case .attended:
            "checkmark.seal.fill"
        }
    }
}

enum FestivalTiming: String, CaseIterable, Identifiable, Codable, Hashable {
    case upcoming
    case past

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct ReviewCategoryScore: Identifiable, Hashable {
    let id: String
    let name: String
    let score: Double
}

@Model
final class WLFestival {
    @Attribute(.unique) var id: String
    var name: String
    var city: String
    var state: String
    var country: String
    var venue: String
    var startDate: Date
    var endDate: Date
    var genresRaw: String
    var lineupRaw: String
    var summary: String
    var detailDescription: String
    var paletteRaw: String
    var communityRating: Double
    var communityReviewCount: Int
    var lineupScore: Double
    var productionScore: Double
    var venueScore: Double
    var organizationScore: Double
    var valueScore: Double
    var friendNamesRaw: String
    var isTrending: Bool
    var isRecommended: Bool
    var isNearUser: Bool
    var isSaved: Bool
    var statusRaw: String
    var personalRank: Int
    var attendedDate: Date?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String,
        name: String,
        city: String,
        state: String,
        country: String = "United States",
        venue: String,
        startDate: Date,
        endDate: Date,
        genres: [String],
        lineup: [String],
        summary: String,
        detailDescription: String,
        palette: FestivalPalette,
        communityRating: Double,
        communityReviewCount: Int,
        lineupScore: Double,
        productionScore: Double,
        venueScore: Double,
        organizationScore: Double,
        valueScore: Double,
        friendNames: [String],
        isTrending: Bool,
        isRecommended: Bool,
        isNearUser: Bool,
        isSaved: Bool = false,
        status: AttendanceStatus = .none,
        personalRank: Int = 0,
        attendedDate: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.city = city
        self.state = state
        self.country = country
        self.venue = venue
        self.startDate = startDate
        self.endDate = endDate
        self.genresRaw = genres.joined(separator: "|")
        self.lineupRaw = lineup.joined(separator: "|")
        self.summary = summary
        self.detailDescription = detailDescription
        self.paletteRaw = palette.rawValue
        self.communityRating = communityRating
        self.communityReviewCount = communityReviewCount
        self.lineupScore = lineupScore
        self.productionScore = productionScore
        self.venueScore = venueScore
        self.organizationScore = organizationScore
        self.valueScore = valueScore
        self.friendNamesRaw = friendNames.joined(separator: "|")
        self.isTrending = isTrending
        self.isRecommended = isRecommended
        self.isNearUser = isNearUser
        self.isSaved = isSaved
        self.statusRaw = status.rawValue
        self.personalRank = personalRank
        self.attendedDate = attendedDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var genres: [String] {
        get { Self.decodeList(genresRaw) }
        set { genresRaw = newValue.joined(separator: "|") }
    }

    var lineup: [String] {
        get { Self.decodeList(lineupRaw) }
        set { lineupRaw = newValue.joined(separator: "|") }
    }

    var friendNames: [String] {
        get { Self.decodeList(friendNamesRaw) }
        set { friendNamesRaw = newValue.joined(separator: "|") }
    }

    var palette: FestivalPalette {
        get { FestivalPalette(rawValue: paletteRaw) ?? .sunset }
        set { paletteRaw = newValue.rawValue }
    }

    var status: AttendanceStatus {
        get { AttendanceStatus(rawValue: statusRaw) ?? .none }
        set { statusRaw = newValue.rawValue }
    }

    var timing: FestivalTiming {
        endDate < Calendar.current.startOfDay(for: .now) ? .past : .upcoming
    }

    var cityState: String {
        "\(city), \(state)"
    }

    var dateRangeText: String {
        DateFormatting.festivalRange(startDate: startDate, endDate: endDate)
    }

    var categoryScores: [ReviewCategoryScore] {
        [
            ReviewCategoryScore(id: "\(id)-lineup", name: "Lineup", score: lineupScore),
            ReviewCategoryScore(id: "\(id)-production", name: "Production", score: productionScore),
            ReviewCategoryScore(id: "\(id)-venue", name: "Venue", score: venueScore),
            ReviewCategoryScore(id: "\(id)-organization", name: "Organization", score: organizationScore),
            ReviewCategoryScore(id: "\(id)-value", name: "Value", score: valueScore)
        ]
    }

    private static func decodeList(_ rawValue: String) -> [String] {
        rawValue
            .split(separator: "|")
            .map(String.init)
            .filter { !$0.isEmpty }
    }
}

@Model
final class WLReview {
    @Attribute(.unique) var id: String
    var festivalID: String
    var userID: String
    var userName: String
    var userHandle: String
    var userInitials: String
    var userPaletteRaw: String
    var attendedDate: Date
    var overallScore: Double
    var lineupScore: Double
    var productionScore: Double
    var venueScore: Double
    var organizationScore: Double
    var valueScore: Double
    var reviewText: String
    var favoritePerformancesRaw: String
    var isVisibleToFriends: Bool
    var likeCount: Int
    var commentCount: Int
    var isLiked: Bool
    var isCurrentUser: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String,
        festivalID: String,
        userID: String,
        userName: String,
        userHandle: String,
        userInitials: String,
        userPalette: FestivalPalette,
        attendedDate: Date,
        overallScore: Double,
        lineupScore: Double,
        productionScore: Double,
        venueScore: Double,
        organizationScore: Double,
        valueScore: Double,
        reviewText: String,
        favoritePerformances: [String],
        isVisibleToFriends: Bool,
        likeCount: Int,
        commentCount: Int,
        isLiked: Bool = false,
        isCurrentUser: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.festivalID = festivalID
        self.userID = userID
        self.userName = userName
        self.userHandle = userHandle
        self.userInitials = userInitials
        self.userPaletteRaw = userPalette.rawValue
        self.attendedDate = attendedDate
        self.overallScore = overallScore
        self.lineupScore = lineupScore
        self.productionScore = productionScore
        self.venueScore = venueScore
        self.organizationScore = organizationScore
        self.valueScore = valueScore
        self.reviewText = reviewText
        self.favoritePerformancesRaw = favoritePerformances.joined(separator: "|")
        self.isVisibleToFriends = isVisibleToFriends
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.isLiked = isLiked
        self.isCurrentUser = isCurrentUser
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var userPalette: FestivalPalette {
        get { FestivalPalette(rawValue: userPaletteRaw) ?? .violet }
        set { userPaletteRaw = newValue.rawValue }
    }

    var favoritePerformances: [String] {
        get {
            favoritePerformancesRaw
                .split(separator: "|")
                .map(String.init)
                .filter { !$0.isEmpty }
        }
        set { favoritePerformancesRaw = newValue.joined(separator: "|") }
    }

    var categoryScores: [ReviewCategoryScore] {
        [
            ReviewCategoryScore(id: "\(id)-lineup", name: "Lineup", score: lineupScore),
            ReviewCategoryScore(id: "\(id)-production", name: "Production", score: productionScore),
            ReviewCategoryScore(id: "\(id)-venue", name: "Venue", score: venueScore),
            ReviewCategoryScore(id: "\(id)-organization", name: "Organization", score: organizationScore),
            ReviewCategoryScore(id: "\(id)-value", name: "Value", score: valueScore)
        ]
    }
}

@Model
final class WLProfile {
    @Attribute(.unique) var id: String
    var displayName: String
    var username: String
    var bio: String
    var homeCity: String
    var avatarInitials: String
    var paletteRaw: String
    var followers: Int
    var following: Int
    var currentStreak: Int
    var privacyRaw: String
    var notificationsEnabled: Bool
    var reviewLikesEnabled: Bool
    var updatedAt: Date

    init(
        id: String,
        displayName: String,
        username: String,
        bio: String,
        homeCity: String,
        avatarInitials: String,
        palette: FestivalPalette,
        followers: Int,
        following: Int,
        currentStreak: Int,
        privacy: ProfilePrivacy = .friends,
        notificationsEnabled: Bool = true,
        reviewLikesEnabled: Bool = true,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.displayName = displayName
        self.username = username
        self.bio = bio
        self.homeCity = homeCity
        self.avatarInitials = avatarInitials
        self.paletteRaw = palette.rawValue
        self.followers = followers
        self.following = following
        self.currentStreak = currentStreak
        self.privacyRaw = privacy.rawValue
        self.notificationsEnabled = notificationsEnabled
        self.reviewLikesEnabled = reviewLikesEnabled
        self.updatedAt = updatedAt
    }

    var palette: FestivalPalette {
        get { FestivalPalette(rawValue: paletteRaw) ?? .sunset }
        set { paletteRaw = newValue.rawValue }
    }

    var privacy: ProfilePrivacy {
        get { ProfilePrivacy(rawValue: privacyRaw) ?? .friends }
        set { privacyRaw = newValue.rawValue }
    }
}

enum ProfilePrivacy: String, CaseIterable, Identifiable, Codable, Hashable {
    case friends
    case privateProfile
    case publicProfile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .friends:
            "Friends"
        case .privateProfile:
            "Private"
        case .publicProfile:
            "Public"
        }
    }
}

@Model
final class WLComment {
    @Attribute(.unique) var id: String
    var reviewID: String
    var userName: String
    var userInitials: String
    var text: String
    var createdAt: Date

    init(id: String, reviewID: String, userName: String, userInitials: String, text: String, createdAt: Date = .now) {
        self.id = id
        self.reviewID = reviewID
        self.userName = userName
        self.userInitials = userInitials
        self.text = text
        self.createdAt = createdAt
    }
}

@Model
final class WLAppMetadata {
    @Attribute(.unique) var key: String
    var value: String

    init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}
