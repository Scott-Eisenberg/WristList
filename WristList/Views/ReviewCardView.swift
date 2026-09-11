//
//  ReviewCardView.swift
//  WristList
//

import SwiftData
import SwiftUI

struct ReviewCardView: View {
    let review: WLReview
    let festival: WLFestival
    let profile: WLProfile?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var isShowingComments = false
    @State private var actionError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                NavigationLink {
                    UserProfileDetailView(review: review)
                } label: {
                    AvatarCircle(initials: review.userInitials, palette: review.userPalette, size: 44, fontSize: 14)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open \(review.userName)'s profile")

                VStack(alignment: .leading, spacing: 3) {
                    NavigationLink {
                        UserProfileDetailView(review: review)
                    } label: {
                        Text(review.userName)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                    }
                    .buttonStyle(.plain)

                    Text("\(review.userHandle) reviewed \(festival.name)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                ScoreBadge(score: review.overallScore, palette: festival.palette)
            }

            NavigationLink {
                FestivalDetailView(festival: festival)
            } label: {
                FestivalReviewSummary(review: review, festival: festival)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open \(festival.name) details")

            CategoryScoresGrid(scores: review.categoryScores, palette: festival.palette)

            if !review.favoritePerformances.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Favorite performances")
                        .font(.caption.weight(.black))
                        .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                    Text(review.favoritePerformances.joined(separator: " / "))
                        .font(.caption)
                        .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                        .lineLimit(2)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Favorite performances: \(review.favoritePerformances.joined(separator: ", "))")
            }

            ReviewActionBar(
                review: review,
                festival: festival,
                onLike: toggleLike,
                onComment: { isShowingComments = true },
                onSave: toggleSave
            )
        }
        .padding(14)
        .background(WristlistTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(WristlistTheme.cardStroke(for: colorScheme), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .sheet(isPresented: $isShowingComments) {
            CommentsSheet(review: review, profile: profile)
        }
        .alert("Could not update review", isPresented: Binding(get: { actionError != nil }, set: { if !$0 { actionError = nil } })) {
            Button("OK", role: .cancel) { actionError = nil }
        } message: {
            Text(actionError ?? "Try again.")
        }
    }

    private func toggleLike() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.70)) {
            do {
                try WristlistDataController.toggleLike(review, context: modelContext)
            } catch {
                actionError = error.localizedDescription
            }
        }
    }

    private func toggleSave() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.76)) {
            do {
                try WristlistDataController.toggleSave(festival, context: modelContext)
            } catch {
                actionError = error.localizedDescription
            }
        }
    }
}

private struct FestivalReviewSummary: View {
    let review: WLReview
    let festival: WLFestival

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                FestivalArtworkView(festival: festival)
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(festival.name)
                            .font(.headline.weight(.black))
                            .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)

                        Label(festival.cityState, systemImage: "mappin.and.ellipse")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                            .lineLimit(1)

                        Label(DateFormatting.monthYear(review.attendedDate), systemImage: "calendar")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                            .lineLimit(1)
                    }

                    HStack(spacing: 6) {
                        ForEach(festival.genres.prefix(3), id: \.self) { tag in
                            WristbandTag(text: tag, palette: festival.palette)
                        }
                    }
                }
            }

            Text(review.reviewText.isEmpty ? "Logged this festival without a written review." : review.reviewText)
                .font(.subheadline)
                .lineSpacing(2)
                .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Review: \(review.reviewText)")
        }
    }
}

private struct CategoryScoresGrid: View {
    let scores: [ReviewCategoryScore]
    let palette: FestivalPalette

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(scores) { score in
                CategoryScoreView(score: score, palette: palette)
            }
        }
    }
}

private struct ReviewActionBar: View {
    let review: WLReview
    let festival: WLFestival
    let onLike: () -> Void
    let onComment: () -> Void
    let onSave: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            ReviewActionButton(
                title: "\(review.likeCount)",
                systemImage: review.isLiked ? "heart.fill" : "heart",
                isActive: review.isLiked,
                accessibilityLabel: review.isLiked ? "Unlike review" : "Like review",
                action: onLike
            )

