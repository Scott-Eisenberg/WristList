//
//  SampleProfileData.swift
//  WristList
//

import Foundation

enum SampleProfileData {
    static func profile() -> WLProfile {
        WLProfile(
            id: WristlistDataController.currentUserID,
            displayName: "Scott Eisenberg",
            username: "@scottontour",
            bio: "Chasing crisp sound, late-night sets, and festival weekends with strong logistics.",
            homeCity: "Los Angeles, CA",
            avatarInitials: "SE",
            palette: .sunset,
            followers: 486,
            following: 221,
            currentStreak: 7,
            privacy: .friends,
            notificationsEnabled: true,
            reviewLikesEnabled: true
        )
    }

    static func friendMatches() -> [FriendFestivalMatch] {
        [
            FriendFestivalMatch(id: "maya", name: "Maya", initials: "MC", matchPercent: 94, sharedFavorites: "Nova Bloom + Harbor Glow", palette: .violet),
            FriendFestivalMatch(id: "alex", name: "Alex", initials: "AR", matchPercent: 89, sharedFavorites: "Desert Circuit + Midnight Atlas", palette: .electric),
            FriendFestivalMatch(id: "jordan", name: "Jordan", initials: "JE", matchPercent: 82, sharedFavorites: "Lunar Pier + Solstice Yard", palette: .sunset)
        ]
    }

    static func wristbandMemories(from festivals: [WLFestival]) -> [WristbandMemory] {
        RankingService.rankedFestivals(from: festivals).prefix(3).map { festival in
            WristbandMemory(
                id: "memory-\(festival.id)",
                year: (festival.attendedDate ?? festival.endDate).formatted(.dateTime.year()),
                festivalName: festival.name,
                moment: memoryMoment(for: festival.id),
                palette: festival.palette
            )
        }
    }

    static func tasteSignals(festivals: [WLFestival], reviews: [WLReview]) -> [TasteSignal] {
        let attended = festivals.filter { $0.status == .attended }
        let genreCounts = Dictionary(grouping: attended.flatMap(\.genres), by: { $0 }).mapValues(\.count)
        let favoriteGenre = genreCounts.max { first, second in first.value < second.value }?.key ?? "Electronic"
        let averageRating = reviews.filter(\.isCurrentUser).map(\.overallScore).average
        let productionAverage = reviews.filter(\.isCurrentUser).map(\.productionScore).average

        return [
            TasteSignal(id: "genre", title: favoriteGenre, detail: "Top genre", systemImage: "waveform", palette: .electric),
            TasteSignal(id: "ranked", title: "\(attended.count) ranked", detail: "Festival history", systemImage: "list.number", palette: .sunset),
            TasteSignal(id: "average", title: String(format: "%.1f avg", averageRating), detail: "Your rating", systemImage: "star.fill", palette: .violet),
            TasteSignal(id: "production", title: String(format: "%.1f prod", productionAverage), detail: "Production score", systemImage: "sparkles", palette: .lagoon)
        ]
    }

    static func cityStats(from festivals: [WLFestival]) -> [CityFestivalStat] {
        let attended = festivals.filter { $0.status == .attended }
        let grouped = Dictionary(grouping: attended, by: \.cityState)

        return grouped.map { city, festivals in
            let topFestival = festivals.sorted { $0.personalRank < $1.personalRank }.first
            return CityFestivalStat(
                id: city,
                city: city,
                count: festivals.count,
                topFestivalName: topFestival?.name ?? "None yet",
                palette: topFestival?.palette ?? .sunset
            )
        }
        .sorted { first, second in
            if first.count == second.count {
                return first.city < second.city
            }
            return first.count > second.count
        }
    }

    private static func memoryMoment(for festivalID: String) -> String {
        switch festivalID {
        case "midnight-atlas":
            "Late transport worked and the final stage run felt perfectly paced."
        case "canyon-echo":
            "Small crowd, clear sightlines, and a Sunday closer that felt rare."
        case "solstice-yard":
            "First rail spot at the warehouse stage after a long city day."
        default:
            "A weekend worth keeping in the wristband drawer."
        }
    }
}

struct WristbandMemory: Identifiable, Hashable {
    let id: String
    let year: String
    let festivalName: String
    let moment: String
    let palette: FestivalPalette
}

private extension Array where Element == Double {
    var average: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}
