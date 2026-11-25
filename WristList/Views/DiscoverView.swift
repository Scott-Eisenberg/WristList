//
//  DiscoverView.swift
//  WristList
//

import SwiftData
import SwiftUI

struct DiscoverView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Query private var festivals: [WLFestival]

    @State private var filters = FestivalFilters()
    @State private var remoteFestivalResults: [ExternalFestivalSearchResult] = []
    @State private var remoteSearchError: String?
    @State private var remoteSearchQuery = ""
    @State private var isRemoteSearchLoading = false
    @State private var importingRemoteResultID: ExternalFestivalSearchResult.ID?
    @State private var selectedImportedFestival: WLFestival?
    @State private var isShowingImportedFestival = false
    @State private var actionError: String?

    private let remoteSearchProvider: any FestivalRemoteSearching

    init(remoteSearchProvider: any FestivalRemoteSearching = WikipediaFestivalSearchProvider()) {
        self.remoteSearchProvider = remoteSearchProvider
    }

    private var normalizedSearchText: String {
        FestivalSearchService.normalizedSearchText(filters.searchText)
    }

    private var searchResults: [FestivalSearchResult] {
        FestivalSearchService.rankedResults(from: festivals, filters: filters)
    }

    private var shouldSearchRemoteFestivals: Bool {
        normalizedSearchText.count >= FestivalExternalSearchService.minimumQueryLength
    }

    private var isRemoteSearchInProgress: Bool {
        shouldSearchRemoteFestivals &&
        (isRemoteSearchLoading || FestivalSearchService.normalizedSearchText(remoteSearchQuery) != normalizedSearchText)
    }

    private var visibleRemoteFestivalResults: [ExternalFestivalSearchResult] {
        guard FestivalSearchService.normalizedSearchText(remoteSearchQuery) == normalizedSearchText else {
            return []
        }

        let localFestivalNames = Set(festivals.map { FestivalSearchService.normalizedSearchText($0.name) })
        return remoteFestivalResults.filter { result in
            !localFestivalNames.contains(FestivalSearchService.normalizedSearchText(result.title))
        }
    }

    private var resultsSubtitle: String {
        guard shouldSearchRemoteFestivals else {
            return "\(searchResults.count) matching festivals"
        }

        if isRemoteSearchInProgress {
            return "\(searchResults.count) local · searching online"
        }

        return "\(searchResults.count) local · \(visibleRemoteFestivalResults.count) online"
    }

    private var trendingFestivals: [WLFestival] {
        festivals.filter(\.isTrending).sorted { $0.communityRating > $1.communityRating }
    }

    private var nearYouFestivals: [WLFestival] {
        festivals.filter(\.isNearUser).sorted { $0.startDate < $1.startDate }
    }

    private var comingSoonFestivals: [WLFestival] {
        festivals.filter { $0.timing == .upcoming }.sorted { $0.startDate < $1.startDate }
    }

    private var recommendedFestivals: [WLFestival] {
        festivals.filter(\.isRecommended).sorted { $0.communityRating > $1.communityRating }
    }

    private var availableGenres: [String] {
        FestivalSearchService.availableGenres(from: festivals)
    }

    private var availableCities: [String] {
        FestivalSearchService.availableCities(from: festivals)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 30) {
                    header
                    filterBar

                    if filters.isActive {
                        resultsSection
                    } else if festivals.isEmpty {
                        EmptyStateView(
                            title: "No festivals yet",
                            message: "Sample festivals are seeded locally when the app starts. Use Settings to reset sample data if needed.",
                            systemImage: "music.mic"
                        )
                    } else {
                        DiscoverySection(title: "Trending", subtitle: "The festivals your circle keeps bringing up", festivals: trendingFestivals)
                        DiscoverySection(title: "Near You", subtitle: "Weekends close enough to make the group chat", festivals: nearYouFestivals)
                        DiscoverySection(title: "Coming Soon", subtitle: "Next dates on the calendar", festivals: comingSoonFestivals)
                        DiscoverySection(title: "Worth a Look", subtitle: "Strong ratings, lineups, and friend activity", festivals: recommendedFestivals)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 34)
            }
            .background(WristlistTheme.appBackground(for: colorScheme).ignoresSafeArea())
            .navigationTitle("")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $filters.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Festival, artist, city, venue, genre")
#else
            .searchable(text: $filters.searchText, prompt: "Festival, artist, city, venue, genre")
