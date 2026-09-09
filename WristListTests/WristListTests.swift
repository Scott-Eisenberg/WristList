//
//  WristListTests.swift
//  WristListTests
//
//  Created by Scott Eisenberg on 9/7/26.
//

import SwiftData
import Testing
@testable import WristList

@MainActor
struct WristListTests {
    @Test func ratingValidationRequiresFestivalAndValidScores() throws {
        var draft = ReviewDraft.blank
        draft.festivalID = nil
        draft.overallScore = 11

        let issues = RatingValidator.validationIssues(for: draft)

        #expect(issues.contains(.missingFestival))
        #expect(issues.contains(.invalidScore("Overall score")))
    }

    @Test func searchMatchesFestivalArtistCityVenueAndGenre() throws {
        let context = try seededContext()
        let festivals = try context.fetch(FetchDescriptor<WLFestival>())

        var filters = FestivalFilters()
        filters.searchText = "Helio Drift"
        #expect(FestivalSearchService.results(from: festivals, filters: filters).map(\.name) == ["Midnight Atlas"])

        filters.searchText = "Long Beach"
        #expect(FestivalSearchService.results(from: festivals, filters: filters).map(\.name) == ["Lunar Pier"])

        filters.searchText = "Electronic"
        #expect(FestivalSearchService.results(from: festivals, filters: filters).contains { $0.name == "Nova Bloom" })
    }

    @Test func filtersByStatusAndDate() throws {
        let context = try seededContext()
        let festivals = try context.fetch(FetchDescriptor<WLFestival>())

        var filters = FestivalFilters()
        filters.statusFilter = .wantToGo
        let wantToGoResults = FestivalSearchService.results(from: festivals, filters: filters)
        #expect(wantToGoResults.allSatisfy { $0.status == .wantToGo })

        filters.clear()
        filters.dateFilter = .past
        let pastResults = FestivalSearchService.results(from: festivals, filters: filters, now: DateFormatting.date(year: 2026, month: 9, day: 8))
        #expect(pastResults.contains { $0.name == "Midnight Atlas" })
        #expect(pastResults.allSatisfy { $0.endDate < DateFormatting.date(year: 2026, month: 9, day: 8) })
    }

    @Test func savingAndUnsavingFestivalPersistsState() throws {
        let context = try seededContext()
        let festivals = try context.fetch(FetchDescriptor<WLFestival>())
        let festival = try #require(festivals.first { $0.name == "Lunar Pier" })

        #expect(festival.isSaved == false)
        try WristlistDataController.toggleSave(festival, context: context)
        #expect(festival.isSaved == true)
        #expect(festival.status == .saved)

        try WristlistDataController.toggleSave(festival, context: context)
        #expect(festival.isSaved == false)
        #expect(festival.status == .none)
    }

    @Test func attendanceChangesAssignAndClearRanking() throws {
        let context = try seededContext()
        let festivals = try context.fetch(FetchDescriptor<WLFestival>())
        let festival = try #require(festivals.first { $0.name == "Lunar Pier" })

        try WristlistDataController.updateAttendance(festival, status: .attended, context: context)
        #expect(festival.status == .attended)
        #expect(festival.isSaved == true)
        #expect(festival.personalRank > 0)

        try WristlistDataController.updateAttendance(festival, status: .none, context: context)
        #expect(festival.status == .none)
        #expect(festival.isSaved == false)
        #expect(festival.personalRank == 0)
    }

    @Test func rankingMoveUpdatesPersistentOrder() throws {
        let context = try seededContext()
        let festivals = try context.fetch(FetchDescriptor<WLFestival>())
        let rankedBefore = RankingService.rankedFestivals(from: festivals)
        let second = try #require(rankedBefore.dropFirst().first)

        RankingService.moveFestival(second, direction: .up, in: festivals)
        try WristlistDataController.saveIfNeeded(context)

        let rankedAfter = RankingService.rankedFestivals(from: festivals)
        #expect(rankedAfter.first?.id == second.id)
        #expect(second.personalRank == 1)
    }

    @Test func sampleSeedingDoesNotDuplicateData() throws {
        let context = try emptyContext()

        try WristlistDataController.seedIfNeeded(in: context)
        let firstFestivalCount = try context.fetch(FetchDescriptor<WLFestival>()).count
        let firstReviewCount = try context.fetch(FetchDescriptor<WLReview>()).count

        try WristlistDataController.seedIfNeeded(in: context)
        let secondFestivalCount = try context.fetch(FetchDescriptor<WLFestival>()).count
        let secondReviewCount = try context.fetch(FetchDescriptor<WLReview>()).count

        #expect(firstFestivalCount == secondFestivalCount)
        #expect(firstReviewCount == secondReviewCount)
    }

    @Test func creatingEditingAndDeletingReviewUpdatesLocalStore() throws {
        let context = try seededContext()
        let festivals = try context.fetch(FetchDescriptor<WLFestival>())
        let profiles = try context.fetch(FetchDescriptor<WLProfile>())
        let festival = try #require(festivals.first { $0.name == "Harbor Glow" })
        let profile = try #require(profiles.first)

        var draft = ReviewDraft.blank
        draft.festivalID = festival.id
        draft.status = .attended
        draft.attendedDate = DateFormatting.date(year: 2027, month: 1, day: 16)
        draft.overallScore = 9.1
        draft.reviewText = "Great waterfront flow and a strong ambient room."
        draft.favoritePerformances = ["Rainline"]

        let createdReview = try #require(WristlistDataController.saveReview(draft: draft, festival: festival, profile: profile, existingReview: nil, context: context))
        #expect(createdReview.festivalID == festival.id)
        #expect(festival.status == .attended)

        draft.overallScore = 8.8
        draft.reviewText = "Updated note after comparing it with the rest of the year."
        let editedReview = try #require(WristlistDataController.saveReview(draft: draft, festival: festival, profile: profile, existingReview: createdReview, context: context))
        #expect(editedReview.overallScore == 8.8)
        #expect(editedReview.reviewText == "Updated note after comparing it with the rest of the year.")

        try WristlistDataController.deleteReview(editedReview, festivals: festivals, context: context)
        let remainingReviews = try context.fetch(FetchDescriptor<WLReview>())
        #expect(!remainingReviews.contains { $0.id == editedReview.id })
        #expect(festival.status == .none)
    }

    private func seededContext() throws -> ModelContext {
        let context = try emptyContext()
        try WristlistDataController.seedIfNeeded(in: context)
        return context
    }

    private func emptyContext() throws -> ModelContext {
        let schema = Schema(WristlistDataController.schemaModels)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return container.mainContext
    }
}
