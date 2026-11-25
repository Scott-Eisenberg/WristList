import SwiftData
import SwiftUI

struct JournalHome: View {
    let tab: JournalTab
    @Query(sort: \WLFestival.startDate) private var festivals: [WLFestival]
    @Query private var reviews: [WLReview]
    @Query private var profiles: [WLProfile]
    @State private var filter = "For you"
    @State private var search = ""

    private var profile: WLProfile? { profiles.first { $0.id == WristlistDataController.currentUserID } }
    private var visible: [WLFestival] {
        festivals.filter { festival in
            (search.isEmpty || "\(festival.name) \(festival.cityState) \(festival.genres.joined(separator: " "))".localizedCaseInsensitiveContains(search)) &&
            (filter == "For you" || (filter == "Saved" ? festival.isSaved : festival.genres.contains(filter)))
        }
    }
    private func score(_ festival: WLFestival) -> Double? {
        reviews.first { $0.festivalID == festival.id && $0.isCurrentUser }?.overallScore
    }

    var body: some View {
        NavigationStack {
            Group {
                switch tab {
                case .discover, .add:
                    discover
                case .rankings:
                    JournalRankings()
                case .friends:
                    JournalFriends()
                case .profile:
                    JournalProfile()
                }
            }
            .background(JournalStyle.paper)
            .foregroundStyle(JournalStyle.ink)
            
            .toolbar {
                if tab == .discover {
                    ToolbarItem(placement: .navigation) {
                        HStack(spacing: 6) {
                            Text("wristlist").font(.title3.bold()).tracking(-0.8)
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        NavigationLink { JournalProfile() } label: {
                            Text(profile?.avatarInitials ?? "SE").font(.caption.bold())
                                .frame(width: 40, height: 40)
                                .background(JournalStyle.violet.opacity(0.10), in: Circle())
                        }.accessibilityLabel("Your profile")
                    }
                }
            }
        }
    }

    private var discover: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    JournalHeading(title: "Discover festivals",
                                   subtitle: "Hey \(profile?.displayName.components(separatedBy: " ").first ?? "Scott"). Explore your friends’ favorites and plan what’s next.")
                    HStack {
                        Image(systemName: "magnifyingglass")
                        TextField("Festival, city, or genre", text: $search)
                            .textFieldStyle(.plain)
                            .accessibilityLabel("Search festivals")
                        if !search.isEmpty {
                            Button { search = "" } label: { Image(systemName: "xmark.circle.fill") }
                                .frame(minWidth: 44, minHeight: 44).accessibilityLabel("Clear search")
                        }
                    }
                    .padding(.horizontal, 16).frame(minHeight: 48)
                    .background(.white, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(JournalStyle.line))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(["For you", "Indie", "Electronic", "Rock", "Saved"], id: \.self) { item in
                                Button { filter = item } label: {
                                    Text(item).font(.subheadline.weight(.medium))
                                        .padding(.horizontal, 16).frame(minHeight: 44)
                                        .background(filter == item ? JournalStyle.ink : .white, in: Capsule())
                                        .foregroundStyle(filter == item ? .white : JournalStyle.ink)
                                }.buttonStyle(.plain).accessibilityAddTraits(filter == item ? .isSelected : [])
                            }
                        }
                    }
                    JournalDiscoverySections(festivals: visible, reviews: reviews, isWide: geometry.size.width >= 960)
                    Text("Demo dates, lineups, and friend recommendations. Archive photo credits are on each festival page.")
                        .font(.caption2).foregroundStyle(JournalStyle.muted).padding(.top, 8)
                }
                .padding(24).frame(maxWidth: 1280).frame(maxWidth: .infinity)
            }
            .journalNavigationStyle()
        }
    }
}

