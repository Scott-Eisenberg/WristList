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
        !FestivalSearchService.normalizedSearchText(searchText).isEmpty ||
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

enum FestivalSearchMatchKind: String, Equatable {
    case festival
    case artist
    case location
    case venue
    case genre
    case description
    case filtered

    var title: String {
        switch self {
        case .festival: "Festival"
        case .artist: "Artist"
        case .location: "Place"
        case .venue: "Venue"
        case .genre: "Genre"
        case .description: "About"
        case .filtered: "Match"
        }
    }
}

struct FestivalSearchResult: Identifiable {
    var id: String { festival.id }

    let festival: WLFestival
    let matchKind: FestivalSearchMatchKind
    let matchDetail: String
    let score: Int
}

enum FestivalSearchService {
    nonisolated static func normalizedSearchText(_ value: String) -> String {
        let foldedValue = value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        let searchableCharacters = foldedValue.unicodeScalars.map { scalar in
            CharacterSet.alphanumerics.contains(scalar) ? String(scalar) : " "
        }

        return searchableCharacters
            .joined()
            .split { $0.isWhitespace }
            .joined(separator: " ")
    }

    static func results(from festivals: [WLFestival], filters: FestivalFilters, now: Date = .now) -> [WLFestival] {
        rankedResults(from: festivals, filters: filters, now: now).map(\.festival)
    }

    static func rankedResults(from festivals: [WLFestival], filters: FestivalFilters, now: Date = .now) -> [FestivalSearchResult] {
        let normalizedQuery = normalizedSearchText(filters.searchText)

        return festivals.filter { festival in
            matchesSearch(festival, query: filters.searchText) &&
            matchesDate(festival, dateFilter: filters.dateFilter, now: now) &&
            matchesStatus(festival, statusFilter: filters.statusFilter) &&
            matchesGenre(festival, genre: filters.genre) &&
            matchesCity(festival, city: filters.city)
        }
        .map { festival in
            searchResult(for: festival, normalizedQuery: normalizedQuery, now: now)
        }
        .sorted { first, second in
            guard !normalizedQuery.isEmpty else {
                if first.festival.startDate == second.festival.startDate {
                    return first.festival.name.localizedStandardCompare(second.festival.name) == .orderedAscending
                }
                return first.festival.startDate < second.festival.startDate
            }

            if first.score != second.score {
                return first.score > second.score
            }
            if first.festival.startDate == second.festival.startDate {
                return first.festival.name.localizedStandardCompare(second.festival.name) == .orderedAscending
            }
            return first.festival.startDate < second.festival.startDate
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
        let normalizedQuery = normalizedSearchText(query)
        guard !normalizedQuery.isEmpty else { return true }

        let searchableValues = [
            festival.name,
            festival.city,
            festival.state,
            festival.venue,
            festival.summary,
            festival.detailDescription
        ] + festival.genres + festival.lineup

        let searchableText = searchableValues
            .map(normalizedSearchText)
            .joined(separator: " ")

        if searchableText.contains(normalizedQuery) {
            return true
        }

        let queryTokens = normalizedQuery.split(separator: " ").map(String.init)
        return queryTokens.allSatisfy { searchableText.contains($0) }
    }

    private static func searchResult(for festival: WLFestival, normalizedQuery: String, now: Date) -> FestivalSearchResult {
        guard !normalizedQuery.isEmpty else {
            return FestivalSearchResult(
                festival: festival,
                matchKind: .filtered,
                matchDetail: festival.dateRangeText,
                score: 0
            )
        }

        let candidates: [(kind: FestivalSearchMatchKind, detail: String, value: String, weight: Int)] = [
            (.festival, festival.festivalSeriesName, festival.festivalSeriesName, 1_000),
            (.festival, festival.name, festival.name, 950)
        ] + festival.lineup.map { (.artist, $0, $0, 700) } + [
            (.location, festival.cityState, "\(festival.city) \(festival.state) \(festival.country)", 560),
            (.venue, festival.venue, festival.venue, 500)
        ] + festival.genres.map { (.genre, $0, $0, 440) } + [
            (.description, festival.summary, "\(festival.summary) \(festival.detailDescription)", 160)
        ]

        let bestCandidate = candidates
            .compactMap { candidate -> (FestivalSearchMatchKind, String, Int)? in
                let normalizedValue = normalizedSearchText(candidate.value)
                guard fieldMatches(normalizedValue, query: normalizedQuery) else { return nil }

                let qualityBonus: Int
                if normalizedValue == normalizedQuery {
                    qualityBonus = 120
                } else if normalizedValue.hasPrefix(normalizedQuery) {
                    qualityBonus = 70
                } else if normalizedValue.contains(normalizedQuery) {
                    qualityBonus = 35
                } else {
                    qualityBonus = 0
                }
                return (candidate.kind, candidate.detail, candidate.weight + qualityBonus)
            }
            .max { $0.2 < $1.2 }

        let socialBonus = min(festival.friendNames.count * 6, 30)
        let upcomingBonus = festival.endDate >= Calendar.current.startOfDay(for: now) ? 20 : 0
        let ratingBonus = Int(festival.communityRating.rounded())

        return FestivalSearchResult(
            festival: festival,
            matchKind: bestCandidate?.0 ?? .filtered,
            matchDetail: bestCandidate?.1 ?? "Multiple fields",
            score: (bestCandidate?.2 ?? 0) + socialBonus + upcomingBonus + ratingBonus
        )
    }

    private static func fieldMatches(_ normalizedValue: String, query: String) -> Bool {
        if normalizedValue.contains(query) {
            return true
        }
        let queryTokens = query.split(separator: " ").map(String.init)
        return queryTokens.allSatisfy { normalizedValue.contains($0) }
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

struct ExternalFestivalSearchResult: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String?
    let summary: String
    let sourceName: String
    let sourceURL: URL
    let thumbnailURL: URL?

    var subtitle: String {
        guard let description, !description.isEmpty else {
            return sourceName
        }
        return description
    }
}

protocol FestivalRemoteSearching: Sendable {
    func search(query: String, limit: Int) async throws -> [ExternalFestivalSearchResult]
}

struct WikipediaFestivalSearchProvider: FestivalRemoteSearching {
    func search(query: String, limit: Int = 5) async throws -> [ExternalFestivalSearchResult] {
        try await FestivalExternalSearchService.search(query: query, limit: limit)
    }
}

enum FestivalExternalSearchError: LocalizedError, Equatable {
    case invalidResponse
    case requestFailed(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "The festival search response could not be read."
        case .requestFailed(let statusCode):
            "Online festival search failed with status \(statusCode)."
        }
    }
}

enum FestivalExternalSearchService {
    static let minimumQueryLength = 2
    private static let sourceName = "Wikipedia"

