import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appearancePreference") private var appearancePreferenceRaw = AppearancePreference.system.rawValue
    @Query private var festivals: [WLFestival]
    @Query private var profiles: [WLProfile]

    @State private var selectedTab = AppTab.home
    @State private var lastContentTab = AppTab.home
    @State private var isShowingLogFlow = false
    @State private var seedError: String?

    private var profile: WLProfile? {
        profiles.first { $0.id == WristlistDataController.currentUserID } ?? profiles.first
    }

    private var preferredColorScheme: ColorScheme? {
        AppearancePreference(rawValue: appearancePreferenceRaw)?.colorScheme
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "person.2.fill", value: AppTab.home) {
                FeedView()
            }

            Tab("Explore", systemImage: "safari.fill", value: AppTab.explore) {
                DiscoverView()
            }

            Tab("Log", systemImage: "plus.circle.fill", value: AppTab.log) {
                Color.clear
                    .accessibilityHidden(true)
            }

            Tab("My Festivals", systemImage: "list.number", value: AppTab.myFestivals) {
                MyListView()
            }

            Tab("Profile", systemImage: "person.crop.circle", value: AppTab.profile) {
                ProfileView()
            }
        }
        .tabViewStyle(.tabBarOnly)
        .tint(WristlistTheme.brand)
        .preferredColorScheme(preferredColorScheme)
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .log {
                selectedTab = lastContentTab
                isShowingLogFlow = true
            } else {
                lastContentTab = newTab
            }
        }
        .sheet(isPresented: $isShowingLogFlow) {
            ReviewFlowView(festivals: festivals, profile: profile)
        }
        .task {
            do {
                try WristlistDataController.seedIfNeeded(in: modelContext)
            } catch {
                seedError = error.localizedDescription
            }
        }
        .alert("Couldn’t open Wristlist", isPresented: Binding(
            get: { seedError != nil },
            set: { isPresented in
                if !isPresented {
                    seedError = nil
                }
            }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(seedError ?? "Your festival data could not be loaded.")
        }
    }
}

private enum AppTab: Hashable {
    case home
    case explore
    case log
    case myFestivals
    case profile
}

// Retained for the standalone journal previews and compatibility with JournalHome.
enum JournalTab: String, CaseIterable, Identifiable {
    case discover = "Discover"
    case rankings = "Rankings"
    case add = "Add"
    case friends = "Friends"
    case profile = "Profile"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .discover: "sparkle.magnifyingglass"
        case .rankings: "list.number"
        case .add: "plus"
        case .friends: "person.2"
        case .profile: "person.crop.circle"
        }
    }
}

#Preview("Wristlist") {
    ContentView()
        .modelContainer(PreviewContainerFactory.makeContainer())
}
