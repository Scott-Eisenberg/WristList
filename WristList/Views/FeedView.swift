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
    @Query private var comments: [WLComment]
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
                    VStack(alignment: .leading, spacing: 24) {
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
                            comments: comments,
                            onLogFestival: { isShowingReviewFlow = true }
                        )
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
        }
        .sheet(isPresented: $isShowingReviewFlow) {
            ReviewFlowView(festivals: festivals, profile: currentProfile)
        }
        .sheet(isPresented: $isShowingNotifications) {
            NotificationsSheet()
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
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Wristlist")
                    .font(.system(.largeTitle, design: .rounded).weight(.black))
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))

                Text("Live notes from the festival circuit")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
            }

            Spacer(minLength: 8)

            HeaderIconButton(systemImage: "bell.badge", accessibilityLabel: "Open notifications", action: onNotifications)

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
            .frame(minHeight: 58)
            .background(WristlistTheme.gradient(for: .sunset), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: WristlistTheme.coral.opacity(0.22), radius: isPressed ? 8 : 16, y: isPressed ? 4 : 10)
            .scaleEffect(isPressed ? 0.98 : 1)
        }
        .buttonStyle(.plain)
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
        .padding(14)
        .background(WristlistTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct UpcomingFestivalsSection: View {
    let festivals: [WLFestival]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitleView(title: "Upcoming Festivals", subtitle: "Saved, nearby, and rising weekends")

            if festivals.isEmpty {
                EmptyStateView(
                    title: "No upcoming festivals",
                    message: "Saved and recommended festivals will appear here once local data is available.",
                    systemImage: "calendar.badge.exclamationmark"
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(festivals) { festival in
                            NavigationLink {
                                FestivalDetailView(festival: festival)
                            } label: {
                                UpcomingFestivalCard(festival: festival)
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

private struct UpcomingFestivalCard: View {
    let festival: WLFestival

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var actionError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            FestivalArtworkView(festival: festival)
                .frame(width: 174, height: 134)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 7) {
                Text(festival.dateRangeText)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(WristlistTheme.coral)

                Text(festival.name)
                    .font(.headline.weight(.bold))
                    .lineLimit(1)
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))

                Text(festival.cityState)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))

                HStack(spacing: 6) {
                    ForEach(festival.genres.prefix(2), id: \.self) { tag in
                        WristbandTag(text: tag, palette: festival.palette)
                    }
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
                    .font(.caption.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .foregroundStyle(festival.isSaved ? .white : WristlistTheme.primaryText(for: colorScheme))
                    .background(saveBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(festival.isSaved ? "Remove \(festival.name) from saved festivals" : "Save \(festival.name)")
        }
        .padding(10)
        .frame(width: 194)
        .background(WristlistTheme.cardFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(WristlistTheme.cardStroke(for: colorScheme), lineWidth: 1)
        }
        .alert("Save failed", isPresented: Binding(get: { actionError != nil }, set: { if !$0 { actionError = nil } })) {
            Button("OK", role: .cancel) { actionError = nil }
        } message: {
            Text(actionError ?? "Try again.")
        }
    }

    private var saveBackground: LinearGradient {
        if festival.isSaved {
            return WristlistTheme.gradient(for: festival.palette)
        }
        return LinearGradient(colors: [WristlistTheme.cardFill(for: colorScheme)], startPoint: .leading, endPoint: .trailing)
    }
}

private struct FriendsReviewsSection: View {
    let reviews: [WLReview]
    let festivals: [WLFestival]
    let profile: WLProfile?
    let comments: [WLComment]
    let onLogFestival: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitleView(title: "Friends' Reviews", subtitle: "Fresh ratings from your circle")

            if reviews.isEmpty {
                EmptyStateView(
                    title: "No reviews yet",
                    message: "Log your first festival or save an upcoming one to start shaping your feed.",
                    systemImage: "text.bubble",
                    actionTitle: "Log Festival",
                    action: onLogFestival
                )
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(reviews) { review in
                        if let festival = festivals.first(where: { $0.id == review.festivalID }) {
                            ReviewCardView(review: review, festival: festival, profile: profile, comments: comments)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }
            }
        }
    }
}

private struct NotificationsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Label("Maya saved Nova Bloom after your review", systemImage: "bookmark.fill")
                Label("Lunar Pier is trending near Los Angeles", systemImage: "chart.line.uptrend.xyaxis")
                Label("Your Midnight Atlas review passed 30 likes", systemImage: "heart.fill")
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
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