    static func search(query: String, limit: Int = 5, session: URLSession = .shared) async throws -> [ExternalFestivalSearchResult] {
        let normalizedQuery = FestivalSearchService.normalizedSearchText(query)
        guard normalizedQuery.count >= minimumQueryLength else { return [] }

        var request = URLRequest(url: try searchURL(for: query, limit: limit * 2))
        request.setValue("WristList/1.0 festival search", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FestivalExternalSearchError.invalidResponse
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            throw FestivalExternalSearchError.requestFailed(httpResponse.statusCode)
        }

        return try results(from: data, matching: query, limit: limit)
    }

    static func results(from data: Data, matching query: String, limit: Int = 5) throws -> [ExternalFestivalSearchResult] {
        let response = try JSONDecoder().decode(WikipediaSearchResponse.self, from: data)
        let queryTokens = significantTokens(from: query)
        let pages = response.query?.pages.values.map { $0 } ?? []
        var seenTitles = Set<String>()

        return pages
            .sorted { ($0.index ?? Int.max) < ($1.index ?? Int.max) }
            .compactMap { page -> ExternalFestivalSearchResult? in
                guard looksLikeFestivalResult(page, queryTokens: queryTokens) else { return nil }

                let normalizedTitle = FestivalSearchService.normalizedSearchText(page.title)
                guard seenTitles.insert(normalizedTitle).inserted else { return nil }

                let fallbackURL = URL(string: "https://en.wikipedia.org/?curid=\(page.pageid)")
                guard let sourceURL = page.fullurl ?? fallbackURL else { return nil }

                let description = cleaned(page.terms?.description?.first)
                let summary = cleaned(page.extract) ?? description ?? "Festival information from \(sourceName)."

                return ExternalFestivalSearchResult(
                    id: "\(sourceName.lowercased())-\(page.pageid)",
                    title: page.title,
                    description: description,
                    summary: summary,
                    sourceName: sourceName,
                    sourceURL: sourceURL,
                    thumbnailURL: page.thumbnail?.source
                )
            }
            .prefix(limit)
            .map { $0 }
    }

