import SwiftUI

struct VerseRow: View {
    
    let verse: Verse
    
    @EnvironmentObject var quranVM: QuranViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var audioPlayer: AudioPlayerService
    @State private var showActions: Bool = false
    
    private var isBookmarked: Bool {
        quranVM.isBookmarked(surah: verse.surahNumber, verse: verse.verseNumber)
    }
    
    private var isCurrentlyPlaying: Bool {
        audioPlayer.currentSurah == verse.surahNumber &&
        audioPlayer.currentVerse == verse.verseNumber &&
        audioPlayer.isActive
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            verseNumberBar
            arabicText
            
            if settingsVM.showTranslation, let english = verse.textEnglish, !english.isEmpty {
                translationText(english)
            }
            
            Divider().padding(.top, 8)
        }
        .padding(.vertical, 8)
        .background(isCurrentlyPlaying ? Color.green.opacity(0.05) : Color.clear)
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            quranVM.updateReadingPosition(surah: verse.surahNumber, verse: verse.verseNumber)
        }
        .onLongPressGesture {
            showActions = true
        }
        .confirmationDialog("Verse \(verse.verseKey)", isPresented: $showActions) {
            Button(isBookmarked ? "Remove Bookmark" : "Add Bookmark") {
                quranVM.toggleBookmark(surah: verse.surahNumber, verse: verse.verseNumber)
            }
            Button("Copy Arabic Text") {
                UIPasteboard.general.string = verse.textArabic
            }
            if let english = verse.textEnglish, !english.isEmpty {
                Button("Copy Translation") {
                    UIPasteboard.general.string = english
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    // MARK: - Subviews
    
    private var verseNumberBar: some View {
        HStack {
            Text(verse.verseKey)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Capsule().fill(.secondary.opacity(0.1)))
            
            Text("Juz \(verse.juzNumber)")
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            // Bookmark
            Button {
                quranVM.toggleBookmark(surah: verse.surahNumber, verse: verse.verseNumber)
            } label: {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.body)
                    .foregroundStyle(isBookmarked ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            // Play this verse
            Button {
                if isCurrentlyPlaying {
                    audioPlayer.togglePlayPause()
                } else {
                    audioPlayer.playVerse(surah: verse.surahNumber, verse: verse.verseNumber)
                }
            } label: {
                Image(systemName: isCurrentlyPlaying && audioPlayer.isPlaying
                      ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title3)
                    .foregroundStyle(isCurrentlyPlaying ? .green : .green.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
    }
    
    private var arabicText: some View {
        let verseEndMarker = " \u{06DD}\(verse.arabicVerseNumber)"
        
        // If playing with word timestamps, show word highlighting
        if isCurrentlyPlaying && !audioPlayer.wordTimestamps.isEmpty {
            return AnyView(
                highlightedArabicText(verseEndMarker: verseEndMarker)
            )
        }
        
        // If tajweed text available and tajweed is ON, show colored text
        if settingsVM.showTajweedColors, let tajweedText = verse.textTajweed, !tajweedText.isEmpty {
            return AnyView(
                TajweedParser.coloredText(
                    from: tajweedText,
                    fontSize: settingsVM.fontSize,
                    theme: settingsVM.theme,
                    showTajweed: true
                )
                .multilineTextAlignment(.trailing)
                .lineSpacing(settingsVM.fontSize * 0.5)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)
            )
        }
        
        // Fallback: plain Arabic text
        return AnyView(
            Text(verse.textArabic + verseEndMarker)
                .font(.custom(AppConstants.arabicFontName, size: settingsVM.fontSize, relativeTo: .title))
                .foregroundStyle(settingsVM.theme.textColor)
                .multilineTextAlignment(.trailing)
                .lineSpacing(settingsVM.fontSize * 0.5)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)
        )
    }
    
    private func highlightedArabicText(verseEndMarker: String) -> some View {
        let words = verse.textArabic.components(separatedBy: " ")
        let highlighted = audioPlayer.highlightedWordIndex
        
        var fullText = Text("")
        for (index, word) in words.enumerated() {
            let color: Color
            if index == highlighted {
                color = .green
            } else if index < highlighted {
                color = settingsVM.theme.textColor.opacity(0.6)
            } else {
                color = settingsVM.theme.textColor
            }
            
            let wordText = Text(word).foregroundColor(color)
            if index > 0 {
                fullText = fullText + Text(" ") + wordText
            } else {
                fullText = wordText
            }
        }
        
        fullText = fullText + Text(verseEndMarker).foregroundColor(settingsVM.theme.textColor.opacity(0.5))
        
        return fullText
            .font(.custom(AppConstants.arabicFontName, size: settingsVM.fontSize, relativeTo: .title))
            .multilineTextAlignment(.trailing)
            .lineSpacing(settingsVM.fontSize * 0.5)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .environment(\.layoutDirection, .rightToLeft)
    }
    
    private func translationText(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }
}