private struct JournalDiscoverySections: View {
    let festivals: [WLFestival]
    let reviews: [WLReview]
    let isWide: Bool
    private var featured: WLFestival? { festivals.first { $0.id == "outside-lands" } ?? festivals.first }
    private var popular: [WLFestival] {
        let candidates = festivals.filter { !$0.friendNames.isEmpty && $0.id != featured?.id }
        return Array(candidates.sorted {
            let firstHasPhoto = FestivalPhoto.catalog[$0.id] != nil
            let secondHasPhoto = FestivalPhoto.catalog[$1.id] != nil
            return firstHasPhoto != secondHasPhoto ? firstHasPhoto : $0.startDate < $1.startDate
        }.prefix(4))
    }
    private var upcoming: [WLFestival] { festivals.filter { $0.timing == .upcoming } }
    private func score(_ festival: WLFestival) -> Double? {
        reviews.first { $0.festivalID == festival.id && $0.isCurrentUser }?.overallScore
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            if let featured {
                if isWide {
                    HStack(alignment: .top, spacing: 32) {
                        NavigationLink { JournalDetail(festival: featured) } label: {
                            JournalFeatureCard(festival: featured, score: score(featured))
                        }.buttonStyle(.plain).frame(minWidth: 500, maxWidth: .infinity)
                        JournalUpcomingSection(festivals: upcoming, reviews: reviews)
                            .frame(minWidth: 360, maxWidth: 420)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 24) {
                        NavigationLink { JournalDetail(festival: featured) } label: {
                            JournalFeatureCard(festival: featured, score: score(featured))
                        }.buttonStyle(.plain)
                    }
                }
            } else {
                ContentUnavailableView("No festivals found", systemImage: "magnifyingglass",
                                       description: Text("Try another city, genre, or filter."))
            }
            if !popular.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Popular with friends").font(.title3.bold())
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 20, alignment: .top)], alignment: .leading, spacing: 24) {
                        ForEach(popular) { festival in
                            NavigationLink { JournalDetail(festival: festival) } label: {
                                JournalFeatureCard(festival: festival, score: score(festival), compact: true)
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }
            if !isWide || featured == nil {
                JournalUpcomingSection(festivals: upcoming, reviews: reviews, title: "Upcoming festivals")
            }
        }
    }
}

private struct JournalUpcomingSection: View {
    let festivals: [WLFestival]
    let reviews: [WLReview]
    var title = "On the horizon"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.title3.bold()).padding(.bottom, 8)
            if festivals.isEmpty {
                Text("No upcoming festivals match. Try a different filter.")
                    .font(.subheadline).foregroundStyle(JournalStyle.muted)
            }
            ForEach(festivals) { festival in
                NavigationLink { JournalDetail(festival: festival) } label: {
                    JournalFestivalRow(festival: festival, score: reviews.first {
                        $0.festivalID == festival.id && $0.isCurrentUser
                    }?.overallScore)
                }.buttonStyle(.plain)
                Divider()
            }
        }
    }
}

struct JournalRankings: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<WLFestival> { $0.statusRaw == "attended" }, sort: \WLFestival.personalRank)
    private var festivals: [WLFestival]
    @Query(filter: #Predicate<WLReview> { $0.isCurrentUser }) private var reviews: [WLReview]
    @State private var editing = false
    @State private var error: String?
    var body: some View {
        List {
            Section {
                JournalHeading(title: "Your greatest hits.", subtitle: "\(festivals.count) weekends. Entirely your order.")
                    .padding(.vertical, 16)
                Text(editing ? "Drag the handles to change your order." : "The sets, the people, the ones you’d do again.")
                    .font(.subheadline).foregroundStyle(JournalStyle.muted)
            }.listRowBackground(Color.clear).listRowSeparator(.hidden)
            Section {
                ForEach(festivals) { festival in
                    NavigationLink { JournalDetail(festival: festival) } label: {
                        HStack(spacing: 8) {
                            Text("\(festival.personalRank)").font(.title3.bold()).foregroundStyle(JournalStyle.muted)
                                .frame(minWidth: 24)
                            JournalFestivalRow(festival: festival, score: reviews.first { $0.festivalID == festival.id }?.overallScore)
                        }
                    }.listRowBackground(Color.clear)
                }
                .onMove { source, destination in
                    var reordered = festivals
                    reordered.move(fromOffsets: source, toOffset: destination)
                    for (index, festival) in reordered.enumerated() { festival.personalRank = index + 1 }
                    do { try context.save() } catch { context.rollback(); self.error = error.localizedDescription }
                }
            }
            if festivals.isEmpty {
                ContentUnavailableView("Your first encore awaits", systemImage: "list.number",
                                       description: Text("Tap Add to log a festival you’ve attended."))
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain).scrollContentBackground(.hidden)
        .journalReordering(editing)
        .navigationTitle("Rankings").journalNavigationStyle()
        .toolbar { Button(editing ? "Done" : "Reorder") { editing.toggle() }.disabled(festivals.isEmpty) }
        .alert("Couldn’t save order", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(error ?? "") }
    }
}

struct JournalProfile: View {
    @Query private var profiles: [WLProfile]
    @Query(sort: \WLFestival.personalRank) private var festivals: [WLFestival]
    @Query(filter: #Predicate<WLReview> { $0.isCurrentUser }) private var reviews: [WLReview]
    @State private var showSaved = false
    private var profile: WLProfile? { profiles.first { $0.id == WristlistDataController.currentUserID } }
    private var attended: [WLFestival] { festivals.filter { $0.status == .attended } }
    private var saved: [WLFestival] { festivals.filter { $0.isSaved && $0.status != .attended } }
    private var displayed: [WLFestival] { showSaved ? saved : Array(attended.prefix(3)) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 16) {
                    Text(profile?.avatarInitials ?? "SE").font(.title.bold())
                        .frame(width: 72, height: 72).background(JournalStyle.coral.opacity(0.25), in: Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile?.displayName ?? "Your journal").font(.title.bold())
                        Text(profile?.homeCity ?? "Somewhere near the stage").font(.subheadline).foregroundStyle(JournalStyle.muted)
                    }
                }
                Text(profile?.bio ?? "Collecting weekends, not things.").font(.body)
                HStack(spacing: 32) {
                    VStack(alignment: .leading) {
                        Text("\(attended.count)").font(.title.bold())
                        Text("attended").font(.caption).foregroundStyle(JournalStyle.muted)
                    }
                    VStack(alignment: .leading) {
                        Text("\(saved.count)").font(.title.bold())
                        Text("on the bucket list").font(.caption).foregroundStyle(JournalStyle.muted)
                    }
                }
                Divider()
                Picker("Your festivals", selection: $showSaved) {
                    Text("Top festivals").tag(false)
                    Text("Bucket list").tag(true)
                }.pickerStyle(.segmented)
                ForEach(displayed) { festival in
                    NavigationLink { JournalDetail(festival: festival) } label: {
                        JournalFestivalRow(festival: festival, score: reviews.first { $0.festivalID == festival.id }?.overallScore)
                    }.buttonStyle(.plain)
                    Divider()
                }
                if displayed.isEmpty {
                    ContentUnavailableView(showSaved ? "Make room for next time" : "Start your festival journal",
                                           systemImage: showSaved ? "bookmark" : "music.note",
                                           description: Text("Use Add to save a weekend or rate one you’ve lived."))
                }
            }.padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }
        .background(JournalStyle.paper).foregroundStyle(JournalStyle.ink)
        .navigationTitle("Profile").journalNavigationStyle()
        .toolbar {
            if let profile {
                NavigationLink { JournalEditProfile(profile: profile) } label: { Text("Edit") }
            }
        }
    }
}

