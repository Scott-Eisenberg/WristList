//
//  ContentView.swift
//  WristList
//
//  Created by Scott Eisenberg on 9/7/26.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appearancePreference") private var appearancePreferenceRaw = AppearancePreference.system.rawValue
    @State private var seedError: String?

    private var appearancePreference: AppearancePreference {
        AppearancePreference(rawValue: appearancePreferenceRaw) ?? .system
    }

    var body: some View {
        TabView {
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "sparkles.rectangle.stack")
                }

            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }

            MyListView()
                .tabItem {
                    Label("My List", systemImage: "list.bullet.clipboard")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        .tint(WristlistTheme.coral)
        .preferredColorScheme(appearancePreference.colorScheme)
        .task {
            do {
                try WristlistDataController.seedIfNeeded(in: modelContext)
            } catch {
                seedError = error.localizedDescription
            }
        }
        .alert("Could not prepare local data", isPresented: Binding(get: { seedError != nil }, set: { if !$0 { seedError = nil } })) {
            Button("OK", role: .cancel) { seedError = nil }
        } message: {
            Text(seedError ?? "Try again.")
        }
    }
}

#Preview("App Shell") {
    ContentView()
        .modelContainer(PreviewContainerFactory.makeContainer())
        .preferredColorScheme(.dark)
}
