//
//  FestivalSearchService.swift
//  WristList
//

import Foundation

enum FestivalDateFilter: String, CaseIterable, Identifiable {
    case any
    case upcoming
    case past
    case next30Days

    var id: String { rawValue }

    var title: String {
        switch self {
        case .any:
            "Any date"
        case .upcoming:
            "Upcoming"
        case .past:
            "Past"
        case .next30Days:
            "Next 30 days"
        }
    }
}

enum FestivalStatusFilter: String, CaseIterable, Identifiable {
    case all
    case saved
    case wantToGo
    case attended

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            "All"
        case .saved:
            "Saved"
        case .wantToGo:
            "Want"
        case .attended:
            "Attended"
        }
    }
}

enum FestivalSortOption: String, CaseIterable, Identifiable {
    case date
    case rating
    case name
    case ranking

    var id: String { rawValue }

    var title: String {
        switch self {
        case .date:
            "Date"
        case .rating:
            "Rating"
        case .name:
            "Name"
        case .ranking:
            "Ranking"
        }
    }
}

struct FestivalFilters: Equatable {
    var searchText = ""
    var dateFilter: FestivalDateFilter = .any
    var statusFilter: FestivalStatusFilter = .all
    var genre = "All"
    var city = "All"

    var isActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        dateFilter != .any ||
        statusFilter != .all ||
        genre != "All" ||
        city != "All"
    }

    mutating func clear() {
        searchText = ""
        dateFilter = .any
        statusFilter = .all
        genre = "All"
        city = "All"
    }
}

enum FestivalSearchService {
    static func results(from festivals: [WLFestival], filters: FestivalFilters, now: Date = .now) -> [WLFestival] {
        festivals.filter { festival in
            matchesSearch(festival, query: filters.searchText) &&
            matchesDate(festival, dateFilter: filters.dateFilter, now: now) &&
            matchesStatus(festival, statusFilter: filters.statusFilter) &&
            matchesGenre(festival, genre: filters.genre) &&
            matchesCity(festival, city: filters.city)
        }
        .sorted { first, second in
            if first.startDate == second.startDate {
                return first.name.localizedStandardCompare(second.name) == .orderedAscending
            }
            return first.startDate < second.startDate
        }
    }

    static func sorted(_ festivals: [WLFestival], by option: FestivalSortOption) -> [WLFestival] {
        switch option {
        case .date:
            festivals.sorted { $0.startDate < $1.startDate }
        case .rating:
            festivals.sorted { $0.communityRating > $1.communityRating }
        case .name:
            festivals.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .ranking:
            RankingService.rankedFestivals(from: festivals)
        }
    }

    static func availableGenres(from festivals: [WLFestival]) -> [String] {
        ["All"] + Set(festivals.flatMap(\.genres)).sorted()
    }

    static func availableCities(from festivals: [WLFestival]) -> [String] {
        ["All"] + Set(festivals.map(\.cityState)).sorted()
    }

    private static func matchesSearch(_ festival: WLFestival, query: String) -> Bool {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return true }

        let searchableValues = [
            festival.name,
            festival.city,
            festival.state,
            festival.venue,
            festival.summary,
            festival.detailDescription
        ] + festival.genres + festival.lineup

        return searchableValues.contains { value in
            value.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }

    private static func matchesDate(_ festival: WLFestival, dateFilter: FestivalDateFilter, now: Date) -> Bool {
        let startOfToday = Calendar.current.startOfDay(for: now)
        let thirtyDaysOut = Calendar.current.date(byAdding: .day, value: 30, to: startOfToday) ?? startOfToday

        switch dateFilter {
        case .any:
            return true
        case .upcoming:
            return festival.endDate >= startOfToday
        case .past:
            return festival.endDate < startOfToday
        case .next30Days:
            return festival.startDate >= startOfToday && festival.startDate <= thirtyDaysOut
        }
    }

    private static func matchesStatus(_ festival: WLFestival, statusFilter: FestivalStatusFilter) -> Bool {
        switch statusFilter {
        case .all:
            return true
        case .saved:
            return festival.isSaved
        case .wantToGo:
            return festival.status == .wantToGo
        case .attended:
            return festival.status == .attended
        }
    }

    private static func matchesGenre(_ festival: WLFestival, genre: String) -> Bool {
        genre == "All" || festival.genres.contains(genre)
    }

    private static func matchesCity(_ festival: WLFestival, city: String) -> Bool {
        city == "All" || festival.cityState == city
    }
}
