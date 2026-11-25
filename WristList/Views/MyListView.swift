//
//  MyListView.swift
//  WristList
//

import SwiftData
import SwiftUI

struct MyListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var festivals: [WLFestival]

    @State private var selectedSection: MyListSection = .ranked
    @State private var sortOption: FestivalSortOption = .ranking
    @State private var genreFilter = "All"
    @State private var actionError: String?

    private var availableGenres: [String] {
        FestivalSearchService.availableGenres(from: festivals)
    }

    private var filteredFestivals: [WLFestival] {
        let sectionFestivals = festivals.filter { festival in
            switch selectedSection {
            case .ranked:
                return festival.status == .attended
            case .attended:
                return festival.status == .attended
            case .wantToGo:
                return festival.status == .wantToGo
            case .saved:
                return festival.isSaved
            }
        }
        let genreFiltered = genreFilter == "All" ? sectionFestivals : sectionFestivals.filter { $0.genres.contains(genreFilter) }
        return selectedSection == .ranked ? RankingService.rankedFestivals(from: genreFiltered) : FestivalSearchService.sorted(genreFiltered, by: sortOption)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    segmentedControl
                    controls
                    listContent
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 34)
            }
            .background(WristlistTheme.appBackground(for: colorScheme).ignoresSafeArea())
            .navigationTitle("My List")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
        }
        .alert("List update failed", isPresented: Binding(get: { actionError != nil }, set: { if !$0 { actionError = nil } })) {
            Button("OK", role: .cancel) { actionError = nil }
        } message: {
            Text(actionError ?? "Try again.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Your festival shelf")
                .font(WristlistTheme.pageTitleFont)
                .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                .lineLimit(2)
                .minimumScaleFactor(0.76)

            Text("Rank attended weekends, track saved festivals, and keep future plans organized.")
                .font(.body)
                .lineSpacing(3)
                .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
        }
    }

    private var segmentedControl: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 18) {
                ForEach(MyListSection.allCases) { section in
                    Button {
                        selectedSection = section
                    } label: {
                        VStack(alignment: .leading, spacing: 7) {
                            Text(section.title.uppercased())
                                .font(WristlistTheme.kickerFont)
                                .tracking(1.0)

                            Rectangle()
                                .fill(selectedSection == section ? WristlistTheme.brand : WristlistTheme.divider(for: colorScheme))
                                .frame(width: selectedSection == section ? 42 : 24, height: 3)
                        }
                        .foregroundStyle(selectedSection == section ? WristlistTheme.primaryText(for: colorScheme) : WristlistTheme.secondaryText(for: colorScheme))
                        .frame(minHeight: 44, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, -20)
        .accessibilityLabel("Choose list section")
        .onChange(of: selectedSection) { _, newSection in
            sortOption = newSection == .ranked ? .ranking : .date
        }
    }

    private var controls: some View {
        HStack(spacing: 18) {
            Menu {
                Picker("Sort", selection: $sortOption) {
                    ForEach(sortOptions) { option in
                        Text(option.title).tag(option)
                    }
                }
            } label: {
                Label(sortOption.title, systemImage: "arrow.up.arrow.down")
                    .font(WristlistTheme.kickerFont)
                    .tracking(0.7)
                    .frame(minHeight: 44)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(WristlistTheme.divider(for: colorScheme))
                            .frame(height: 1)
                    }
            }
            .disabled(selectedSection == .ranked)
            .opacity(selectedSection == .ranked ? 0.55 : 1)

            Menu {
                Picker("Genre", selection: $genreFilter) {
                    ForEach(availableGenres, id: \.self) { genre in
                        Text(genre).tag(genre)
                    }
                }
            } label: {
                Label(genreFilter, systemImage: "waveform")
                    .font(WristlistTheme.kickerFont)
                    .tracking(0.7)
                    .frame(minHeight: 44)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(WristlistTheme.divider(for: colorScheme))
                            .frame(height: 1)
                    }
            }

            Spacer()

            if genreFilter != "All" {
                Button("Clear") { genreFilter = "All" }
                    .font(WristlistTheme.kickerFont)
                    .tracking(0.7)
                    .foregroundStyle(WristlistTheme.coral)
                    .frame(minHeight: 44)
            }
        }
        .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
    }

    @ViewBuilder
    private var listContent: some View {
        if filteredFestivals.isEmpty {
            EmptyStateView(
                title: selectedSection.emptyTitle,
                message: selectedSection.emptyMessage,
                systemImage: selectedSection.systemImage
            )
        } else {
            LazyVStack(spacing: 0) {
                ForEach(Array(filteredFestivals.enumerated()), id: \.element.id) { index, festival in
                    NavigationLink {
                        FestivalDetailView(festival: festival)
                    } label: {
                        if selectedSection == .ranked {
                            RankedFestivalRowView(
                                festival: festival,
                                canMoveUp: index > 0,
                                canMoveDown: index < filteredFestivals.count - 1,
                                moveUp: { moveFestival(festival, direction: .up) },
                                moveDown: { moveFestival(festival, direction: .down) }
                            )
                        } else {
                            MyListFestivalRow(festival: festival, section: selectedSection)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var sortOptions: [FestivalSortOption] {
        [.date, .rating, .name]
    }

    private func moveFestival(_ festival: WLFestival, direction: MoveDirection) {
        do {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                RankingService.moveFestival(festival, direction: direction, in: festivals)
            }
            try WristlistDataController.saveIfNeeded(modelContext)
        } catch {
            actionError = error.localizedDescription
        }
    }
}

private enum MyListSection: String, CaseIterable, Identifiable {
    case ranked
    case attended
    case wantToGo
    case saved

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ranked:
            "Ranked"
        case .attended:
            "Attended"
        case .wantToGo:
            "Want"
        case .saved:
            "Saved"
        }
    }

    var systemImage: String {
        switch self {
        case .ranked:
            "list.number"
        case .attended:
            "checkmark.seal"
        case .wantToGo:
            "sparkles"
        case .saved:
            "bookmark"
        }
    }

    var emptyTitle: String {
        switch self {
        case .ranked:
            "No ranked festivals"
        case .attended:
            "No attended festivals"
        case .wantToGo:
            "No want-to-go festivals"
        case .saved:
            "No saved festivals"
        }
    }

    var emptyMessage: String {
        switch self {
        case .ranked:
            "Mark a festival attended and write a review to start your personal ranking."
        case .attended:
            "Festivals you mark attended will appear here."
        case .wantToGo:
            "Use Discover to save future weekends to this list."
        case .saved:
            "Tap Save on festivals or reviews to build a planning queue."
        }
    }
}

private struct MyListFestivalRow: View {
    let festival: WLFestival
    let section: MyListSection

    @Environment(\.colorScheme) private var colorScheme

    @MainActor
    private var trailingText: String {
        switch section {
        case .ranked:
            "#\(festival.personalRank)"
        case .attended:
            festival.attendedDate.map(DateFormatting.monthYear) ?? "Attended"
        case .wantToGo:
            festival.dateRangeText
        case .saved:
            festival.status.title
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                FestivalCompactRow(festival: festival)

                VStack(alignment: .trailing, spacing: 3) {
                    Image(systemName: section.systemImage)
                        .font(.system(size: 14, weight: .black))
                    Text(trailingText)
                        .font(WristlistTheme.kickerFont)
                        .tracking(0.4)
                        .lineLimit(2)
                        .minimumScaleFactor(0.70)
                        .multilineTextAlignment(.trailing)
                }
                .foregroundStyle(WristlistTheme.accent(for: festival.palette))
                .frame(width: 72, alignment: .trailing)
            }
            .padding(.vertical, 12)

            EditorialDivider()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(festival.name), \(section.title), \(trailingText)")
    }
}

#Preview("My List") {
    MyListView()
        .modelContainer(PreviewContainerFactory.makeContainer())
        .preferredColorScheme(.dark)
}
