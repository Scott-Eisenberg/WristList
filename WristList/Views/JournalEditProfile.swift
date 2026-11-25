import SwiftData
import SwiftUI

struct JournalEditProfile: View {
    let profile: WLProfile
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var city = ""
    @State private var bio = ""
    @State private var initialized = false
    @State private var error: String?

    var body: some View {
        Form {
            Section("About you") {
                TextField("Name", text: $name)
                TextField("Home city", text: $city)
                TextField("A little about your festival taste", text: $bio, axis: .vertical).lineLimit(3...6)
            }
            Section {
                Button("Save profile") {
                    profile.displayName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    profile.homeCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
                    profile.bio = bio
                    profile.avatarInitials = profile.displayName.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined()
                    profile.updatedAt = .now
                    do { try context.save(); dismiss() }
                    catch { context.rollback(); self.error = error.localizedDescription }
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .frame(minHeight: 44)
            }
        }
        .scrollContentBackground(.hidden).background(JournalStyle.paper)
        .navigationTitle("Edit profile").journalNavigationStyle()
        .onAppear {
            guard !initialized else { return }
            initialized = true
            name = profile.displayName
            city = profile.homeCity
            bio = profile.bio
        }
        .alert("Couldn’t save profile", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(error ?? "") }
    }
}