#endif
            .searchSuggestions {
                ForEach(searchResults.prefix(5)) { result in
                    Label {
                        Text("\(result.festival.festivalSeriesName) · \(result.festival.editionYear)")
                    } icon: {
                        Image(systemName: result.matchKind == .artist ? "music.note" : "ticket")
                    }
                    .searchCompletion(result.festival.name)
                }
            }
            .task(id: normalizedSearchText) {
                await refreshRemoteFestivalResults(for: filters.searchText)
            }
            .navigationDestination(isPresented: $isShowingImportedFestival) {
                if let selectedImportedFestival {
                    FestivalDetailView(festival: selectedImportedFestival)
                } else {
                    EmptyView()
                }
            }
            .alert(
                "Could not add festival",
                isPresented: Binding(
                    get: { actionError != nil },
                    set: { isPresented in
                        if !isPresented {
                            actionError = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {
                    actionError = nil
                }
            } message: {
                Text(actionError ?? "Try again.")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Discover")
                .font(WristlistTheme.pageTitleFont)
                .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                .lineLimit(2)
                .minimumScaleFactor(0.76)

            Text("Start with a city, a lineup name, or the kind of weekend you want.")
                .font(.body)
                .lineSpacing(3)
                .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
        }
    }

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    Menu {
                        Picker("Date", selection: $filters.dateFilter) {
                            ForEach(FestivalDateFilter.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                    } label: {
                        FilterChip(title: filters.dateFilter.title, systemImage: "calendar")
                    }

                    Menu {
                        Picker("Status", selection: $filters.statusFilter) {
                            ForEach(FestivalStatusFilter.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                    } label: {
                        FilterChip(title: filters.statusFilter.title, systemImage: "bookmark")
                    }

                    Menu {
                        Picker("Genre", selection: $filters.genre) {
                            ForEach(availableGenres, id: \.self) { genre in
                                Text(genre).tag(genre)
                            }
                        }
                    } label: {
                        FilterChip(title: filters.genre, systemImage: "waveform")
                    }

                    Menu {
                        Picker("Location", selection: $filters.city) {
                            ForEach(availableCities, id: \.self) { city in
                                Text(city).tag(city)
                            }
                        }
                    } label: {
                        FilterChip(title: filters.city, systemImage: "mappin.and.ellipse")
                    }

                    if filters.isActive {
                        Button("Clear") {
                            filters.clear()
                        }
                        .font(WristlistTheme.kickerFont)
                        .tracking(0.8)
                        .foregroundStyle(WristlistTheme.coral)
                        .frame(minHeight: 44)
                        .accessibilityLabel("Clear filters")
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitleView(title: "Results", subtitle: resultsSubtitle)

            if searchResults.isEmpty && visibleRemoteFestivalResults.isEmpty && !isRemoteSearchInProgress && remoteSearchError == nil {
                EmptyStateView(
                    title: "No matches",
                    message: "Try a broader search or clear filters to get back to discovery sections.",
                    systemImage: "magnifyingglass",
                    actionTitle: "Clear Filters",
                    action: { filters.clear() }
                )
            } else {
                if !searchResults.isEmpty {
                    LazyVStack(spacing: 0) {
                        ForEach(searchResults) { result in
                            HStack(spacing: 8) {
                                NavigationLink {
                                    FestivalDetailView(festival: result.festival)
                                } label: {
                                    FestivalSearchResultRow(result: result, showsMatchReason: !normalizedSearchText.isEmpty)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    toggleSaved(result.festival)
                                } label: {
                                    Image(systemName: result.festival.isSaved ? "bookmark.fill" : "bookmark")
                                        .font(.body.weight(.bold))
                                        .foregroundStyle(result.festival.isSaved ? WristlistTheme.coral : WristlistTheme.secondaryText(for: colorScheme))
                                        .frame(width: 44, height: 44)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(result.festival.isSaved ? "Remove \(result.festival.name) from saved festivals" : "Save \(result.festival.name)")
                            }

                            EditorialDivider()
                        }
                    }
                }

                remoteResultsSection
            }
        }
    }

    @ViewBuilder
    private var remoteResultsSection: some View {
        if shouldSearchRemoteFestivals {
            if isRemoteSearchInProgress {
                RemoteSearchStatusRow(
                    systemImage: "magnifyingglass",
                    title: "Searching online",
                    message: "Looking for festival matches."
                )
            } else if let remoteSearchError {
                RemoteSearchStatusRow(
                    systemImage: "wifi.exclamationmark",
                    title: "Online search unavailable",
                    message: remoteSearchError,
                    actionTitle: "Retry",
                    action: {
                        Task {
                            await refreshRemoteFestivalResults(for: filters.searchText, debounce: false)
                        }
                    }
                )
            } else if !visibleRemoteFestivalResults.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    SectionTitleView(title: "Online Matches", subtitle: "External event discovery")

                    LazyVStack(spacing: 10) {
                        ForEach(visibleRemoteFestivalResults) { result in
                            ExternalFestivalResultRow(
                                result: result,
                                isImporting: importingRemoteResultID == result.id,
                                onAdd: {
                                    importRemoteFestival(result)
                                }
                            )
                        }
                    }
                }
                .padding(.top, searchResults.isEmpty ? 0 : 8)
            }
        }
    }

    @MainActor
    private func importRemoteFestival(_ result: ExternalFestivalSearchResult) {
        importingRemoteResultID = result.id

        do {
            let festival = try WristlistDataController.importDiscoveredFestival(result, context: modelContext)
            let importedFestivalName = FestivalSearchService.normalizedSearchText(festival.name)
            remoteFestivalResults.removeAll { remoteResult in
                FestivalSearchService.normalizedSearchText(remoteResult.title) == importedFestivalName
            }
            selectedImportedFestival = festival
            isShowingImportedFestival = true
        } catch {
            actionError = error.localizedDescription
        }

        importingRemoteResultID = nil
    }

    @MainActor
    private func toggleSaved(_ festival: WLFestival) {
        do {
            try WristlistDataController.toggleSave(festival, context: modelContext)
        } catch {
            actionError = error.localizedDescription
        }
    }

    @MainActor
    private func refreshRemoteFestivalResults(for query: String, debounce: Bool = true) async {
        let normalizedQuery = FestivalSearchService.normalizedSearchText(query)
        guard normalizedQuery.count >= FestivalExternalSearchService.minimumQueryLength else {
            remoteFestivalResults = []
            remoteSearchError = nil
            remoteSearchQuery = ""
            isRemoteSearchLoading = false
            return
        }

        let searchQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        remoteSearchQuery = searchQuery
        remoteSearchError = nil
        isRemoteSearchLoading = true

        do {
            if debounce {
                try await Task.sleep(nanoseconds: 350_000_000)
            }
            try Task.checkCancellation()

            let results = try await remoteSearchProvider.search(query: searchQuery, limit: 5)
            try Task.checkCancellation()

            remoteFestivalResults = results
            remoteSearchError = nil
        } catch is CancellationError {
            if FestivalSearchService.normalizedSearchText(remoteSearchQuery) == normalizedQuery {
                isRemoteSearchLoading = false
            }
            return
        } catch {
            remoteFestivalResults = []
            remoteSearchError = error.localizedDescription
        }

        if FestivalSearchService.normalizedSearchText(remoteSearchQuery) == normalizedQuery {
            isRemoteSearchLoading = false
        }
    }
}

private struct DiscoverySection: View {
    let title: String
    let subtitle: String
    let festivals: [WLFestival]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitleView(title: title, subtitle: subtitle)

            if festivals.isEmpty {
                EmptyStateView(title: "Nothing here yet", message: "This section updates from local festival data.", systemImage: "tray")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 18) {
                        ForEach(festivals.prefix(6)) { festival in
                            NavigationLink {
                                FestivalDetailView(festival: festival)
                            } label: {
                                DiscoveryFestivalCard(festival: festival)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 2)
                }
                .padding(.horizontal, -20)
            }
        }
    }
}

private struct DiscoveryFestivalCard: View {
    let festival: WLFestival

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            FestivalArtworkView(festival: festival)
                .frame(width: 214, height: 276)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(festival.name)
                        .font(.system(size: 22, weight: .black, design: .serif))
                        .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                        .lineLimit(2)
                        .minimumScaleFactor(0.70)
                    Spacer(minLength: 6)
                    Text(festival.communityRating, format: .number.precision(.fractionLength(1)))
                        .font(.title3.weight(.black))
                        .monospacedDigit()
                        .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                }

                Text("\(festival.cityState) / \(festival.dateRangeText)")
                    .font(WristlistTheme.metadataFont)
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                    .lineLimit(2)

                Text(festival.summary)
                    .font(.caption.weight(.semibold))
                    .lineSpacing(2)
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                    .lineLimit(2)
            }
        }
        .frame(width: 214, alignment: .topLeading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(festival.name), \(festival.cityState), \(festival.dateRangeText), rating \(festival.communityRating, specifier: "%.1f")")
    }
}

