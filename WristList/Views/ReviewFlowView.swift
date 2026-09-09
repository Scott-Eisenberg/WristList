//
//  ReviewFlowView.swift
//  WristList
//

import SwiftData
import SwiftUI

struct ReviewFlowView: View {
    let festivals: [WLFestival]
    let profile: WLProfile?
    let preselectedFestival: WLFestival?
    let existingReview: WLReview?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @State private var step: ReviewFlowStep = .festival
    @State private var searchText = ""
    @State private var selectedFestival: WLFestival?
    @State private var draft: ReviewDraft
    @State private var initialDraft: ReviewDraft
    @State private var showingDiscardConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var actionError: String?

    init(
        festivals: [WLFestival],
        profile: WLProfile?,
        preselectedFestival: WLFestival? = nil,
        existingReview: WLReview? = nil
    ) {
        self.festivals = festivals
        self.profile = profile
        self.preselectedFestival = preselectedFestival
        self.existingReview = existingReview

        var initialDraft = ReviewDraft.blank
        let initialFestival = preselectedFestival

        if let existingReview {
            initialDraft = ReviewDraft(
                festivalID: existingReview.festivalID,
                status: .attended,
                attendedDate: existingReview.attendedDate,
                overallScore: existingReview.overallScore,
                lineupScore: existingReview.lineupScore,
                productionScore: existingReview.productionScore,
                venueScore: existingReview.venueScore,
                organizationScore: existingReview.organizationScore,
                valueScore: existingReview.valueScore,
                reviewText: existingReview.reviewText,
                favoritePerformances: existingReview.favoritePerformances,
                isVisibleToFriends: existingReview.isVisibleToFriends
            )
        } else if let preselectedFestival {
            initialDraft.festivalID = preselectedFestival.id
            initialDraft.attendedDate = preselectedFestival.timing == .past ? preselectedFestival.endDate : .now
        }

        _selectedFestival = State(initialValue: initialFestival ?? festivals.first(where: { $0.id == initialDraft.festivalID }))
        _draft = State(initialValue: initialDraft)
        _initialDraft = State(initialValue: initialDraft)
    }