    private static func searchURL(for query: String, limit: Int) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "en.wikipedia.org"
        components.path = "/w/api.php"
        components.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "generator", value: "search"),
            URLQueryItem(name: "gsrsearch", value: "\(query) music festival"),
            URLQueryItem(name: "gsrnamespace", value: "0"),
            URLQueryItem(name: "gsrlimit", value: "\(max(1, limit))"),
            URLQueryItem(name: "prop", value: "pageimages|pageterms|extracts|info"),
            URLQueryItem(name: "inprop", value: "url"),
            URLQueryItem(name: "exintro", value: "1"),
            URLQueryItem(name: "explaintext", value: "1"),
            URLQueryItem(name: "exsentences", value: "2"),
            URLQueryItem(name: "piprop", value: "thumbnail"),
            URLQueryItem(name: "pithumbsize", value: "320"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "origin", value: "*")
        ]

        guard let url = components.url else {
            throw FestivalExternalSearchError.invalidResponse
        }
        return url
    }

    private static func looksLikeFestivalResult(_ page: WikipediaPage, queryTokens: [String]) -> Bool {
        let normalizedTitle = FestivalSearchService.normalizedSearchText(page.title)
        let normalizedDescription = FestivalSearchService.normalizedSearchText(page.terms?.description?.first ?? "")
        let normalizedExtract = FestivalSearchService.normalizedSearchText(page.extract ?? "")
        let normalizedBody = "\(normalizedDescription) \(normalizedExtract)"
        let combinedText = "\(normalizedTitle) \(normalizedBody)"

        let hasBodyQueryMatch: Bool
        let hasTitleQueryMatch: Bool
        if queryTokens.count > 1 {
            hasTitleQueryMatch = queryTokens.allSatisfy { normalizedTitle.contains($0) }

            let matchedTokenCount = queryTokens.filter { combinedText.contains($0) }.count
            hasBodyQueryMatch = matchedTokenCount >= min(2, queryTokens.count)
        } else if let queryToken = queryTokens.first {
            hasTitleQueryMatch = normalizedTitle.contains(queryToken)
            hasBodyQueryMatch = combinedText.contains(queryToken)
        } else {
            hasTitleQueryMatch = false
            hasBodyQueryMatch = false
        }

        let festivalTerms = [
            "festival",
            "festivals",
            "music festival",
            "electronic dance",
            "edm festival",
            "concert festival",
            "lineup"
        ]
        let hasFestivalContext = festivalTerms.contains { combinedText.contains($0) }
        let hasFestivalDescriptor = festivalTerms.contains { normalizedDescription.contains($0) }

        return (hasTitleQueryMatch && hasFestivalContext) || (hasBodyQueryMatch && hasFestivalDescriptor)
    }

    private static func significantTokens(from query: String) -> [String] {
        let stopWords: Set<String> = ["a", "an", "and", "at", "for", "in", "music", "of", "the"]

        return FestivalSearchService.normalizedSearchText(query)
            .split(separator: " ")
            .map(String.init)
            .filter { $0.count > 1 && !stopWords.contains($0) }
    }

    private static func cleaned(_ value: String?) -> String? {
        let cleanedValue = value?
            .split { $0.isWhitespace || $0.isNewline }
            .joined(separator: " ")

        guard let cleanedValue, !cleanedValue.isEmpty else {
            return nil
        }
        return cleanedValue
    }
}

private struct WikipediaSearchResponse: Decodable {
    let query: WikipediaQuery?
}

private struct WikipediaQuery: Decodable {
    let pages: [String: WikipediaPage]
}

private struct WikipediaPage: Decodable {
    let pageid: Int
    let index: Int?
    let title: String
    let extract: String?
    let fullurl: URL?
    let thumbnail: WikipediaThumbnail?
    let terms: WikipediaTerms?
}

private struct WikipediaThumbnail: Decodable {
    let source: URL
}

private struct WikipediaTerms: Decodable {
    let description: [String]?
}
