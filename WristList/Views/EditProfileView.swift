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
    @Environment(\.colorScheme) private var colorScheme
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
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        editHeader

                        VStack(alignment: .leading, spacing: 16) {
                            SectionTitleView(title: "Identity", subtitle: "The name and handle people see in reviews")

                            EditProfileField(title: "Name", text: $displayName, prompt: "Display name")
                                .textContentType(.name)
                                .accessibilityLabel("Display name")

                            EditProfileField(title: "Username", text: $username, prompt: "@username")
                                .accessibilityLabel("Username")

                            EditProfileField(title: "Home city", text: $homeCity, prompt: "City, State")
                                .accessibilityLabel("Home city")
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            SectionTitleView(title: "Bio", subtitle: "A short note about your festival taste")

                            TextEditor(text: $bio)
                                .font(.body)
                                .lineSpacing(3)
                                .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                                .frame(minHeight: 132)
                                .padding(12)
                                .scrollContentBackground(.hidden)
                                .background(WristlistTheme.fieldFill(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: WristlistTheme.cornerSmall, style: .continuous))
                                .overlay(alignment: .bottom) {
                                    Rectangle()
                                        .fill(WristlistTheme.divider(for: colorScheme))
                                        .frame(height: 2)
                                }
                                .accessibilityLabel("Bio")
                        }

                        VStack(alignment: .leading, spacing: 16) {
                            SectionTitleView(title: "Profile Color", subtitle: "This color travels with your avatar and reviews")

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 78), spacing: 12)], spacing: 12) {
                                ForEach(FestivalPalette.allCases) { option in
                                    PaletteSwatchButton(
                                        palette: option,
                                        isSelected: palette == option,
                                        action: { palette = option }
                                    )
                                }
                            }
                        }

                        if let validationMessage {
                            Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(WristlistTheme.coral)
                                .accessibilityElement(children: .combine)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                }

                Button("Save Changes") { save() }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .disabled(!hasChanges)
                    .padding(20)
                    .background(WristlistTheme.appBackground(for: colorScheme).ignoresSafeArea())
            }
            .background(WristlistTheme.appBackground(for: colorScheme).ignoresSafeArea())
            .navigationTitle("")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { cancel() }
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

    private var editHeader: some View {
        HStack(alignment: .center, spacing: 16) {
            AvatarCircle(initials: initials(from: displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? profile.displayName : displayName), palette: palette, size: 76, fontSize: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text("Edit profile")
                    .font(WristlistTheme.pageTitleFont)
                    .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(username.isEmpty ? profile.username : username)
                    .font(WristlistTheme.metadataFont)
                    .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                    .lineLimit(1)
            }
        }
    }
}

private struct EditProfileField: View {
    let title: String
    @Binding var text: String
    let prompt: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(WristlistTheme.kickerFont)
                .tracking(0.8)
                .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))

            TextField(prompt, text: $text)
                .font(.body.weight(.semibold))
                .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                .textFieldStyle(.plain)
                .padding(.vertical, 12)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(WristlistTheme.divider(for: colorScheme))
                        .frame(height: 2)
                }
        }
    }
}

private struct PaletteSwatchButton: View {
    let palette: FestivalPalette
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    Rectangle()
                        .fill(WristlistTheme.accent(for: palette))
                        .frame(height: 48)
                        .overlay(alignment: .topLeading) {
                            Rectangle()
                                .fill(WristlistTheme.secondaryAccent(for: palette))
                                .frame(width: 38, height: 18)
                        }

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.black))
                            .foregroundStyle(WristlistTheme.contrastText(for: palette))
                            .padding(7)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: WristlistTheme.cornerSmall, style: .continuous))

                Text(palette.rawValue.capitalized)
                    .font(WristlistTheme.kickerFont)
                    .tracking(0.6)
                    .foregroundStyle(isSelected ? WristlistTheme.primaryText(for: colorScheme) : WristlistTheme.secondaryText(for: colorScheme))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(palette.rawValue.capitalized) profile color")
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
