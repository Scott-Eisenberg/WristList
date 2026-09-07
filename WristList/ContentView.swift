//
//  ContentView.swift
//  WristList
//
//  Created by Scott Eisenberg on 9/7/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "sparkles.rectangle.stack")
                }

            PlaceholderTabView(
                title: "Discover",
                subtitle: "Search festivals, compare lineups, and find the next weekend worth planning around.",
                systemImage: "magnifyingglass",
                palette: .violet
            )
            .tabItem {
                Label("Discover", systemImage: "magnifyingglass")
            }

            PlaceholderTabView(
                title: "My List",
                subtitle: "Keep track of festivals you have saved, ranked, attended, or want to hit next.",
                systemImage: "list.bullet.clipboard",
                palette: .sunset
            )
            .tabItem {
                Label("My List", systemImage: "list.bullet.clipboard")
            }

            PlaceholderTabView(
                title: "Profile",
                subtitle: "Your festival history, stats, favorite cities, and all-time rankings will live here.",
                systemImage: "person.crop.circle",
                palette: .electric
            )
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
        }
        .tint(WristlistTheme.coral)
    }
}

#Preview("App Shell") {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
        .preferredColorScheme(.dark)
}
