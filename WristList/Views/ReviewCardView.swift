//
//  ReviewCardView.swift
//  WristList
//

import SwiftUI

struct ReviewCardView: View {
    let review: FestivalReview

    @Environment(\.colorScheme) private var colorScheme
    @State private var isLiked = false
    @State private var isSaved: Bool
    @State private var likeCount: Int

    init(review: FestivalReview) {
        self.review = review
        _isSaved = State(initialValue: review.isSaved)
        _likeCount = State(initialValue: review.likes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Text(review.user.initials)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(WristlistTheme.gradient(for: review.user.palette), in: Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(review.user.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))

                    Text("\(review.user.handle) reviewed \(review.festival.name)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                ScoreBadge(score: review.overallScore, palette: review.festival.palette)
            }

            FestivalReviewSummary(review: review)

            CategoryScoresGrid(scores: review.categoryScores, palette: review.festival.palette)

            ReviewActionBar(
                likeCount: likeCount,
                commentCount: review.comments,
                isLiked: isLiked,
                isSaved: isSaved,
                onLike: toggleLike,
                onComment: { },
                onSave: toggleSave
            )
        }
        .padding(16)
        .background(WristlistTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(WristlistTheme.cardStroke(for: colorScheme), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }

    private func toggleLike() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.70)) {
            isLiked.toggle()
            likeCount += isLiked ? 1 : -1
        }
    }

    private func toggleSave() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.76)) {
            isSaved.toggle()
        }
    }
}

private struct FestivalReviewSummary: View {
    let review: FestivalReview

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            FestivalArtworkView(festival: review.festival)
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(review.festival.name)
                        .font(.title3.weight(.black))
                        .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Label(review.festival.city, systemImage: "mappin.and.ellipse")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                        .lineLimit(1)

                    Label(review.attendedOn, systemImage: "calendar")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    ForEach(review.festival.genreTags.prefix(3), id: \.self) { tag in
                        WristbandTag(text: tag, palette: review.festival.palette)
                    }
                }
            }
        }

        Text(review.reviewText)
            .font(.body)
            .lineSpacing(2)
            .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel("Review: \(review.reviewText)")
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

private struct CategoryScoreView: View {
    let score: ReviewCategoryScore
    let palette: FestivalPalette

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(score.name)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                    .lineLimit(1)

                Spacer(minLength: 4)

                Text(score.score, format: .number.precision(.fractionLength(1)))
                    .font(.caption.weight(.black))
                    .monospacedDigit()
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(WristlistTheme.cardStroke(for: colorScheme))

                    Capsule()
                        .fill(WristlistTheme.gradient(for: palette))
                        .frame(width: max(8, proxy.size.width * min(score.score / 10, 1)))
                }
            }
            .frame(height: 5)
        }
        .padding(10)
        .background(Color.white.opacity(colorScheme == .dark ? 0.05 : 0.50), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(score.name) score \(score.score, specifier: "%.1f") out of 10")
    }
}

private struct ReviewActionBar: View {
    let likeCount: Int
    let commentCount: Int
    let isLiked: Bool
    let isSaved: Bool
    let onLike: () -> Void
    let onComment: () -> Void
    let onSave: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            ReviewActionButton(
                title: "\(likeCount)",
                systemImage: isLiked ? "heart.fill" : "heart",
                isActive: isLiked,
                accessibilityLabel: isLiked ? "Unlike review" : "Like review",
                action: onLike
            )

            ReviewActionButton(
                title: "\(commentCount)",
                systemImage: "bubble.left",
                isActive: false,
                accessibilityLabel: "Comment on review",
                action: onComment
            )

            Spacer()

            ReviewActionButton(
                title: isSaved ? "Saved" : "Save",
                systemImage: isSaved ? "bookmark.fill" : "bookmark",
                isActive: isSaved,
                accessibilityLabel: isSaved ? "Remove saved review" : "Save review",
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
                .background(Color.white.opacity(colorScheme == .dark ? 0.06 : 0.55), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

#Preview("Review Card") {
    ZStack {
        WristlistTheme.appBackground(for: .dark)
            .ignoresSafeArea()

        ReviewCardView(review: SampleFeedData.reviews[0])
            .padding()
    }
    .preferredColorScheme(.dark)
}
