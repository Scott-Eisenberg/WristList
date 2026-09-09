//
//  SettingsView.swift
//  WristList
//

import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appearancePreference") private var appearancePreferenceRaw = AppearancePreference.system.rawValue
    @Query private var profiles: [WLProfile]

    @State private var showingResetConfirmation = false
    @State private var actionError: String?

    private var profile: WLProfile? {
        profiles.first { $0.id == WristlistDataController.currentUserID } ?? profiles.first
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Appearance", selection: $appearancePreferenceRaw) {
                        ForEach(AppearancePreference.allCases) { preference in
                            Text(preference.title).tag(preference.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Appearance selection")
                }

                if let profile {
                    Section("Notifications") {
                        Toggle("Festival reminders", isOn: Binding(get: { profile.notificationsEnabled }, set: { update(profile) { $0.notificationsEnabled = $1 }($0) }))
                            .accessibilityLabel("Festival reminders")
                        Toggle("Review likes and comments", isOn: Binding(get: { profile.reviewLikesEnabled }, set: { update(profile) { $0.reviewLikesEnabled = $1 }($0) }))
                            .accessibilityLabel("Review likes and comments")
                    }

                    Section("Privacy") {
                        Picker("Profile visibility", selection: Binding(get: { profile.privacy }, set: { newValue in update(profile) { $0.privacy = newValue } })) {
                            ForEach(ProfilePrivacy.allCases) { privacy in
                                Text(privacy.title).tag(privacy)
                            }
                        }
                        .accessibilityLabel("Profile visibility")
                    }
                }

                Section("About Wristlist") {
                    LabeledContent("Version", value: "Local MVP")
                    Text("Wristlist stores this MVP's festivals, rankings, reviews, likes, comments, and profile edits locally with SwiftData. No live backend or account system is connected yet.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Sample Data") {
                    Button("Reset Sample Data", role: .destructive) {
                        showingResetConfirmation = true
                    }
                    .accessibilityLabel("Reset sample data")
                }
            }
            .navigationTitle("Settings")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Reset sample data?", isPresented: $showingResetConfirmation, titleVisibility: .visible) {
                Button("Reset Sample Data", role: .destructive) { resetSampleData() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This removes local edits, reviews, likes, comments, saved states, and rankings, then restores the MVP sample data.")
            }
            .alert("Settings update failed", isPresented: Binding(get: { actionError != nil }, set: { if !$0 { actionError = nil } })) {
                Button("OK", role: .cancel) { actionError = nil }
            } message: {
                Text(actionError ?? "Try again.")
            }
        }
    }

    private func update(_ profile: WLProfile, mutation: (WLProfile) -> Void) {
        mutation(profile)
        profile.updatedAt = .now
        do {
            try WristlistDataController.saveIfNeeded(modelContext)
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func resetSampleData() {
        do {
            try WristlistDataController.resetSampleData(in: modelContext)
        } catch {
            actionError = error.localizedDescription
        }
    }
}

#Preview("Settings") {
    SettingsView()
        .modelContainer(PreviewContainerFactory.makeContainer())
}
