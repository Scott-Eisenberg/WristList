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
            try saveIfNeeded(context)
            return existingReview
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
