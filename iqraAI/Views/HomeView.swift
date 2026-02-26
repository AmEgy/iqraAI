import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject var quranVM: QuranViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var audioPlayer: AudioPlayerService
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                NavigationStack {
                    SurahListView()
                }
                .tabItem {
                    Label("Read", systemImage: "book")
                }
                
                NavigationStack {
                    BookmarksView()
                }
                .tabItem {
                    Label("Bookmarks", systemImage: "bookmark")
                }
                
                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
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