private struct FestivalSearchResultRow: View {
    let result: FestivalSearchResult
    let showsMatchReason: Bool

    @Environment(\.colorScheme) private var colorScheme

    private var festival: WLFestival { result.festival }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .center, spacing: 12) {
                FestivalCompactRow(
                    festival: festival,
                    trailingText: festival.communityRating > 0 ? festival.communityRating.formatted(.number.precision(.fractionLength(1))) : nil
                )

                if festival.status != .none && festival.status != .saved {
                    FestivalStatusBadge(status: festival.status, palette: festival.palette)
                        .frame(maxWidth: 96)
                }
            }

            if showsMatchReason {
                Text("\(result.matchKind.title) · \(result.matchDetail)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(result.matchKind == .artist ? WristlistTheme.coral : WristlistTheme.secondaryText(for: colorScheme))
                    .lineLimit(1)
                    .padding(.leading, 64)
            }
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(festival.festivalSeriesName), \(festival.editionYear) edition, \(festival.cityState), matched by \(result.matchKind.title.lowercased())")
    }
}

private struct ExternalFestivalResultRow: View {
    let result: ExternalFestivalSearchResult
    let isImporting: Bool
    let onAdd: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 13) {
            thumbnail

            VStack(alignment: .leading, spacing: 5) {
                Text(result.title)
                    .font(.system(size: 20, weight: .black, design: .serif))
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                    .lineLimit(2)
                    .minimumScaleFactor(0.84)

                Text(result.subtitle)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                    .lineLimit(1)

                Text(result.summary)
                    .font(.caption)
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                    .lineLimit(3)

                Text(result.sourceName)
                    .font(.caption2.weight(.black))
                    .foregroundStyle(WristlistTheme.coral)
                    .textCase(.uppercase)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 8) {
                Link(destination: result.sourceURL) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption.weight(.black))
                        .foregroundStyle(WristlistTheme.coral)
                        .frame(width: 34, height: 34)
                        .background(WristlistTheme.fieldFill(for: colorScheme), in: Circle())
                }
                .buttonStyle(.plain)
                .help("Open source")
                .accessibilityLabel("Open \(result.sourceName) source for \(result.title)")

                Button(action: onAdd) {
                    if isImporting {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Label("Add", systemImage: "plus")
                    }
                }
                .font(.caption.weight(.black))
                .foregroundStyle(.white)
                .frame(minWidth: 76, minHeight: 34)
                .background(WristlistTheme.coral.opacity(isImporting ? 0.68 : 1))
                .clipShape(RoundedRectangle(cornerRadius: WristlistTheme.cornerSmall, style: .continuous))
                .disabled(isImporting)
                .accessibilityLabel("Add \(result.title) to WristList")
            }
        }
            .padding(.vertical, 14)

            EditorialDivider()
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        AsyncImage(url: result.thumbnailURL) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                placeholderThumbnail
            @unknown default:
                placeholderThumbnail
            }
        }
        .frame(width: 70, height: 84)
        .background(WristlistTheme.fieldFill(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: WristlistTheme.cornerSmall, style: .continuous))
    }

    private var placeholderThumbnail: some View {
        Image(systemName: "music.mic")
            .font(.title3.weight(.bold))
            .foregroundStyle(WristlistTheme.coral)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct RemoteSearchStatusRow: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline.weight(.black))
                .foregroundStyle(WristlistTheme.coral)
                .frame(width: 42, height: 42)
                .background(WristlistTheme.fieldFill(for: colorScheme), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))

                Text(message)
                    .font(.caption)
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.caption.weight(.black))
                    .foregroundStyle(WristlistTheme.coral)
            }
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            EditorialDivider()
        }
        .accessibilityElement(children: .combine)
    }
}

private struct FilterChip: View {
    let title: String
    let systemImage: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(WristlistTheme.kickerFont)
            .tracking(0.6)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
            .frame(minHeight: 44)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(WristlistTheme.divider(for: colorScheme))
                    .frame(height: 1)
            }
    }
}

#Preview("Discover") {
    DiscoverView()
        .modelContainer(PreviewContainerFactory.makeContainer())
        .preferredColorScheme(.dark)
}