struct JournalFriends: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<WLReview> { !$0.isCurrentUser && $0.isVisibleToFriends }, sort: \WLReview.createdAt, order: .reverse)
    private var reviews: [WLReview]
    @Query private var festivals: [WLFestival]
    @State private var error: String?
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                JournalHeading(title: "Good ears. Great company.", subtitle: "The weekends your friends are still talking about.")
                ForEach(reviews) { review in
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(review.userInitials).font(.caption.bold()).frame(width: 40, height: 40)
                                .background(JournalStyle.violet.opacity(0.10), in: Circle())
                            VStack(alignment: .leading, spacing: 4) {
                                Text(review.userName).font(.headline)
                                Text("Added a festival to their journal").font(.caption).foregroundStyle(JournalStyle.muted)
                            }
                            Spacer()
                            JournalScore(score: review.overallScore)
                        }
                        if let festival = festivals.first(where: { $0.id == review.festivalID }) {
                            NavigationLink { JournalDetail(festival: festival) } label: {
                                JournalFeatureCard(festival: festival, compact: true)
                            }.buttonStyle(.plain)
                        }
                        Text(review.reviewText).font(.subheadline)
                        Button {
                            do { try WristlistDataController.toggleLike(review, context: context) }
                            catch { context.rollback(); self.error = error.localizedDescription }
                        } label: {
                            Label("\(review.likeCount) · Love this", systemImage: review.isLiked ? "heart.fill" : "heart")
                                .font(.subheadline).frame(minHeight: 44)
                        }
                        Divider()
                    }
                }
                if reviews.isEmpty {
                    ContentUnavailableView("Quiet between sets", systemImage: "person.2", description: Text("Friends’ shared festival reviews will appear here."))
                }
            }.padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }
        .navigationTitle("Friends").journalNavigationStyle()
        .alert("Couldn’t save reaction", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(error ?? "") }
    }
}

#if os(macOS)
#Preview("Discover · desktop") {
    JournalHome(tab: .discover)
        .modelContainer(PreviewContainerFactory.makeContainer())
        .frame(width: 1120, height: 1000)
        .preferredColorScheme(.light)
}

#Preview("Discover · narrow") {
    JournalHome(tab: .discover)
        .modelContainer(PreviewContainerFactory.makeContainer())
        .frame(width: 390, height: 844)
        .preferredColorScheme(.light)
}
#endif
