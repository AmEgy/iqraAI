import SwiftUI

struct VerseReaderView: View {
    
    let surahNumber: Int
    
    @EnvironmentObject var quranVM: QuranViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var audioPlayer: AudioPlayerService
    
    @State private var surah: Surah?
    @State private var verses: [Verse] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Audio controls bar
            if let surah {
                AudioControlsView(surahNumber: surahNumber, totalVerses: surah.verseCount)
                    .environmentObject(audioPlayer)
            }
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if let surah {
                            SurahHeader(surah: surah)
                                .padding(.bottom, 12)
                                .id("top")
                        }
                        
                        ForEach(verses) { verse in
                            VerseRow(verse: verse)
                                .id(verse.verseNumber)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
                .background(settingsVM.theme.backgroundColor)
                .onAppear {
                    loadData()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        proxy.scrollTo("top", anchor: .top)
                    }
                }
                // Auto-scroll to current playing verse
                .onChange(of: audioPlayer.currentVerse) { _, newVerse in
                    if audioPlayer.currentSurah == surahNumber {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(newVerse, anchor: .center)
                        }
                    }
                }
            }
        }
        .navigationTitle(surah?.nameTransliteration ?? "Loading...")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        settingsVM.showTranslation.toggle()
                    } label: {
                        if settingsVM.showTranslation {
                            Label("Hide Translation", systemImage: "text.badge.minus")
                        } else {
                            Label("Show Translation", systemImage: "text.badge.plus")
                        }
                    }
                    
                    Button {
                        settingsVM.showTajweedColors.toggle()
                    } label: {
                        if settingsVM.showTajweedColors {
                            Label("Hide Tajweed Colors", systemImage: "paintpalette")
                        } else {
                            Label("Show Tajweed Colors", systemImage: "paintpalette.fill")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onDisappear {
            quranVM.updateReadingPosition(surah: surahNumber, verse: 1)
        }
    }
    
    private func loadData() {
        let db = QuranDatabase.shared
        surah = db.fetchSurah(number: surahNumber)
        verses = db.fetchVerses(surahNumber: surahNumber)
    }
}

#Preview {
    NavigationStack {
        VerseReaderView(surahNumber: 1)
    }
    .environmentObject(QuranViewModel())
    .environmentObject(SettingsViewModel())
    .environmentObject(AudioPlayerService.shared)
}
