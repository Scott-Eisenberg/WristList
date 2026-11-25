//
//  FeedView.swift
//  WristList
//

import SwiftData
import SwiftUI

struct FeedView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var festivals: [WLFestival]
    @Query private var reviews: [WLReview]
    @Query private var profiles: [WLProfile]

    @State private var isRefreshing = false
    @State private var isShowingReviewFlow = false
    @State private var isShowingNotifications = false
    @State private var actionError: String?

    private var currentProfile: WLProfile? {
        profiles.first { $0.id == WristlistDataController.currentUserID } ?? profiles.first
    }

    private var upcomingFestivals: [WLFestival] {
        festivals
            .filter { $0.timing == .upcoming }
            .sorted { $0.startDate < $1.startDate }
            .prefix(6)
            .map { $0 }
    }

    private var friendReviews: [WLReview] {
        reviews
            .filter { $0.isVisibleToFriends }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                WristlistTheme.appBackground(for: colorScheme)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 30) {
                        FeedHeaderView(profile: currentProfile, onNotifications: { isShowingNotifications = true })

                        LogFestivalButton {
                            isShowingReviewFlow = true
                        }

                        if isRefreshing {
                            FeedLoadingView()
                        }

                        UpcomingFestivalsSection(festivals: upcomingFestivals)

                        FriendsReviewsSection(
                            reviews: friendReviews,
                            festivals: festivals,
                            profile: currentProfile,
                            onLogFestival: { isShowingReviewFlow = true }
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 34)
                }
                .refreshable {
                    await refreshFeed()
                }
            }
#if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
#endif
        }
        .sheet(isPresented: $isShowingReviewFlow) {
            ReviewFlowView(festivals: festivals, profile: currentProfile)
        }
        .sheet(isPresented: $isShowingNotifications) {
            NotificationsSheet(festivals: festivals, reviews: friendReviews)
        }
        .alert("Feed update failed", isPresented: Binding(get: { actionError != nil }, set: { if !$0 { actionError = nil } })) {
            Button("OK", role: .cancel) { actionError = nil }
        } message: {
            Text(actionError ?? "Try again.")
        }
    }

    @MainActor
    private func refreshFeed() async {
        isRefreshing = true
        try? await Task.sleep(nanoseconds: 700_000_000)
        let animation = reduceMotion ? Animation.linear(duration: 0.01) : .spring(response: 0.40, dampingFraction: 0.86)
        withAnimation(animation) {
            isRefreshing = false
        }
    }
}

private struct FeedHeaderView: View {
    let profile: WLProfile?
    let onNotifications: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wristlist")
                        .font(WristlistTheme.mastheadFont)
                        .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)

                    Text("Ratings, plans, and field notes from your circle")
                        .font(WristlistTheme.metadataFont)
                        .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                }

                Spacer(minLength: 8)

                HeaderIconButton(systemImage: "bell.badge", accessibilityLabel: "Open notifications", action: onNotifications)
            }

            HStack(alignment: .center, spacing: 12) {
                Rectangle()
                    .fill(WristlistTheme.brand)
                    .frame(width: 72, height: 3)

                Text("Culture Log")
                    .font(WristlistTheme.kickerFont)
                    .tracking(1.2)
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))

                Spacer(minLength: 8)

                NavigationLink {
                    if let profile {
                        UserProfileDetailView(profile: profile)
                    } else {
                        EmptyStateView(title: "Profile loading", message: "Your local profile is being prepared.", systemImage: "person.crop.circle")
                            .padding()
                    }
                } label: {
                    AvatarCircle(
                        initials: profile?.avatarInitials ?? "WL",
                        palette: profile?.palette ?? .sunset,
                        size: 44,
                        fontSize: 14
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open your profile")
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct LogFestivalButton: View {
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false

    var body: some View {
        Button {
            if !reduceMotion {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                        isPressed = false
                    }
                }
            }
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.title3.weight(.bold))

                Text("Log a Festival")
                    .font(.headline.weight(.bold))

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.subheadline.weight(.bold))
            }
            .foregroundStyle(.white)
            .scaleEffect(isPressed ? 0.98 : 1)
        }
        .buttonStyle(PrimaryActionButtonStyle())
        .accessibilityLabel("Log a festival")
    }
}

private struct FeedLoadingView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(WristlistTheme.coral)
            Text("Refreshing festival activity")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
            Spacer()
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}

private struct UpcomingFestivalsSection: View {
    let festivals: [WLFestival]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitleView(title: "On Your Radar", subtitle: "Saved, nearby, and rising weekends")

