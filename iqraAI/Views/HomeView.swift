import SwiftUI

struct HomeView: View {

    @EnvironmentObject var quranVM: QuranViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var audioPlayer: AudioPlayerService

    @State private var selectedTab: Int = 0
    @State private var readNavPath = NavigationPath()
    @State private var bookmarksNavPath = NavigationPath()
    @State private var settingsNavPath = NavigationPath()

    /// Custom binding: tapping the already-selected tab pops its NavigationStack to root.
    private var tabBinding: Binding<Int> {
        Binding(
            get: { selectedTab },
            set: { newTab in
                if newTab == selectedTab {
                    // Re-tapped the same tab — pop to root
                    switch selectedTab {
                    case 0: readNavPath = NavigationPath()
                    case 1: bookmarksNavPath = NavigationPath()
                    case 2: settingsNavPath = NavigationPath()
                    default: break
                    }
                }
                selectedTab = newTab
            }
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: tabBinding) {
                NavigationStack(path: $readNavPath) {
                    SurahListView()
                }
                .tabItem {
                    Label("Read", systemImage: "book")
                }
                .tag(0)

                NavigationStack(path: $bookmarksNavPath) {
                    BookmarksView()
                }
                .tabItem {
                    Label("Bookmarks", systemImage: "bookmark")
                }
                .tag(1)

                NavigationStack(path: $settingsNavPath) {
                    SettingsView()
                }
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(2)
            }
            .tint(.green)

            // Mini player bar above tab bar
            MiniPlayerBar()
                .environmentObject(audioPlayer)
                .padding(.bottom, 49) // tab bar height
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(QuranViewModel())
        .environmentObject(SettingsViewModel())
        .environmentObject(AudioPlayerService.shared)
}
