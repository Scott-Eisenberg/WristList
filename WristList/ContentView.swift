import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = JournalTab.discover
    @State private var showingAdd = false
    @State private var seedError: String?

    var body: some View {
        JournalHome(tab: selectedTab)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(JournalTab.allCases) { tab in
                        Button {
                            if tab == .add { showingAdd = true } else { selectedTab = tab }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: tab == .add ? 22 : 20, weight: .medium))
                                    .frame(width: 48, height: 32)
                                    .background(tab == .add ? JournalStyle.coral : .clear, in: Capsule())
                                Text(tab.rawValue).font(.caption2.weight(selectedTab == tab ? .bold : .regular))
                            }
                            .foregroundStyle(tab == .add ? JournalStyle.ink : selectedTab == tab ? JournalStyle.violet : JournalStyle.muted)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
                    }
                }
                .padding(.horizontal, 8).padding(.top, 8)
                .background(JournalStyle.paper)
                .overlay(alignment: .top) { Divider() }
            }
            .sheet(isPresented: $showingAdd) { JournalAddView() }
            .tint(JournalStyle.violet)
            .preferredColorScheme(.light)
            .task {
                do {
                    try WristlistDataController.seedIfNeeded(in: modelContext)
                    try JournalSampleData.install(in: modelContext)
                } catch { seedError = error.localizedDescription }
            }
            .alert("Couldn’t load your journal", isPresented: Binding(get: { seedError != nil }, set: { if !$0 { seedError = nil } })) {
                Button("OK", role: .cancel) {}
            } message: { Text(seedError ?? "") }
    }
}

enum JournalTab: String, CaseIterable, Identifiable {
    case discover = "Discover", rankings = "Rankings", add = "Add", friends = "Friends", profile = "Profile"
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

#Preview("Festival journal") {
    ContentView().modelContainer(PreviewContainerFactory.makeContainer())
}
