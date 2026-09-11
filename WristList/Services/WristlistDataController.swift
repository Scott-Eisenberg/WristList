//
//  WristlistDataController.swift
//  WristList
//

import Foundation
import SwiftData

@MainActor
enum WristlistDataController {
    static let currentUserID = "current-user"
    private static let seedMarkerKey = "sample-data-seeded"

    static var schemaModels: [any PersistentModel.Type] {
        [
            Item.self,
            WLFestival.self,
            WLReview.self,
            WLProfile.self,
            WLComment.self,
            WLAppMetadata.self
        ]
    }

    static func seedIfNeeded(in context: ModelContext) throws {
        let markers = try context.fetch(FetchDescriptor<WLAppMetadata>())
        if markers.contains(where: { $0.key == seedMarkerKey && $0.value == "true" }) {
            return
        }

        let existingFestivals = try context.fetch(FetchDescriptor<WLFestival>())
        if !existingFestivals.isEmpty {
            context.insert(WLAppMetadata(key: seedMarkerKey, value: "true"))
            try saveIfNeeded(context)
            return
        }

        try seedSampleData(in: context)
    }

    static func resetSampleData(in context: ModelContext) throws {
        try deleteAll(WLComment.self, in: context)
        try deleteAll(WLReview.self, in: context)
        try deleteAll(WLFestival.self, in: context)
        try deleteAll(WLProfile.self, in: context)
        try deleteAll(WLAppMetadata.self, in: context)
        try seedSampleData(in: context)
    }

    static func currentProfile(from profiles: [WLProfile], context: ModelContext) throws -> WLProfile {
        if let profile = profiles.first(where: { $0.id == currentUserID }) {
            return profile
        }

        let profile = SampleProfileData.profile()
        context.insert(profile)
        try saveIfNeeded(context)
        return profile
    }

    @discardableResult
    static func importDiscoveredFestival(_ result: ExternalFestivalSearchResult, context: ModelContext) throws -> WLFestival {
        let trimmedTitle = result.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !FestivalSearchService.normalizedSearchText(trimmedTitle).isEmpty else {
            throw FestivalImportError.missingTitle
        }

        let festivals = try context.fetch(FetchDescriptor<WLFestival>())
        let normalizedTitle = FestivalSearchService.normalizedSearchText(trimmedTitle)

        if let existingFestival = festivals.first(where: { festival in
            festival.id == result.id || FestivalSearchService.normalizedSearchText(festival.name) == normalizedTitle
        }) {
            if !existingFestival.isSaved || existingFestival.status == .none {
                existingFestival.isSaved = true
                if existingFestival.status == .none {
                    existingFestival.status = .saved
                }
                existingFestival.updatedAt = .now
                try saveIfNeeded(context)
            }
            return existingFestival
        }

        let placeholderDate = Calendar.current.startOfDay(for: .now)
        let festival = WLFestival(
            id: uniqueDiscoveredFestivalID(for: result, existingFestivals: festivals),
            name: trimmedTitle,
            city: "Location",
            state: "TBD",
            country: "Unknown",
            venue: "Details from \(result.sourceName)",
            startDate: placeholderDate,
            endDate: placeholderDate,
            genres: inferredGenres(from: result),
            lineup: [],
            summary: result.summary,
            detailDescription: discoveredDetailDescription(for: result),
            palette: palette(for: trimmedTitle),
            communityRating: 0,
            communityReviewCount: 0,
            lineupScore: 0,
            productionScore: 0,
            venueScore: 0,
            organizationScore: 0,
            valueScore: 0,
            friendNames: [],
            isTrending: false,
            isRecommended: false,
            isNearUser: false,
            isSaved: true,
            status: .saved
        )

        context.insert(festival)
        try saveIfNeeded(context)
        return festival
    }

    static func toggleSave(_ festival: WLFestival, context: ModelContext) throws {
        festival.isSaved.toggle()
        if festival.isSaved && festival.status == .none {
            festival.status = .saved
        } else if !festival.isSaved && festival.status == .saved {
            festival.status = .none
        }
        festival.updatedAt = .now
        try saveIfNeeded(context)
    }