            ReviewActionButton(
                title: "\(review.commentCount)",
                systemImage: "bubble.left",
                isActive: false,
                accessibilityLabel: "Comment on review",
                action: onComment
            )

            ShareLink(item: "Check out \(review.userName)'s Wristlist review of \(festival.name): \(review.overallScore.formatted(.number.precision(.fractionLength(1))))/10") {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background(WristlistTheme.tertiaryFill(for: colorScheme), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Share review")

            Spacer(minLength: 0)

            ReviewActionButton(
                title: festival.isSaved ? "Saved" : "Save",
                systemImage: festival.isSaved ? "bookmark.fill" : "bookmark",
                isActive: festival.isSaved,
                accessibilityLabel: festival.isSaved ? "Remove \(festival.name) from saved festivals" : "Save \(festival.name)",
                action: onSave
            )
        }
        .padding(.top, 2)
    }
}

private struct ReviewActionButton: View {
    let title: String
    let systemImage: String
    let isActive: Bool
    let accessibilityLabel: String
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .foregroundStyle(isActive ? WristlistTheme.coral : WristlistTheme.secondaryText(for: colorScheme))
                .padding(.horizontal, 12)
                .frame(height: 36)
                .background(WristlistTheme.tertiaryFill(for: colorScheme), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct CommentsSheet: View {
    let review: WLReview
    let profile: WLProfile?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allComments: [WLComment]
    @State private var commentText = ""
    @State private var actionError: String?

    private var comments: [WLComment] {
        allComments
            .filter { $0.reviewID == review.id }
            .sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            List {
                if comments.isEmpty {
                    ContentUnavailableView {
                        Label("No comments yet", systemImage: "bubble.left")
                    } description: {
                        Text("Start the conversation about this review.")
                    }
                } else {
                    ForEach(comments) { comment in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                AvatarCircle(initials: comment.userInitials, palette: .violet, size: 32, fontSize: 11)
                                Text(comment.userName)
                                    .font(.subheadline.weight(.bold))
                                Spacer()
                                Text(DateFormatting.shortDate(comment.createdAt))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(comment.text)
                                .font(.body)
                        }
                        .padding(.vertical, 4)
                        .accessibilityElement(children: .combine)
                    }
                }

                Section("Add comment") {
                    TextField("Add a comment", text: $commentText, axis: .vertical)
                        .lineLimit(2...4)
                        .accessibilityLabel("Comment text")

                    Button("Post Comment") {
                        addComment()
                    }
                    .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || profile == nil)
                    .accessibilityLabel("Post comment")
                }
            }
            .navigationTitle("Comments")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Could not post comment", isPresented: Binding(get: { actionError != nil }, set: { if !$0 { actionError = nil } })) {
                Button("OK", role: .cancel) { actionError = nil }
            } message: {
                Text(actionError ?? "Try again.")
            }
        }
    }

    private func addComment() {
        guard let profile else { return }

        do {
            try WristlistDataController.addComment(text: commentText, to: review, profile: profile, context: modelContext)
            commentText = ""
        } catch {
            actionError = error.localizedDescription
        }
    }
}

#Preview("Review Card") {
    let container = PreviewContainerFactory.makeContainer()
    let context = container.mainContext
    let festivals = (try? context.fetch(FetchDescriptor<WLFestival>())) ?? []
    let reviews = (try? context.fetch(FetchDescriptor<WLReview>())) ?? []
    let profiles = (try? context.fetch(FetchDescriptor<WLProfile>())) ?? []
    let review = reviews.first
    let festival = review.flatMap { selectedReview in festivals.first { $0.id == selectedReview.festivalID } }

    ZStack {
        WristlistTheme.appBackground(for: .dark)
            .ignoresSafeArea()

        if let review, let festival {
            ReviewCardView(review: review, festival: festival, profile: profiles.first)
                .padding()
        }
    }
    .modelContainer(container)
    .preferredColorScheme(.dark)
}
