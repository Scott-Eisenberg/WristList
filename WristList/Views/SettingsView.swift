//
//  SettingsView.swift
//  WristList
//

import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appearancePreference") private var appearancePreferenceRaw = AppearancePreference.system.rawValue
    @Query private var profiles: [WLProfile]

    @State private var showingResetConfirmation = false
    @State private var actionError: String?

    private var profile: WLProfile? {
        profiles.first { $0.id == WristlistDataController.currentUserID } ?? profiles.first
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Settings")
                            .font(WristlistTheme.pageTitleFont)
                            .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))

                        Text("Control how your festival shelf appears and who can see your reviews.")
                            .font(.body)
                            .lineSpacing(3)
                            .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        SectionTitleView(title: "Appearance")

                        HStack(spacing: 12) {
                            ForEach(AppearancePreference.allCases) { preference in
                                SettingsOptionButton(
                                    title: preference.title,
                                    systemImage: appearanceIcon(for: preference),
                                    isSelected: appearancePreferenceRaw == preference.rawValue,
                                    action: { appearancePreferenceRaw = preference.rawValue }
                                )
                            }
                        }
                        .accessibilityLabel("Appearance selection")
                    }

                    if let profile {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitleView(title: "Notifications")

                            Toggle("Festival reminders", isOn: Binding(get: { profile.notificationsEnabled }, set: { newValue in
                                update(profile) { profile in
                                    profile.notificationsEnabled = newValue
                                }
                            }))
                            .font(.headline.weight(.black))
                            .padding(.vertical, 10)
                            .overlay(alignment: .bottom) {
                                EditorialDivider()
                            }
                            .accessibilityLabel("Festival reminders")

                            Toggle("Review likes and comments", isOn: Binding(get: { profile.reviewLikesEnabled }, set: { newValue in
                                update(profile) { profile in
                                    profile.reviewLikesEnabled = newValue
                                }
                            }))
                            .font(.headline.weight(.black))
                            .padding(.vertical, 10)
                            .overlay(alignment: .bottom) {
                                EditorialDivider()
                            }
                            .accessibilityLabel("Review likes and comments")
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            SectionTitleView(title: "Privacy")

                            HStack(spacing: 12) {
                                ForEach(ProfilePrivacy.allCases) { privacy in
                                    SettingsOptionButton(
                                        title: privacy.title,
                                        systemImage: privacyIcon(for: privacy),
                                        isSelected: profile.privacy == privacy,
                                        action: { update(profile) { $0.privacy = privacy } }
                                    )
                                }
                            }
                            .accessibilityLabel("Profile visibility")
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitleView(title: "About Wristlist")

                        HStack(alignment: .firstTextBaseline) {
                            Text("Version")
                                .font(.headline.weight(.black))
                                .foregroundStyle(WristlistTheme.primaryText(for: colorScheme))
                            Spacer()
                            Text("Local")
                                .font(WristlistTheme.metadataFont)
                                .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                        }
                        .padding(.vertical, 10)
                        .overlay(alignment: .bottom) {
                            EditorialDivider()
                        }

                        Text("Festivals, rankings, reviews, likes, comments, and profile edits are stored locally on this device. No live backend or account system is connected yet.")
                            .font(.subheadline)
                            .lineSpacing(3)
                            .foregroundStyle(WristlistTheme.secondaryText(for: colorScheme))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        SectionTitleView(title: "Sample Data")

                        Button("Reset Sample Data", role: .destructive) {
                            showingResetConfirmation = true
                        }
                        .font(.headline.weight(.black))
                        .foregroundStyle(WristlistTheme.coral)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(alignment: .bottom) {
                            EditorialDivider()
                        }
                        .accessibilityLabel("Reset sample data")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 34)
            }
            .background(WristlistTheme.appBackground(for: colorScheme).ignoresSafeArea())
            .navigationTitle("")
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

    private func appearanceIcon(for preference: AppearancePreference) -> String {
        switch preference {
        case .system:
            "circle.lefthalf.filled"
        case .light:
            "sun.max"
        case .dark:
            "moon"
        }
    }

    private func privacyIcon(for privacy: ProfilePrivacy) -> String {
        switch privacy {
        case .friends:
            "person.2"
        case .privateProfile:
            "lock"
        case .publicProfile:
            "globe"
        }
    }
}

private struct SettingsOptionButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 9) {
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .black))

                Text(title.uppercased())
                    .font(WristlistTheme.kickerFont)
                    .tracking(0.7)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                Rectangle()
                    .fill(isSelected ? WristlistTheme.brand : WristlistTheme.divider(for: colorScheme))
                    .frame(height: 3)
            }
            .foregroundStyle(isSelected ? WristlistTheme.primaryText(for: colorScheme) : WristlistTheme.secondaryText(for: colorScheme))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

#Preview("Settings") {
    SettingsView()
        .modelContainer(PreviewContainerFactory.makeContainer())
}
