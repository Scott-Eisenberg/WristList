import Foundation
import SwiftData

enum JournalSampleData {
    // Illustrative dates and lineups for the demo, not a live event calendar.
    static func festivals() -> [WLFestival] {
        [
            make("outside-lands", "Outside Lands", "San Francisco", "CA", "Golden Gate Park", 2026, 8, 7, 9,
                 ["Indie", "Electronic", "Hip-Hop"], ["Tyler, the Creator", "Hozier", "Jamie xx", "Vampire Weekend"],
                 "Fog in the trees. A favorite song from the next stage. Three days that feel like San Francisco.", 9.2, 1),
            make("lollapalooza", "Lollapalooza", "Chicago", "IL", "Grant Park", 2026, 7, 30, 31,
                 ["Pop", "Rock", "Hip-Hop"], ["Olivia Rodrigo", "RÜFÜS DU SOL", "A$AP Rocky", "Clairo"],
                 "Big stages, lake breezes, and a skyline that deserves its own encore.", 8.6, 2),
            make("coachella", "Coachella", "Indio", "CA", "Empire Polo Club", 2026, 4, 10, 12,
                 ["Pop", "Electronic", "Indie"], ["Lady Gaga", "Green Day", "Post Malone", "The Marías"],
                 "Desert sunsets, art installations, and the kind of set you talk about all year.", 7.9, 3),
            make("bonnaroo", "Bonnaroo", "Manchester", "TN", "Great Stage Park", 2027, 6, 10, 13,
                 ["Rock", "Electronic", "Soul"], ["Lineup to be announced"],
                 "Long nights on the farm, new friends at camp, and one more set before sunrise.", 8.9, 0),
            make("outside-lands-2027", "Outside Lands 2027", "San Francisco", "CA", "Golden Gate Park", 2027, 8, 6, 8,
                 ["Indie", "Electronic", "Hip-Hop"], ["Lineup to be announced"],
                 "Put another weekend in the park on your horizon.", 9.1, 0),
            make("coachella-2027", "Coachella 2027", "Indio", "CA", "Empire Polo Club", 2027, 4, 9, 11,
                 ["Pop", "Electronic", "Indie"], ["Lineup to be announced"],
                 "A new chapter under the desert sky.", 8.5, 0)
        ]
    }

    private static func make(_ id: String, _ name: String, _ city: String, _ state: String, _ venue: String,
                             _ year: Int, _ month: Int, _ start: Int, _ end: Int, _ genres: [String],
                             _ lineup: [String], _ summary: String, _ score: Double, _ rank: Int) -> WLFestival {
        let festival = WLFestival(id: id, name: name, city: city, state: state, venue: venue,
                   startDate: DateFormatting.date(year: year, month: month, day: start),
                   endDate: DateFormatting.date(year: year, month: month, day: end),
                   genres: genres, lineup: lineup, summary: summary, detailDescription: summary,
                   palette: .violet, communityRating: score, communityReviewCount: 128,
                   lineupScore: score, productionScore: score, venueScore: score,
                   organizationScore: score, valueScore: score,
                   friendNames: id.contains("coachella") ? ["Jordan", "Tess"] : ["Maya", "Alex", "Priya"],
                   isTrending: true, isRecommended: true, isNearUser: city == "San Francisco",
                   isSaved: rank > 0 || id == "bonnaroo", status: rank > 0 ? .attended : id == "bonnaroo" ? .wantToGo : .none,
                   personalRank: rank,
                   attendedDate: rank > 0 ? DateFormatting.date(year: year, month: month, day: start) : nil)
        if id == "lollapalooza" { festival.endDate = DateFormatting.date(year: 2026, month: 8, day: 2) }
        return festival
    }

    static func reviews() -> [WLReview] {
        let attended = festivals().filter { $0.personalRank > 0 }
        return attended.flatMap { festival in
            [review(festival, current: true), review(festival, current: false)]
        }
    }

    private static func review(_ festival: WLFestival, current: Bool) -> WLReview {
        WLReview(id: "journal-\(festival.id)-\(current ? "me" : "maya")", festivalID: festival.id,
                 userID: current ? WristlistDataController.currentUserID : "maya-journal",
                 userName: current ? "Scott" : "Maya Chen", userHandle: current ? "@scott" : "@mayachen",
                 userInitials: current ? "SE" : "MC", userPalette: .violet,
                 attendedDate: festival.endDate, overallScore: festival.communityRating,
                 lineupScore: festival.communityRating, productionScore: 8, venueScore: 9,
                 organizationScore: 8, valueScore: 8,
                 reviewText: current ? "A weekend worth keeping." : "Still thinking about that last set. Go with people who are happy to get a little lost between stages.",
                 favoritePerformances: [], isVisibleToFriends: true, likeCount: current ? 0 : 12,
                 commentCount: 0, isCurrentUser: current)
    }

    @MainActor
    static func install(in context: ModelContext) throws {
        let key = "journal-catalog-v1"
        guard try !context.fetch(FetchDescriptor<WLAppMetadata>()).contains(where: { $0.key == key }) else { return }
        let existing = try context.fetch(FetchDescriptor<WLFestival>())
        let ids = Set(existing.map(\.id))
        var nextRank = (existing.map(\.personalRank).max() ?? 0) + 1
        var inserted = Set<String>()
        for festival in festivals() where !ids.contains(festival.id) {
            if festival.personalRank > 0 {
                festival.personalRank = nextRank
                nextRank += 1
            }
            context.insert(festival)
            inserted.insert(festival.id)
        }
        for review in reviews() where inserted.contains(review.festivalID) { context.insert(review) }
        context.insert(WLAppMetadata(key: key, value: "true"))
        try context.save()
    }
}
