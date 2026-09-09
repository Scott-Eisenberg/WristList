//
//  DiscoverView.swift
//  WristList
//

import SwiftData
import SwiftUI

struct DiscoverView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Query private var festivals: [WLFestival]

    @State private var filters = FestivalFilters()

    private var searchResults: [WLFestival] {
        FestivalSearchService.results(from: festivals, filters: filters)
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
                VStack(alignment: .leading, spacing: 22) {
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
                        DiscoverySection(title: "Trending", subtitle: "Festivals getting the most local attention", festivals: trendingFestivals)
                        DiscoverySection(title: "Near You", subtitle: "Los Angeles-friendly travel and local weekends", festivals: nearYouFestivals)
                        DiscoverySection(title: "Coming Soon", subtitle: "Upcoming dates sorted by start date", festivals: comingSoonFestivals)
                        DiscoverySection(title: "Recommended", subtitle: "Based on your saved genres and ranked history", festivals: recommendedFestivals)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .background(WristlistTheme.appBackground(for: colorScheme).ignoresSafeArea())
            .navigationTitle("Discover")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .searchable(text: $filters.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Festival, artist, city, venue, genre")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Find your next wristband")
                .font(.system(.largeTitle, design: .rounded).weight(.black))
                .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            Text("Search across festivals, cities, venues, genres, and sample lineup artists.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
        }
    }

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
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
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(WristlistTheme.coral)
                        .frame(minHeight: 44)
                        .padding(.horizontal, 10)
                        .accessibilityLabel("Clear filters")
                    }
                }
                .padding(.horizontal, 18)
            }
            .padding(.horizontal, -18)
        }
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitleView(title: "Results", subtitle: "\(searchResults.count) matching festivals")

            if searchResults.isEmpty {
                EmptyStateView(
                    title: "No matches",
                    message: "Try a broader search or clear filters to get back to discovery sections.",
                    systemImage: "magnifyingglass",
                    actionTitle: "Clear Filters",
                    action: { filters.clear() }
                )
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(searchResults) { festival in
                        NavigationLink {
                            FestivalDetailView(festival: festival)
                        } label: {
                            DiscoveryFestivalRow(festival: festival)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct DiscoverySection: View {
    let title: String
    let subtitle: String
    let festivals: [WLFestival]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitleView(title: title, subtitle: subtitle)

            if festivals.isEmpty {
                EmptyStateView(title: "Nothing here yet", message: "This section updates from local festival data.", systemImage: "tray")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(festivals.prefix(6)) { festival in
                            NavigationLink {
                                FestivalDetailView(festival: festival)
                            } label: {
                                DiscoveryFestivalCard(festival: festival)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 2)
                }
                .padding(.horizontal, -18)
            }
        }
    }
}

private struct DiscoveryFestivalCard: View {
    let festival: WLFestival

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            FestivalArtworkView(festival: festival)
                .frame(width: 204, height: 138)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(festival.name)
                        .font(.headline.weight(.black))
                        .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                        .lineLimit(1)
                    Spacer(minLength: 6)
                    Text(festival.communityRating, format: .number.precision(.fractionLength(1)))
                        .font(.subheadline.weight(.black))
                        .monospacedDigit()
                        .foregroundStyle(WristlistTheme.coral)
                }

                Text("\(festival.cityState) · \(festival.dateRangeText)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                    .lineLimit(1)

                Text(festival.summary)
                    .font(.caption)
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                    .lineLimit(2)
            }
        }
        .padding(10)
        .frame(width: 224)
        .background(WristlistTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(WristlistTheme.cardStroke(for: colorScheme), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(festival.name), \(festival.cityState), \(festival.dateRangeText), rating \(festival.communityRating, specifier: "%.1f")")
    }
}

private struct DiscoveryFestivalRow: View {
    let festival: WLFestival

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            FestivalCompactRow(festival: festival, trailingText: festival.communityRating.formatted(.number.precision(.fractionLength(1))))

            if festival.status != .none {
                FestivalStatusBadge(status: festival.status, palette: festival.palette)
                    .frame(maxWidth: 104)
            }
        }
        .padding(12)
        .background(WristlistTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(WristlistTheme.cardStroke(for: colorScheme), lineWidth: 1)
        }
    }
}

private struct FilterChip: View {
    let title: String
    let systemImage: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.bold))
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .background(WristlistTheme.cardFill(for: colorScheme), in: Capsule())
            .overlay {
                Capsule().strokeBorder(WristlistTheme.cardStroke(for: colorScheme), lineWidth: 1)
            }
    }
}

#Preview("Discover") {
    DiscoverView()
        .modelContainer(PreviewContainerFactory.makeContainer())
        .preferredColorScheme(.dark)
}