    private var filteredFestivals: [WLFestival] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return festivals.sorted { $0.startDate < $1.startDate }
        }

        var filters = FestivalFilters()
        filters.searchText = searchText
        return FestivalSearchService.results(from: festivals, filters: filters)
    }

    private var validationIssues: [ReviewValidationIssue] {
        var copy = draft
        copy.festivalID = selectedFestival?.id
        return RatingValidator.validationIssues(for: copy)
    }

    private var hasUnsavedChanges: Bool {
        draft != initialDraft || selectedFestival?.id != initialDraft.festivalID
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressHeader

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        stepContent
                    }
                    .padding(18)
                }

                footer
            }
            .background(WristlistTheme.appBackground(for: colorScheme).ignoresSafeArea())
            .navigationTitle(existingReview == nil ? "Log Festival" : "Edit Review")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { cancel() }
                }

                if existingReview != nil {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Delete", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                    }
                }
            }
            .confirmationDialog("Discard this review?", isPresented: $showingDiscardConfirmation, titleVisibility: .visible) {
                Button("Discard Changes", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) { }
            } message: {
                Text("Your festival selections and review text have not been saved.")
            }
            .confirmationDialog("Delete this review?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete Review", role: .destructive) { deleteReview() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This removes your review and clears the attended ranking for this festival.")
            }
            .alert("Could not save review", isPresented: Binding(get: { actionError != nil }, set: { if !$0 { actionError = nil } })) {
                Button("OK", role: .cancel) { actionError = nil }
            } message: {
                Text(actionError ?? "Try again.")
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .festival:
            festivalStep
        case .status:
            statusStep
        case .scores:
            scoresStep
        case .review:
            reviewTextStep
        case .summary:
            summaryStep
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ForEach(ReviewFlowStep.allCases) { flowStep in
                    Capsule()
                        .fill(flowStep.index <= step.index ? WristlistTheme.coral : WristlistTheme.cardStroke(for: colorScheme))
                        .frame(height: 5)
                }
            }
            Text(step.title)
                .font(.headline.weight(.black))
                .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }

    private var festivalStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Choose the festival this entry belongs to.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))

            TextField("Search festivals, artists, cities, venues, genres", text: $searchText)
                .textInputAutocapitalization(.words)
                .padding(12)
                .frame(minHeight: 44)
                .background(WristlistTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityLabel("Search festivals")

            if filteredFestivals.isEmpty {
                EmptyStateView(title: "No festival found", message: "Try a different festival, city, genre, venue, or artist.", systemImage: "magnifyingglass")
            } else {
                VStack(spacing: 10) {
                    ForEach(filteredFestivals) { festival in
                        Button {
                            selectedFestival = festival
                            draft.festivalID = festival.id
                        } label: {
                            HStack(spacing: 12) {
                                FestivalCompactRow(festival: festival)
                                Image(systemName: selectedFestival?.id == festival.id ? "checkmark.circle.fill" : "circle")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(selectedFestival?.id == festival.id ? WristlistTheme.coral : WristlistTheme.secondaryText(for: colorScheme))
                            }
                            .padding(12)
                            .background(WristlistTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(selectedFestival?.id == festival.id ? WristlistTheme.coral.opacity(0.75) : WristlistTheme.cardStroke(for: colorScheme), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Select \(festival.name)")
                    }
                }
            }
        }
    }

    private var statusStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Add it to your history or save it as a future weekend.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))

            VStack(spacing: 10) {
                statusButton(.attended, detail: "Rank it, score it, and optionally write a review.")
                statusButton(.wantToGo, detail: "Save it to your future festival list without publishing a review yet.")
            }

            if draft.status == .attended {
                DatePicker("Date attended", selection: Binding(get: { draft.attendedDate ?? .now }, set: { draft.attendedDate = $0 }), displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding(12)
                    .background(WristlistTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityLabel("Date attended")
            }
        }
    }

    private var scoresStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(draft.status == .attended ? "Score the festival from 0 to 10." : "Optional preview scores are saved only if you mark the festival attended.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))

            VStack(spacing: 12) {
                ScoreSlider(title: "Overall", score: $draft.overallScore, palette: selectedFestival?.palette ?? .sunset)
                ScoreSlider(title: "Lineup", score: $draft.lineupScore, palette: selectedFestival?.palette ?? .sunset)
                ScoreSlider(title: "Production", score: $draft.productionScore, palette: selectedFestival?.palette ?? .sunset)
                ScoreSlider(title: "Venue", score: $draft.venueScore, palette: selectedFestival?.palette ?? .sunset)
                ScoreSlider(title: "Organization", score: $draft.organizationScore, palette: selectedFestival?.palette ?? .sunset)
                ScoreSlider(title: "Value", score: $draft.valueScore, palette: selectedFestival?.palette ?? .sunset)
            }
        }
    }

    private var reviewTextStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Add the details friends actually care about: sound, crowds, logistics, and performances.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))

            TextEditor(text: $draft.reviewText)
                .frame(minHeight: 136)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(WristlistTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(WristlistTheme.cardStroke(for: colorScheme), lineWidth: 1)
                }
                .accessibilityLabel("Review text")

            if let selectedFestival, !selectedFestival.lineup.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Favorite performances")
                        .font(.headline.weight(.black))
                        .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(selectedFestival.lineup, id: \.self) { artist in
                            favoritePerformanceButton(artist)
                        }
                    }
                }
            }

            Toggle("Visible to friends", isOn: $draft.isVisibleToFriends)
                .font(.subheadline.weight(.bold))
                .padding(12)
                .background(WristlistTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityLabel("Review visible to friends")
        }
    }

    private var summaryStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let selectedFestival {
                FestivalCompactRow(festival: selectedFestival, trailingText: draft.status.title)
                    .padding(12)
                    .background(WristlistTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(WristlistTheme.cardStroke(for: colorScheme), lineWidth: 1)
                    }
            }

            VStack(alignment: .leading, spacing: 10) {
                ScoreSummaryRow(title: "Overall", score: draft.overallScore)
                ScoreSummaryRow(title: "Lineup", score: draft.lineupScore)
                ScoreSummaryRow(title: "Production", score: draft.productionScore)
                ScoreSummaryRow(title: "Venue", score: draft.venueScore)
                ScoreSummaryRow(title: "Organization", score: draft.organizationScore)
                ScoreSummaryRow(title: "Value", score: draft.valueScore)
            }
            .padding(12)
            .background(WristlistTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            if !draft.reviewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(draft.reviewText)
                    .font(.body)
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(WristlistTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            if !validationIssues.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(validationIssues) { issue in
                        Label(issue.message, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(WristlistTheme.coral)
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button(step == .festival ? "Cancel" : "Back") {
                if step == .festival {
                    cancel()
                } else {
                    step = step.previous
                }
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background(WristlistTheme.cardFill(for: colorScheme), in: Capsule())
            .accessibilityLabel(step == .festival ? "Cancel review" : "Go back")

            Button(step == .summary ? "Save" : "Next") {
                if step == .summary {
                    save()
                } else {
                    step = step.next
                }
            }
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background(nextButtonDisabled ? disabledGradient : WristlistTheme.gradient(for: selectedFestival?.palette ?? .sunset), in: Capsule())
            .disabled(nextButtonDisabled)
            .accessibilityLabel(step == .summary ? "Save review" : "Continue")
        }
        .padding(18)
        .background(.ultraThinMaterial)
    }

    private var nextButtonDisabled: Bool {
        if step == .festival {
            return selectedFestival == nil
        }
        if step == .summary {
            return !validationIssues.isEmpty || profile == nil
        }
        return false
    }

    private var disabledGradient: LinearGradient {
        LinearGradient(colors: [Color.gray.opacity(0.45), Color.gray.opacity(0.30)], startPoint: .leading, endPoint: .trailing)
    }

    private func statusButton(_ status: AttendanceStatus, detail: String) -> some View {
        Button {
            draft.status = status
            if status == .attended && draft.attendedDate == nil {
                draft.attendedDate = selectedFestival?.endDate ?? .now
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: status.systemImage)
                    .font(.title3.weight(.black))
                    .foregroundStyle(draft.status == status ? .white : WristlistTheme.coral)
                    .frame(width: 44, height: 44)
                    .background(draft.status == status ? WristlistTheme.gradient(for: selectedFestival?.palette ?? .sunset) : LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(status.title)
                        .font(.headline.weight(.black))
                        .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(12)
            .background(WristlistTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(draft.status == status ? WristlistTheme.coral.opacity(0.75) : WristlistTheme.cardStroke(for: colorScheme), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Mark as \(status.title)")
    }

    private func favoritePerformanceButton(_ artist: String) -> some View {
        let isSelected = draft.favoritePerformances.contains(artist)

        return Button {
            if isSelected {
                draft.favoritePerformances.removeAll { $0 == artist }
            } else {
                draft.favoritePerformances.append(artist)
            }
        } label: {
            Label(artist, systemImage: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.caption.weight(.bold))
                .lineLimit(2)
                .minimumScaleFactor(0.78)
                .foregroundStyle(isSelected ? .white : WristlistTheme.primaryText(for: colorScheme))
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(isSelected ? WristlistTheme.gradient(for: selectedFestival?.palette ?? .sunset) : LinearGradient(colors: [WristlistTheme.cardFill(for: colorScheme)], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isSelected ? "Remove \(artist) from favorite performances" : "Add \(artist) to favorite performances")
    }

    private func cancel() {
        if hasUnsavedChanges {
            showingDiscardConfirmation = true
        } else {
            dismiss()
        }
    }

    private func save() {
        guard let selectedFestival, let profile else {
            actionError = "Your local profile is not ready yet."
            return
        }

        do {
            draft.festivalID = selectedFestival.id
            try WristlistDataController.saveReview(
                draft: draft,
                festival: selectedFestival,
                profile: profile,
                existingReview: existingReview,
                context: modelContext
            )
            dismiss()
        } catch let issue as ReviewValidationIssue {
            actionError = issue.message
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func deleteReview() {
        guard let existingReview else { return }

        do {
            try WristlistDataController.deleteReview(existingReview, festivals: festivals, context: modelContext)
            dismiss()
        } catch {
            actionError = error.localizedDescription
        }
    }
}

private enum ReviewFlowStep: String, CaseIterable, Identifiable {
    case festival
    case status
    case scores
    case review
    case summary

    var id: String { rawValue }

    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }

    var title: String {
        switch self {
        case .festival:
            "Festival"
        case .status:
            "Attendance"
        case .scores:
            "Ratings"
        case .review:
            "Review"
        case .summary:
            "Confirm"
        }
    }

    var next: ReviewFlowStep {
        let allCases = Self.allCases
        return allCases[min(index + 1, allCases.count - 1)]
    }

    var previous: ReviewFlowStep {
        let allCases = Self.allCases
        return allCases[max(index - 1, 0)]
    }
}

private struct ScoreSlider: View {
    let title: String
    @Binding var score: Double
    let palette: FestivalPalette

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                Spacer()
                Text(score, format: .number.precision(.fractionLength(1)))
                    .font(.headline.weight(.black))
                    .monospacedDigit()
                    .foregroundStyle(WristlistTheme.coral)
            }

            Slider(value: $score, in: 0...10, step: 0.1)
                .tint(WristlistTheme.colors(for: palette).first ?? WristlistTheme.coral)
                .accessibilityLabel(title)
                .accessibilityValue("\(score, specifier: "%.1f") out of 10")
        }
        .padding(12)
        .background(WristlistTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ScoreSummaryRow: View {
    let title: String
    let score: Double

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
            Spacer()
            Text(score, format: .number.precision(.fractionLength(1)))
                .font(.subheadline.weight(.black))
                .monospacedDigit()
                .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
        }
    }
}

#Preview("Review Flow") {
    let container = PreviewContainerFactory.makeContainer()
    let context = container.mainContext
    let festivals = (try? context.fetch(FetchDescriptor<WLFestival>())) ?? []
    let profiles = (try? context.fetch(FetchDescriptor<WLProfile>())) ?? []

    ReviewFlowView(festivals: festivals, profile: profiles.first)
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
