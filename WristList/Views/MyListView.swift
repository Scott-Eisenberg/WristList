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
                VStack(alignment: .leading, spacing: 20) {
                    header
                    segmentedControl
                    controls
                    listContent
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 28)
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
                .font(.title2.weight(.bold))
                .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                .lineLimit(2)

            Text("Rank attended weekends, track saved festivals, and keep future plans organized.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
        }
    }

    private var segmentedControl: some View {
        Picker("List section", selection: $selectedSection) {
            ForEach(MyListSection.allCases) { section in
                Text(section.title).tag(section)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Choose list section")
        .onChange(of: selectedSection) { _, newSection in
            sortOption = newSection == .ranked ? .ranking : .date
        }
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Menu {
                Picker("Sort", selection: $sortOption) {
                    ForEach(sortOptions) { option in
                        Text(option.title).tag(option)
                    }
                }
            } label: {
                Label(sortOption.title, systemImage: "arrow.up.arrow.down")
                    .font(.subheadline.weight(.bold))
                    .frame(minHeight: 44)
                    .padding(.horizontal, 12)
                    .background(WristlistTheme.cardFill(for: colorScheme), in: Capsule())
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
                    .font(.subheadline.weight(.bold))
                    .frame(minHeight: 44)
                    .padding(.horizontal, 12)
                    .background(WristlistTheme.cardFill(for: colorScheme), in: Capsule())
            }

            Spacer()

            if genreFilter != "All" {
                Button("Clear") { genreFilter = "All" }
                    .font(.subheadline.weight(.bold))
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
            LazyVStack(spacing: 10) {
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
        HStack(spacing: 12) {
            FestivalCompactRow(festival: festival)

            VStack(spacing: 6) {
                Image(systemName: section.systemImage)
                    .font(.system(size: 14, weight: .black))
                Text(trailingText)
                    .font(.caption2.weight(.black))
                    .lineLimit(2)
                    .minimumScaleFactor(0.70)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(.white)
            .frame(width: 64, height: 54)
            .background(WristlistTheme.gradient(for: festival.palette), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(12)
        .background(WristlistTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(WristlistTheme.cardStroke(for: colorScheme), lineWidth: 1)
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
