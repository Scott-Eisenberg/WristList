//
//  WristListTests.swift
//  WristListTests
//
//  Created by Scott Eisenberg on 9/7/26.
//

import Foundation
import SwiftData
import Testing
@testable import WristList

@Suite(.serialized)
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
        let artistMatches = FestivalSearchService.results(from: festivals, filters: filters).map(\.name)
        #expect(artistMatches.contains("Midnight Atlas"))

        filters.searchText = "Long Beach"
        let cityMatches = FestivalSearchService.results(from: festivals, filters: filters).map(\.name)
        #expect(cityMatches.contains("Lunar Pier"))

        filters.searchText = "Electronic"
        let genreMatches = FestivalSearchService.results(from: festivals, filters: filters).map(\.name)
        #expect(genreMatches.contains("Nova Bloom"))
    }

    @Test func searchNormalizesWhitespacePunctuationAndCase() throws {
        let context = try seededContext()
        let festivals = try context.fetch(FetchDescriptor<WLFestival>())

        var filters = FestivalFilters()
        filters.searchText = "  midnight---atlas  "
        let punctuationMatches = FestivalSearchService.results(from: festivals, filters: filters).map(\.name)
        #expect(punctuationMatches.contains("Midnight Atlas"))

        filters.searchText = "red   mesa"
        let venueMatches = FestivalSearchService.results(from: festivals, filters: filters).map(\.name)
        #expect(venueMatches.contains("Canyon Echo"))
    }

    @Test func externalSearchParserReturnsFestivalPagesOnly() throws {
        let data = try #require("""
        {
            "query": {
                "pages": {
                    "52853": {
                        "pageid": 52853,
                        "ns": 0,
                        "title": "Alice's Adventures in Wonderland",
                        "index": 2,
                        "terms": {
                            "description": ["1865 children's novel by Lewis Carroll"]
                        },
                        "extract": "Alice's Adventures in Wonderland is an 1865 English children's novel by Lewis Carroll.",
                        "fullurl": "https://en.wikipedia.org/wiki/Alice%27s_Adventures_in_Wonderland"
                    },
                    "30884650": {
                        "pageid": 30884650,
                        "ns": 0,
                        "title": "Beyond Wonderland",
                        "index": 1,
                        "thumbnail": {
                            "source": "https://example.com/beyond.jpg",
                            "width": 320,
                            "height": 213
                        },
                        "terms": {
                            "description": ["American EDM festival"]
                        },
                        "extract": "Beyond Wonderland is an electronic dance festival organized by Insomniac Events.",
                        "fullurl": "https://en.wikipedia.org/wiki/Beyond_Wonderland"
                    },
                    "40015934": {
                        "pageid": 40015934,
                        "ns": 0,
                        "title": "Insomniac (promoter)",
                        "index": 3,
                        "terms": {
                            "description": ["American electronic music event promoter"]
                        },
                        "extract": "Insomniac runs electronic music events including Beyond Wonderland and Nocturnal Wonderland.",
                        "fullurl": "https://en.wikipedia.org/wiki/Insomniac_(promoter)"
                    }
                }
            }
        }
        """.data(using: .utf8))

        let results = try FestivalExternalSearchService.results(from: data, matching: "Beyond Wonderland")

        #expect(results.map(\.title) == ["Beyond Wonderland"])
        #expect(results.first?.subtitle == "American EDM festival")
    }

    @Test func importingExternalFestivalAddsSearchableSavedFestivalWithoutDuplicates() throws {
        let context = try seededContext()
        let sourceURL = try #require(URL(string: "https://en.wikipedia.org/wiki/Beyond_Wonderland"))
        let thumbnailURL = try #require(URL(string: "https://example.com/beyond.jpg"))
        let result = ExternalFestivalSearchResult(
            id: "wikipedia-30884650",
            title: "Beyond Wonderland",
            description: "American EDM festival",
            summary: "Beyond Wonderland is an electronic dance festival organized by Insomniac Events.",
            sourceName: "Wikipedia",
            sourceURL: sourceURL,
            thumbnailURL: thumbnailURL
        )

        let importedFestival = try WristlistDataController.importDiscoveredFestival(result, context: context)

        #expect(importedFestival.name == "Beyond Wonderland")
        #expect(importedFestival.isSaved)
        #expect(importedFestival.status == .saved)
        #expect(importedFestival.genres.contains("Electronic"))

        var filters = FestivalFilters()
        filters.searchText = "beyond wonderland"
        let searchMatches = FestivalSearchService.results(from: try context.fetch(FetchDescriptor<WLFestival>()), filters: filters)
        #expect(searchMatches.contains { $0.id == importedFestival.id })

        let duplicateImport = try WristlistDataController.importDiscoveredFestival(result, context: context)
        #expect(duplicateImport.id == importedFestival.id)

        let festivals = try context.fetch(FetchDescriptor<WLFestival>())
        let matchingFestivalCount = festivals.filter {
            FestivalSearchService.normalizedSearchText($0.name) == "beyond wonderland"
        }.count
        #expect(matchingFestivalCount == 1)
    }

    @Test func userSearchMatchesNameHandleAndFestivalContext() throws {
        let context = try seededContext()
        let profiles = try context.fetch(FetchDescriptor<WLProfile>())
        let reviews = try context.fetch(FetchDescriptor<WLReview>())
        let festivals = try context.fetch(FetchDescriptor<WLFestival>())
        let friendMatches = SampleProfileData.friendMatches()

        let nameMatches = UserSearchService.results(
            profiles: profiles,
            reviews: reviews,
            festivals: festivals,
            friendMatches: friendMatches,
            query: "Maya"
        )
        #expect(nameMatches.contains { $0.displayName == "Maya Chen" })
        #expect(nameMatches.filter { $0.id == "maya" }.count == 1)

        let handleMatches = UserSearchService.results(
            profiles: profiles,
            reviews: reviews,
            festivals: festivals,
            friendMatches: friendMatches,
            query: "alexafterdark"
        )
        #expect(handleMatches.contains { $0.displayName == "Alex Rivera" })

        let festivalMatches = UserSearchService.results(
            profiles: profiles,
            reviews: reviews,
            festivals: festivals,
            friendMatches: friendMatches,
            query: "Lunar Pier"
        )
        #expect(festivalMatches.contains { $0.displayName == "Jordan Ellis" })

        let hiddenReview = WLReview(
            id: "review-hidden-maya-search",
            festivalID: "midnight-atlas",
            userID: "maya",
            userName: "Maya Chen",
            userHandle: "@maya.wav",
            userInitials: "MC",
            userPalette: .violet,
            attendedDate: DateFormatting.date(year: 2026, month: 5, day: 16),
            overallScore: 7.9,
            lineupScore: 8.0,
            productionScore: 7.5,
            venueScore: 8.2,
            organizationScore: 7.6,
            valueScore: 7.7,
            reviewText: "Private planning notes.",
            favoritePerformances: [],
            isVisibleToFriends: false,
            likeCount: 0,
            commentCount: 0
        )

        let privateReviewMatches = UserSearchService.results(
            profiles: profiles,
            reviews: reviews + [hiddenReview],
            festivals: festivals,
            friendMatches: friendMatches,
            query: "Midnight Atlas"
        )
        #expect(!privateReviewMatches.contains { $0.id == "maya" })
    }

    @Test func profileDetailKeepsCurrentUserReviewsAfterDisplayNameChange() throws {
        let context = try seededContext()
        let profiles = try context.fetch(FetchDescriptor<WLProfile>())
        let reviews = try context.fetch(FetchDescriptor<WLReview>())
        let profile = try #require(profiles.first { $0.id == WristlistDataController.currentUserID })

        profile.displayName = "Renamed User"
        profile.username = "@renamed"

        let profileReviews = UserProfileDetailView.reviewsForProfile(
            userID: profile.id,
            displayName: profile.displayName,
            username: profile.username,
            isCurrentUser: true,
            reviews: reviews
        )

        #expect(profileReviews.contains { $0.id == "review-current-midnight" })
    }

    @Test func profileDetailHidesPrivateReviewsForOtherUsers() throws {
        let context = try seededContext()
        let reviews = try context.fetch(FetchDescriptor<WLReview>())
        let hiddenReview = WLReview(
            id: "review-hidden-maya",
            festivalID: "midnight-atlas",
            userID: "maya",
            userName: "Maya Chen",
            userHandle: "@maya.wav",
            userInitials: "MC",
            userPalette: .violet,
            attendedDate: DateFormatting.date(year: 2026, month: 5, day: 16),
            overallScore: 7.9,
            lineupScore: 8.0,
            productionScore: 7.5,
            venueScore: 8.2,
            organizationScore: 7.6,
            valueScore: 7.7,
            reviewText: "Private planning notes.",
            favoritePerformances: [],
            isVisibleToFriends: false,
            likeCount: 0,
            commentCount: 0
        )
        context.insert(hiddenReview)

        let profileReviews = UserProfileDetailView.reviewsForProfile(
            userID: "maya",
            displayName: "Maya Chen",
            username: "@maya.wav",
            isCurrentUser: false,
            reviews: reviews + [hiddenReview]
        )

        #expect(!profileReviews.contains { $0.id == hiddenReview.id })
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
        let firstFestivals = try context.fetch(FetchDescriptor<WLFestival>())
        let firstReviews = try context.fetch(FetchDescriptor<WLReview>())
        let firstFestivalCount = firstFestivals.count
        let firstReviewCount = firstReviews.count

        try WristlistDataController.seedIfNeeded(in: context)
        let secondFestivals = try context.fetch(FetchDescriptor<WLFestival>())
        let secondReviews = try context.fetch(FetchDescriptor<WLReview>())
        let secondFestivalCount = secondFestivals.count
        let secondReviewCount = secondReviews.count

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

        let createdReviewResult = try WristlistDataController.saveReview(draft: draft, festival: festival, profile: profile, existingReview: nil, context: context)
        let createdReview = try #require(createdReviewResult)
        #expect(createdReview.festivalID == festival.id)
        #expect(festival.status == .attended)

        draft.overallScore = 8.8
        draft.reviewText = "Updated note after comparing it with the rest of the year."
        let editedReviewResult = try WristlistDataController.saveReview(draft: draft, festival: festival, profile: profile, existingReview: createdReview, context: context)
        let editedReview = try #require(editedReviewResult)
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
        let configuration = ModelConfiguration("WristListTests-\(UUID().uuidString)", schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return container.mainContext
    }
}
