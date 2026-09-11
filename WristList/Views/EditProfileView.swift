//
//  EditProfileView.swift
//  WristList
//

import SwiftData
import SwiftUI

struct EditProfileView: View {
    let profile: WLProfile

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var displayName: String
    @State private var username: String
    @State private var bio: String
    @State private var homeCity: String
    @State private var palette: FestivalPalette
    @State private var showingDiscardConfirmation = false
    @State private var validationMessage: String?

    init(profile: WLProfile) {
        self.profile = profile
        _displayName = State(initialValue: profile.displayName)
        _username = State(initialValue: profile.username)
        _bio = State(initialValue: profile.bio)
        _homeCity = State(initialValue: profile.homeCity)
        _palette = State(initialValue: profile.palette)
    }

    private var hasChanges: Bool {
        displayName != profile.displayName ||
        username != profile.username ||
        bio != profile.bio ||
        homeCity != profile.homeCity ||
        palette != profile.palette
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Name", text: $displayName)
                        .textContentType(.name)
                        .accessibilityLabel("Display name")

                    TextField("Username", text: $username)
                        .accessibilityLabel("Username")

                    TextField("Home city", text: $homeCity)
                        .accessibilityLabel("Home city")
                }

                Section("Bio") {
                    TextEditor(text: $bio)
                        .frame(minHeight: 96)
                        .accessibilityLabel("Bio")
                }

                Section("Profile Color") {
                    Picker("Color", selection: $palette) {
                        ForEach(FestivalPalette.allCases) { palette in
                            Text(palette.rawValue.capitalized).tag(palette)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Profile color")
                }

                if let validationMessage {
                    Section {
                        Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(WristlistTheme.coral)
                    }
                }
            }
            .navigationTitle("Edit Profile")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { cancel() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!hasChanges)
                }
            }
            .confirmationDialog("Discard profile changes?", isPresented: $showingDiscardConfirmation, titleVisibility: .visible) {
                Button("Discard Changes", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) { }
            }
        }
    }

    private func cancel() {
        if hasChanges {
            showingDiscardConfirmation = true
        } else {
            dismiss()
        }
    }

    private func save() {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedHomeCity = homeCity.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            validationMessage = "Name is required."
            return
        }

        guard !trimmedUsername.isEmpty else {
            validationMessage = "Username is required."
            return
        }

        profile.displayName = trimmedName
        profile.username = trimmedUsername.hasPrefix("@") ? trimmedUsername : "@\(trimmedUsername)"
        profile.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.homeCity = trimmedHomeCity.isEmpty ? "Los Angeles, CA" : trimmedHomeCity
        profile.avatarInitials = initials(from: trimmedName)
        profile.palette = palette
        profile.updatedAt = .now

        do {
            try WristlistDataController.saveIfNeeded(modelContext)
            dismiss()
        } catch {
            validationMessage = error.localizedDescription
        }
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }.map(String.init)
        return letters.joined().uppercased()
    }
}

#Preview("Edit Profile") {
    let container = PreviewContainerFactory.makeContainer()
    let context = container.mainContext
    let profiles = (try? context.fetch(FetchDescriptor<WLProfile>())) ?? []

    if let profile = profiles.first {
        EditProfileView(profile: profile)
            .modelContainer(container)
    }
}
