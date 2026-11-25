import SwiftData
import SwiftUI

struct JournalDetail: View {
    let festival: WLFestival
    @Environment(\.modelContext) private var context
    @Query private var reviews: [WLReview]
    @State private var rating = false
    @State private var feedback: String?
    @State private var error: String?
    private var mine: WLReview? { reviews.first { $0.festivalID == festival.id && $0.isCurrentUser } }
    private var friends: [WLReview] { reviews.filter { $0.festivalID == festival.id && !$0.isCurrentUser && $0.isVisibleToFriends } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                JournalFeatureCard(festival: festival, score: mine?.overallScore)
                Text(festival.summary).font(.body).lineSpacing(4)
                Label(festival.venue, systemImage: "mappin.and.ellipse")
                    .font(.subheadline).foregroundStyle(JournalStyle.muted)
                HStack(spacing: 12) {
                    Button { rating = true } label: {
                        Label(mine == nil ? "Log & rate" : "Edit your rating", systemImage: "slider.horizontal.3")
                            .font(.subheadline.bold()).frame(maxWidth: .infinity, minHeight: 48)
                    }.buttonStyle(.borderedProminent)
                    Button {
                        do {
                            try WristlistDataController.toggleSave(festival, context: context)
                            feedback = festival.isSaved ? "Saved to your journal" : "Removed from saved"
                        } catch { context.rollback(); self.error = error.localizedDescription }
                    } label: {
                        Label(festival.isSaved ? "Saved" : "Save", systemImage: festival.isSaved ? "bookmark.fill" : "bookmark")
                            .font(.subheadline.bold()).frame(minHeight: 48)
                    }.buttonStyle(.bordered)
                }
                if festival.status == .attended {
                    Label("In your attended festivals", systemImage: "checkmark.circle.fill")
                        .font(.subheadline).foregroundStyle(JournalStyle.violet)
                }
                if let feedback {
                    Label(feedback, systemImage: "checkmark.circle.fill").font(.subheadline)
                        .foregroundStyle(JournalStyle.violet).accessibilityAddTraits(.updatesFrequently)
                }
                Divider()
                Text("The lineup").font(.title2.bold())
                Text(festival.lineup.joined(separator: "  /  "))
                    .font(.title3.weight(.medium)).lineSpacing(8)
                Text("Illustrative demo lineup and dates.").font(.caption).foregroundStyle(JournalStyle.muted)
                Divider()
                if let photo = FestivalPhoto.catalog[festival.id] {
                    FestivalPhotoCredit(photo: photo)
                    Divider()
                }
                Text("Friends’ notes").font(.title2.bold())
                ForEach(friends) { review in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(review.userName).font(.headline)
                            Spacer()
                            JournalScore(score: review.overallScore)
                        }
                        Text(review.reviewText).font(.subheadline).lineSpacing(4)
                        Divider()
                    }
                }
                if friends.isEmpty {
                    Text("No reviews from your friends yet. Your notes could start something.")
                        .foregroundStyle(JournalStyle.muted)
                }
            }.padding(24).frame(maxWidth: 840).frame(maxWidth: .infinity)
        }
        .background(JournalStyle.paper).foregroundStyle(JournalStyle.ink)
        .navigationTitle(festival.name).journalNavigationStyle()
        .sheet(isPresented: $rating) {
            JournalRatingView(festival: festival, existingReview: mine) { feedback = "Rating saved. Another weekend in the books." }
        }
        .alert("Couldn’t save changes", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(error ?? "") }
    }
}

struct JournalAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WLFestival.name) private var festivals: [WLFestival]
    @State private var search = ""
    private var matches: [WLFestival] {
        festivals.filter { search.isEmpty || "\($0.name) \($0.cityState) \($0.genres.joined(separator: " "))".localizedCaseInsensitiveContains(search) }
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    JournalHeading(title: "Keep the weekend.", subtitle: "Find a festival to rate or save for another day.").padding(.bottom, 16)
                    ForEach(matches) { festival in
                        NavigationLink { JournalDetail(festival: festival) } label: {
                            JournalFestivalRow(festival: festival)
                        }.buttonStyle(.plain)
                        Divider()
                    }
                    if matches.isEmpty {
                        ContentUnavailableView.search(text: search)
                    }
                }.padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity)
            }
            .searchable(text: $search, prompt: "Search festivals or cities")
            .background(JournalStyle.paper).foregroundStyle(JournalStyle.ink)
            .navigationTitle("Add a festival").journalNavigationStyle()
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }.tint(JournalStyle.violet).preferredColorScheme(.light)
    }
}

