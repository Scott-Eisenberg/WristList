//
//  RankingService.swift
//  WristList
//

import Foundation

enum RankingService {
    static func rankedFestivals(from festivals: [WLFestival]) -> [WLFestival] {
        festivals
            .filter { $0.status == .attended }
            .sorted { first, second in
                if first.personalRank == 0 && second.personalRank == 0 {
                    return first.communityRating > second.communityRating
                }
                if first.personalRank == 0 {
                    return false
                }
                if second.personalRank == 0 {
                    return true
                }
                return first.personalRank < second.personalRank
            }
    }

    @MainActor
    static func normalizeRanks(for festivals: [WLFestival]) {
        for (index, festival) in rankedFestivals(from: festivals).enumerated() {
            festival.personalRank = index + 1
            festival.updatedAt = .now
        }
    }

    @MainActor
    static func moveFestival(_ festival: WLFestival, direction: MoveDirection, in festivals: [WLFestival]) {
        var ranked = rankedFestivals(from: festivals)
        guard let currentIndex = ranked.firstIndex(where: { $0.id == festival.id }) else { return }

        let destinationIndex: Int
        switch direction {
        case .up:
            destinationIndex = max(0, currentIndex - 1)
        case .down:
            destinationIndex = min(ranked.count - 1, currentIndex + 1)
        }

        guard currentIndex != destinationIndex else { return }

        ranked.swapAt(currentIndex, destinationIndex)
        for (index, rankedFestival) in ranked.enumerated() {
            rankedFestival.personalRank = index + 1
            rankedFestival.updatedAt = .now
        }
    }
}

enum MoveDirection {
    case up
    case down
}