    static func updateAttendance(_ festival: WLFestival, status: AttendanceStatus, context: ModelContext) throws {
        festival.status = status
        festival.isSaved = status != .none
        festival.attendedDate = status == .attended ? (festival.attendedDate ?? festival.endDate) : nil

        if status == .attended && festival.personalRank == 0 {
            festival.personalRank = nextRank(in: context)
        }

        if status != .attended {
            festival.personalRank = 0
            let festivals = try context.fetch(FetchDescriptor<WLFestival>())
            RankingService.normalizeRanks(for: festivals)
        }

        festival.updatedAt = .now
        try saveIfNeeded(context)
    }

    @discardableResult
    static func saveReview(
        draft: ReviewDraft,
        festival: WLFestival,
        profile: WLProfile,
        existingReview: WLReview?,
        context: ModelContext
    ) throws -> WLReview? {
        try RatingValidator.validate(draft)

        festival.status = draft.status
        festival.isSaved = true
        festival.updatedAt = .now

        if draft.status == .wantToGo {
            festival.attendedDate = nil
            festival.personalRank = 0
            if let existingReview {
                context.delete(existingReview)
                let festivals = try context.fetch(FetchDescriptor<WLFestival>())
                RankingService.normalizeRanks(for: festivals)
            }
            try saveIfNeeded(context)
            return nil
        }

        festival.attendedDate = draft.attendedDate
        if festival.personalRank == 0 {
            festival.personalRank = nextRank(in: context)
        }

        let review = existingReview ?? WLReview(
            id: UUID().uuidString,
            festivalID: festival.id,
            userID: profile.id,
            userName: profile.displayName,
            userHandle: profile.username,
            userInitials: profile.avatarInitials,
            userPalette: profile.palette,
            attendedDate: draft.attendedDate ?? festival.endDate,
            overallScore: draft.overallScore,
            lineupScore: draft.lineupScore,
            productionScore: draft.productionScore,
            venueScore: draft.venueScore,
            organizationScore: draft.organizationScore,
            valueScore: draft.valueScore,
            reviewText: draft.reviewText,
            favoritePerformances: draft.favoritePerformances,
            isVisibleToFriends: draft.isVisibleToFriends,
            likeCount: 0,
            commentCount: 0,
            isCurrentUser: true
        )

        review.festivalID = festival.id
        review.userID = profile.id
        review.userName = profile.displayName
        review.userHandle = profile.username
        review.userInitials = profile.avatarInitials
        review.userPalette = profile.palette
        review.attendedDate = draft.attendedDate ?? festival.endDate
        review.overallScore = draft.overallScore
        review.lineupScore = draft.lineupScore
        review.productionScore = draft.productionScore
        review.venueScore = draft.venueScore
        review.organizationScore = draft.organizationScore
        review.valueScore = draft.valueScore
        review.reviewText = draft.reviewText
        review.favoritePerformances = draft.favoritePerformances
        review.isVisibleToFriends = draft.isVisibleToFriends
        review.isCurrentUser = true
        review.updatedAt = .now

        if existingReview == nil {
            context.insert(review)
        }

        try saveIfNeeded(context)
        return review
    }

    static func deleteReview(_ review: WLReview, festivals: [WLFestival], context: ModelContext) throws {
        if let festival = festivals.first(where: { $0.id == review.festivalID }) {
            festival.status = .none
            festival.isSaved = false
            festival.attendedDate = nil
            festival.personalRank = 0
            festival.updatedAt = .now
        }

        context.delete(review)
        RankingService.normalizeRanks(for: festivals)
        try saveIfNeeded(context)
    }

    static func toggleLike(_ review: WLReview, context: ModelContext) throws {
        review.isLiked.toggle()
        review.likeCount += review.isLiked ? 1 : -1
        review.likeCount = max(0, review.likeCount)
        review.updatedAt = .now
        try saveIfNeeded(context)
    }

    static func addComment(text: String, to review: WLReview, profile: WLProfile, context: ModelContext) throws {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let comment = WLComment(
            id: UUID().uuidString,
            reviewID: review.id,
            userName: profile.displayName,
            userInitials: profile.avatarInitials,
            text: trimmedText
        )
        context.insert(comment)
        review.commentCount += 1
        review.updatedAt = .now
        try saveIfNeeded(context)
    }