struct JournalRatingView: View {
    let festival: WLFestival
    let existingReview: WLReview?
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var profiles: [WLProfile]
    @State private var overall = 8.0
    @State private var lineup: Double?
    @State private var organization: Double?
    @State private var venue: Double?
    @State private var vibe: Double?
    @State private var notes = ""
    @State private var attendedDate = Date.now
    @State private var share = true
    @State private var error: String?
    @State private var initialized = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(festival.name).font(.title2.bold())
                    Text("How did it feel to be there?").foregroundStyle(JournalStyle.muted)
                    DatePicker("Date attended", selection: $attendedDate, in: ...Date.now, displayedComponents: .date)
                }
                Section("Your overall score") {
                    HStack {
                        Text("Overall").font(.headline)
                        Spacer()
                        JournalScore(score: overall)
                    }
                    Slider(value: $overall, in: 0...10, step: 0.1).accessibilityLabel("Overall rating")
                }
                Section {
                    JournalOptionalScore(title: "Lineup", value: $lineup)
                    JournalOptionalScore(title: "Organization", value: $organization)
                    JournalOptionalScore(title: "Venue", value: $venue)
                    JournalOptionalScore(title: "Vibe", value: $vibe)
                } header: { Text("The details · optional") }
                Section("A note for future you") {
                    TextField("The encore, the people, the walk back…", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                    Toggle("Share with friends", isOn: $share)
                }
                Section {
                    Button(existingReview == nil ? "Save to my journal" : "Save rating") { save() }
                        .font(.headline).frame(maxWidth: .infinity, minHeight: 44)
                }
            }
            .scrollContentBackground(.hidden).background(JournalStyle.paper)
            .navigationTitle("Rate your weekend").journalNavigationStyle()
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .onAppear {
                guard !initialized else { return }
                initialized = true
                attendedDate = min(existingReview?.attendedDate ?? festival.attendedDate ?? festival.endDate, .now)
                if let review = existingReview {
                    overall = review.overallScore
                    lineup = review.journalLineupScore
                    organization = review.journalOrganizationScore
                    venue = review.journalVenueScore
                    vibe = review.journalVibeScore
                    notes = review.reviewText
                    share = review.isVisibleToFriends
                }
            }
            .alert("Couldn’t save your rating", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK", role: .cancel) {}
            } message: { Text(error ?? "") }
        }.tint(JournalStyle.violet).preferredColorScheme(.light)
    }

    private func save() {
        do {
            let profile = try WristlistDataController.currentProfile(from: profiles, context: context)
            var draft = ReviewDraft.blank
            draft.festivalID = festival.id
            draft.attendedDate = attendedDate
            draft.overallScore = overall
            draft.lineupScore = lineup ?? overall
            draft.organizationScore = organization ?? overall
            draft.venueScore = venue ?? overall
            draft.reviewText = notes
            draft.isVisibleToFriends = share
            draft.journalLineupScore = lineup
            draft.journalOrganizationScore = organization
            draft.journalVenueScore = venue
            draft.journalVibeScore = vibe
            try WristlistDataController.saveReview(draft: draft, festival: festival,
                                                  profile: profile, existingReview: existingReview, context: context)
            onSave()
            dismiss()
        } catch {
            context.rollback()
            self.error = error.localizedDescription
        }
    }
}

private struct JournalOptionalScore: View {
    let title: String
    @Binding var value: Double?
    var body: some View {
        VStack(spacing: 12) {
            Toggle(isOn: Binding(get: { value != nil }, set: { value = $0 ? 8 : nil })) {
                HStack {
                    Text(title)
                    Spacer()
                    if let value { Text(value, format: .number.precision(.fractionLength(1))).monospacedDigit() }
                }
            }
            if value != nil {
                Slider(value: Binding(get: { value ?? 8 }, set: { value = $0 }), in: 0...10, step: 0.1)
                    .accessibilityLabel("\(title) rating")
            }
        }.padding(.vertical, 4)
    }
}
