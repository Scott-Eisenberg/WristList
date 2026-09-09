//
//  FestivalDetailView.swift
//  WristList
//

import SwiftData
import SwiftUI

struct FestivalDetailView: View {
    let festival: WLFestival

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var reviews: [WLReview]
    @Query private var comments: [WLComment]
    @Query private var profiles: [WLProfile]

    @State private var isShowingReviewFlow = false
    @State private var actionError: String?

    private var profile: WLProfile? {
        profiles.first { $0.id == WristlistDataController.currentUserID } ?? profiles.first
    }

    private var festivalReviews: [WLReview] {
        reviews
            .filter { $0.festivalID == festival.id && $0.isVisibleToFriends }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var currentUserReview: WLReview? {
        reviews.first { $0.festivalID == festival.id && $0.isCurrentUser }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                hero
                actionStrip
                descriptionSection
                ratingBreakdown
                lineupSection
                friendsSection
                reviewsSection
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(WristlistTheme.appBackground(for: colorScheme).ignoresSafeArea())
        .navigationTitle(festival.name)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .sheet(isPresented: $isShowingReviewFlow) {
            ReviewFlowView(festivals: [festival], profile: profile, preselectedFestival: festival, existingReview: currentUserReview)
        }
        .alert("Festival update failed", isPresented: Binding(get: { actionError != nil }, set: { if !$0 { actionError = nil } })) {
            Button("OK", role: .cancel) { actionError = nil }
        } message: {
            Text(actionError ?? "Try again.")
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            FestivalArtworkView(festival: festival)
                .frame(height: 210)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(alignment: .topLeading) {
                    FestivalStatusBadge(status: festival.status, palette: festival.palette)
                        .padding(12)
                }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(festival.name)
                        .font(.system(.largeTitle, design: .rounded).weight(.black))
                        .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                        .lineLimit(2)
                        .minimumScaleFactor(0.76)

                    Spacer(minLength: 8)

                    ScoreBadge(score: festival.communityRating, palette: festival.palette, label: "Community rating")
                }

                VStack(alignment: .leading, spacing: 5) {
                    Label("\(festival.dateRangeText) · \(festival.timing.title)", systemImage: "calendar")
                    Label("\(festival.venue), \(festival.cityState)", systemImage: "mappin.and.ellipse")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))

                HStack(spacing: 7) {
                    ForEach(festival.genres.prefix(4), id: \.self) { genre in
                        WristbandTag(text: genre, palette: festival.palette)
                    }
                }
            }
        }
    }

    private var actionStrip: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                detailActionButton(
                    title: festival.isSaved ? "Saved" : "Save",
                    systemImage: festival.isSaved ? "bookmark.fill" : "bookmark",
                    isPrimary: festival.isSaved,
                    action: toggleSave
                )

                detailActionButton(
                    title: festival.status == .attended ? "Attended" : "Attended",
                    systemImage: festival.status == .attended ? "checkmark.seal.fill" : "checkmark.seal",
                    isPrimary: festival.status == .attended,
                    action: markAttended
                )

                ShareLink(item: "\(festival.name) on Wristlist · \(festival.cityState) · \(festival.dateRangeText)") {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .background(WristlistTheme.cardFill(for: colorScheme), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Share \(festival.name)")
            }

            Button {
                isShowingReviewFlow = true
            } label: {
                Label(currentUserReview == nil ? "Write Review" : "Edit Your Review", systemImage: currentUserReview == nil ? "square.and.pencil" : "pencil")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 50)
                    .background(WristlistTheme.gradient(for: .sunset), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(currentUserReview == nil ? "Write review" : "Edit your review")
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitleView(title: "Overview")
            Text(festival.detailDescription)
                .font(.body)
                .lineSpacing(2)
                .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
        }
    }

    private var ratingBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitleView(title: "Community Breakdown", subtitle: "Based on \(festival.communityReviewCount) local sample reviews")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(festival.categoryScores) { score in
                    CategoryScoreView(score: score, palette: festival.palette)
                }
            }
        }
    }

    private var lineupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitleView(title: "Lineup", subtitle: "Artists people are tracking")

            VStack(spacing: 0) {
                ForEach(Array(festival.lineup.enumerated()), id: \.element) { index, artist in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption.weight(.black))
                            .monospacedDigit()
                            .foregroundStyle(WristlistTheme.coral)
                            .frame(width: 24)
                        Text(artist)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                        Spacer()
                    }
                    .padding(.vertical, 11)

                    if index < festival.lineup.count - 1 {
                        Divider().overlay(WristlistTheme.cardStroke(for: colorScheme))
                    }
                }
            }
            .padding(.horizontal, 12)
            .background(WristlistTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(WristlistTheme.cardStroke(for: colorScheme), lineWidth: 1)
            }
        }
    }

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitleView(title: "Friends", subtitle: festival.friendNames.isEmpty ? "No friend activity yet" : "Attended or saved by your circle")

            if festival.friendNames.isEmpty {
                EmptyStateView(title: "No friend activity", message: "Friends who save or review this festival will appear here.", systemImage: "person.2")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(festival.friendNames, id: \.self) { name in
                            friendChip(name: name)
                        }
                    }
                    .padding(.horizontal, 18)
                }
                .padding(.horizontal, -18)
            }
        }
    }

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitleView(title: "Reviews", subtitle: "What people noticed after attending")

            if festivalReviews.isEmpty {
                EmptyStateView(
                    title: "No reviews yet",
                    message: "Be the first to record a full Wristlist review for this festival.",
                    systemImage: "text.bubble",
                    actionTitle: "Write Review",
                    action: { isShowingReviewFlow = true }
                )
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(festivalReviews) { review in
                        ReviewCardView(review: review, festival: festival, profile: profile, comments: comments)
                    }
                }
            }
        }
    }

    private func detailActionButton(title: String, systemImage: String, isPrimary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .foregroundStyle(isPrimary ? .white : WristlistTheme.primaryText(for: colorScheme))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .background(isPrimary ? WristlistTheme.gradient(for: festival.palette) : LinearGradient(colors: [WristlistTheme.cardFill(for: colorScheme)], startPoint: .leading, endPoint: .trailing), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private func friendChip(name: String) -> some View {
        HStack(spacing: 8) {
            AvatarCircle(initials: String(name.prefix(1)), palette: festival.palette, size: 34, fontSize: 12)
            Text(name)
                .font(.caption.weight(.black))
                .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .frame(height: 44)
        .background(WristlistTheme.cardFill(for: colorScheme), in: Capsule())
        .overlay {
            Capsule().strokeBorder(WristlistTheme.cardStroke(for: colorScheme), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private func toggleSave() {
        do {
            try WristlistDataController.toggleSave(festival, context: modelContext)
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func markAttended() {
        do {
            let newStatus: AttendanceStatus = festival.status == .attended ? .saved : .attended
            try WristlistDataController.updateAttendance(festival, status: newStatus, context: modelContext)
        } catch {
            actionError = error.localizedDescription
        }
    }
}

#Preview("Festival Detail") {
    let container = PreviewContainerFactory.makeContainer()
    let context = container.mainContext
    let festivals = (try? context.fetch(FetchDescriptor<WLFestival>())) ?? []

    NavigationStack {
        if let festival = festivals.first {
            FestivalDetailView(festival: festival)
        }
    }
    .modelContainer(container)
    .preferredColorScheme(.dark)
}
