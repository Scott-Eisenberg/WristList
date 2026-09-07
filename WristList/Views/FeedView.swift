//
//  FeedView.swift
//  WristList
//

import SwiftUI

struct FeedView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var reviews = SampleFeedData.reviews
    @State private var headerIsVisible = false

    var body: some View {
        NavigationStack {
            ZStack {
                WristlistTheme.appBackground(for: colorScheme)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        FeedHeaderView()
                            .opacity(headerIsVisible ? 1 : 0)
                            .offset(y: headerIsVisible ? 0 : -10)

                        LogFestivalButton()

                        UpcomingFestivalsSection(festivals: SampleFeedData.upcomingFestivals)

                        FriendsReviewsSection(reviews: reviews)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                }
                .refreshable {
                    await refreshFeed()
                }
            }
#if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
#endif
            .onAppear {
                withAnimation(.easeOut(duration: 0.45)) {
                    headerIsVisible = true
                }
            }
        }
    }

    @MainActor
    private func refreshFeed() async {
        try? await Task.sleep(nanoseconds: 700_000_000)

        guard reviews.count > 1 else { return }

        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
            let firstReview = reviews.removeFirst()
            reviews.append(firstReview)
        }
    }
}

private struct FeedHeaderView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Wristlist")
                    .font(.system(size: 35, weight: .black, design: .rounded))
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))

                Text("Live notes from the festival circuit")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
            }

            Spacer(minLength: 8)

            HeaderIconButton(systemImage: "bell.badge", accessibilityLabel: "Open notifications") { }

            AvatarButton(initials: "SE", palette: .sunset) { }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct LogFestivalButton: View {
    @State private var isPressed = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                isPressed.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3.weight(.bold))

                Text("Log a Festival")
                    .font(.headline.weight(.bold))

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.subheadline.weight(.bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .frame(height: 58)
            .background(WristlistTheme.gradient(for: .sunset), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: WristlistTheme.coral.opacity(0.26), radius: isPressed ? 8 : 18, y: isPressed ? 4 : 12)
            .scaleEffect(isPressed ? 0.98 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Log a festival")
    }
}

private struct UpcomingFestivalsSection: View {
    let festivals: [Festival]

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitleView(title: "Upcoming Festivals", actionTitle: "See all")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(festivals) { festival in
                        UpcomingFestivalCard(festival: festival)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 2)
            }
            .padding(.horizontal, -18)
        }
    }
}

private struct UpcomingFestivalCard: View {
    let festival: Festival

    @Environment(\.colorScheme) private var colorScheme
    @State private var isSaved = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            FestivalArtworkView(festival: festival)
                .frame(width: 174, height: 134)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 7) {
                Text(festival.dateRange)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WristlistTheme.coral)

                Text(festival.name)
                    .font(.headline.weight(.bold))
                    .lineLimit(1)
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))

                Text(festival.city)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))

                HStack(spacing: 6) {
                    ForEach(festival.genreTags.prefix(2), id: \.self) { tag in
                        WristbandTag(text: tag, palette: festival.palette)
                    }
                }
            }
            .padding(.horizontal, 2)

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                    isSaved.toggle()
                }
            } label: {
                Label(isSaved ? "Saved" : "Save", systemImage: isSaved ? "bookmark.fill" : "bookmark")
                    .font(.caption.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .foregroundStyle(isSaved ? .white : WristlistTheme.primaryText(for: colorScheme))
                    .background(isSaved ? WristlistTheme.gradient(for: festival.palette) : LinearGradient(colors: [WristlistTheme.cardFill(for: colorScheme)], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isSaved ? "Remove \(festival.name) from saved festivals" : "Save \(festival.name)")
        }
        .padding(10)
        .frame(width: 194)
        .background(WristlistTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(WristlistTheme.cardStroke(for: colorScheme), lineWidth: 1)
        }
    }
}

private struct FriendsReviewsSection: View {
    let reviews: [FestivalReview]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitleView(title: "Friends' Reviews", actionTitle: "Filter")

            LazyVStack(spacing: 14) {
                ForEach(reviews) { review in
                    ReviewCardView(review: review)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
}

private struct SectionTitleView: View {
    let title: String
    let actionTitle: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title3.weight(.black))
                .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))

            Spacer()

            Button(actionTitle) { }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(WristlistTheme.coral)
                .accessibilityLabel(actionTitle)
        }
    }
}

#Preview("Feed Dark") {
    FeedView()
        .preferredColorScheme(.dark)
}

#Preview("Feed Light") {
    FeedView()
        .preferredColorScheme(.light)
}