    static func saveIfNeeded(_ context: ModelContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }

    private static func uniqueDiscoveredFestivalID(for result: ExternalFestivalSearchResult, existingFestivals: [WLFestival]) -> String {
        let sourceSlug = slug(from: result.sourceName)
        let titleSlug = slug(from: result.title)
        let fallbackSlug = slug(from: result.id)
        let existingIDs = Set(existingFestivals.map(\.id))
        let baseID = [
            "discovered",
            sourceSlug.isEmpty ? "source" : sourceSlug,
            titleSlug.isEmpty ? fallbackSlug : titleSlug
        ]
        .filter { !$0.isEmpty }
        .joined(separator: "-")

        guard existingIDs.contains(baseID) else {
            return baseID
        }

        var suffix = 2
        while existingIDs.contains("\(baseID)-\(suffix)") {
            suffix += 1
        }
        return "\(baseID)-\(suffix)"
    }

    private static func slug(from value: String) -> String {
        FestivalSearchService.normalizedSearchText(value)
            .split(separator: " ")
            .joined(separator: "-")
    }

    private static func inferredGenres(from result: ExternalFestivalSearchResult) -> [String] {
        let searchableText = FestivalSearchService.normalizedSearchText(
            [result.title, result.description, result.summary]
                .compactMap { $0 }
                .joined(separator: " ")
        )
        let tokens = Set(searchableText.split(separator: " ").map(String.init))
        var genres: [String] = []

        func append(_ genre: String, when matches: Bool) {
            guard matches, !genres.contains(genre) else { return }
            genres.append(genre)
        }

        append("Electronic", when: tokens.contains("edm") || tokens.contains("electronic") || searchableText.contains("dance music"))
        append("House", when: tokens.contains("house"))
        append("Techno", when: tokens.contains("techno"))
        append("Bass", when: tokens.contains("bass") || tokens.contains("dubstep"))
        append("Trance", when: tokens.contains("trance"))
        append("Rock", when: tokens.contains("rock"))
        append("Indie", when: tokens.contains("indie"))
        append("Hip-Hop", when: searchableText.contains("hip hop") || searchableText.contains("hip-hop"))
        append("Pop", when: tokens.contains("pop"))
        append("Country", when: tokens.contains("country"))
        append("Folk", when: tokens.contains("folk"))

        return genres.isEmpty ? ["Festival"] : genres
    }

    private static func discoveredDetailDescription(for result: ExternalFestivalSearchResult) -> String {
        let summary = result.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let sourceNote = "Added from \(result.sourceName). Dates, location, venue, lineup, and organizer details are placeholders until a richer event source is connected."

        return [summary, sourceNote]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }

    private static func palette(for title: String) -> FestivalPalette {
        let palettes = FestivalPalette.allCases
        guard !palettes.isEmpty else {
            return .sunset
        }

        let value = FestivalSearchService.normalizedSearchText(title)
            .unicodeScalars
            .reduce(0) { $0 + Int($1.value) }

        return palettes[value % palettes.count]
    }

    private static func seedSampleData(in context: ModelContext) throws {
        for festival in SampleFeedData.festivals() {
            context.insert(festival)
        }

        context.insert(SampleProfileData.profile())

        for review in SampleFeedData.reviews() {
            context.insert(review)
        }

        for comment in SampleFeedData.comments() {
            context.insert(comment)
        }

        context.insert(WLAppMetadata(key: seedMarkerKey, value: "true"))
        try saveIfNeeded(context)
    }

    private static func deleteAll<T: PersistentModel>(_ modelType: T.Type, in context: ModelContext) throws {
        let models = try context.fetch(FetchDescriptor<T>())
        for model in models {
            context.delete(model)
        }
    }

    private static func nextRank(in context: ModelContext) -> Int {
        let festivals = (try? context.fetch(FetchDescriptor<WLFestival>())) ?? []
        let existingRanks = festivals.map(\.personalRank).filter { $0 > 0 }
        return (existingRanks.max() ?? 0) + 1
    }
}

private enum FestivalImportError: LocalizedError {
    case missingTitle

    var errorDescription: String? {
        switch self {
        case .missingTitle:
            "The discovered festival is missing a title."
        }
    }
}