            if festivals.isEmpty {
                EmptyStateView(
                    title: "No upcoming festivals",
                    message: "Saved and recommended festivals will appear here once local data is available.",
                    systemImage: "calendar.badge.exclamationmark"
                )
            } else {
                if let featuredFestival = festivals.first {
                    NavigationLink {
                        FestivalDetailView(festival: featuredFestival)
                    } label: {
                        FeaturedUpcomingFestival(festival: featuredFestival)
                    }
                    .buttonStyle(.plain)
                }

                if festivals.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 18) {
                            ForEach(Array(festivals.dropFirst())) { festival in
                                NavigationLink {
                                    FestivalDetailView(festival: festival)
                                } label: {
                                    UpcomingFestivalCard(festival: festival)
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
}

private struct FeaturedUpcomingFestival: View {
    let festival: WLFestival

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var actionError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            FestivalArtworkView(festival: festival)
                .frame(height: 240)

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(festival.dateRangeText.uppercased())
                        .font(WristlistTheme.kickerFont)
                        .tracking(1)
                        .foregroundStyle(WristlistTheme.accent(for: festival.palette))

                    Text(festival.name)
                        .font(WristlistTheme.festivalTitleFont)
                        .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                        .lineLimit(2)
                        .minimumScaleFactor(0.74)

                    Text("\(festival.venue), \(festival.cityState)")
                        .font(WristlistTheme.metadataFont)
                        .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                        .lineLimit(2)
                }

                Spacer(minLength: 10)

                ScoreBadge(score: festival.communityRating, palette: festival.palette, label: "Community rating")
            }

            HStack(alignment: .center, spacing: 12) {
                Text(festival.summary)
                    .font(.subheadline)
                    .lineSpacing(2)
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                    .lineLimit(3)

                Spacer(minLength: 12)

                Button(action: toggleSave) {
                    Image(systemName: festival.isSaved ? "bookmark.fill" : "bookmark")
                        .font(.headline.weight(.black))
                        .foregroundStyle(festival.isSaved ? WristlistTheme.accent(for: festival.palette) : WristlistTheme.primaryText(for: colorScheme))
                        .frame(width: 44, height: 44)
                        .background(WristlistTheme.fieldFill(for: colorScheme), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(festival.isSaved ? "Remove \(festival.name) from saved festivals" : "Save \(festival.name)")
            }
        }
        .alert("Save failed", isPresented: Binding(get: { actionError != nil }, set: { if !$0 { actionError = nil } })) {
            Button("OK", role: .cancel) { actionError = nil }
        } message: {
            Text(actionError ?? "Try again.")
        }
    }

    private func toggleSave() {
        do {
            try WristlistDataController.toggleSave(festival, context: modelContext)
        } catch {
            actionError = error.localizedDescription
        }
    }
}

private struct UpcomingFestivalCard: View {
    let festival: WLFestival

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var actionError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            FestivalArtworkView(festival: festival)
                .frame(width: 168, height: 206)

            VStack(alignment: .leading, spacing: 7) {
                Text(festival.dateRangeText)
                    .font(WristlistTheme.kickerFont)
                    .tracking(0.8)
                    .foregroundStyle(WristlistTheme.accent(for: festival.palette))

                Text(festival.name)
                    .font(.system(size: 20, weight: .black, design: .serif))
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))

                Text(festival.cityState)
                    .font(WristlistTheme.metadataFont)
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))

                HStack(alignment: .firstTextBaseline) {
                    WristbandTag(text: festival.genres.first ?? "Festival", palette: festival.palette)
                    Spacer(minLength: 8)
                    Text(festival.communityRating, format: .number.precision(.fractionLength(1)))
                        .font(.headline.weight(.black))
                        .monospacedDigit()
                        .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                }
            }
            .padding(.horizontal, 2)

            Button {
                do {
                    try WristlistDataController.toggleSave(festival, context: modelContext)
                } catch {
                    actionError = error.localizedDescription
                }
            } label: {
                Label(festival.isSaved ? "Saved" : "Save", systemImage: festival.isSaved ? "bookmark.fill" : "bookmark")
                    .font(.caption.weight(.black))
                    .foregroundStyle(festival.isSaved ? WristlistTheme.accent(for: festival.palette) : WristlistTheme.secondaryText(for: colorScheme))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(festival.isSaved ? "Remove \(festival.name) from saved festivals" : "Save \(festival.name)")
        }
        .frame(width: 168, alignment: .topLeading)
        .alert("Save failed", isPresented: Binding(get: { actionError != nil }, set: { if !$0 { actionError = nil } })) {
            Button("OK", role: .cancel) { actionError = nil }
        } message: {
            Text(actionError ?? "Try again.")
        }
    }
}

private struct FriendsReviewsSection: View {
    let reviews: [WLReview]
    let festivals: [WLFestival]
    let profile: WLProfile?
    let onLogFestival: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitleView(title: "Friend Notes", subtitle: "Fresh ratings from your circle")

            if reviews.isEmpty {
                EmptyStateView(
                    title: "No reviews yet",
                    message: "Log your first festival or save an upcoming one to start shaping your feed.",
                    systemImage: "text.bubble",
                    actionTitle: "Log Festival",
                    action: onLogFestival
                )
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(reviews) { review in
                        if let festival = festivals.first(where: { $0.id == review.festivalID }) {
                            ReviewCardView(review: review, festival: festival, profile: profile)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }
            }
        }
    }
}

private struct NotificationsSheet: View {
    let festivals: [WLFestival]
    let reviews: [WLReview]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if reviews.isEmpty && festivals.filter({ $0.timing == .upcoming }).isEmpty {
                    ContentUnavailableView(
                        "Nothing new",
                        systemImage: "bell",
                        description: Text("Friend ratings and saved festival dates will show up here.")
                    )
                }

                if !reviews.isEmpty {
                    Section("Friend ratings") {
                        ForEach(reviews.prefix(4)) { review in
                            let festivalName = festivals.first { $0.id == review.festivalID }?.name ?? "a festival"
                            Label {
                                Text("\(review.userName) rated \(festivalName) \(review.overallScore, format: .number.precision(.fractionLength(1)))")
                            } icon: {
                                Image(systemName: "quote.bubble")
                            }
                        }
                    }
                }

                if festivals.contains(where: { $0.timing == .upcoming }) {
                    Section("Upcoming") {
                        ForEach(festivals.filter { $0.timing == .upcoming }.sorted { $0.startDate < $1.startDate }.prefix(4)) { festival in
                            Label("\(festival.name) · \(festival.dateRangeText)", systemImage: "calendar")
                        }
                    }
                }
            }
            .navigationTitle("Notifications")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview("Feed Dark") {
    FeedView()
        .modelContainer(PreviewContainerFactory.makeContainer())
        .preferredColorScheme(.dark)
}

#Preview("Feed Light") {
    FeedView()
        .modelContainer(PreviewContainerFactory.makeContainer())
        .preferredColorScheme(.light)
}
