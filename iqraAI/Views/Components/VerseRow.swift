import SwiftUI

struct VerseRow: View {

    let verse: Verse
    /// Total verses in this surah — needed for "play from here" continuous playback.
    /// When 0 (default, e.g. Juz/Page/Hizb views), auto-looked up from DB.
    var surahTotalVerses: Int = 0

    private var resolvedTotalVerses: Int {
        if surahTotalVerses > 0 { return surahTotalVerses }
        return QuranDatabase.shared.fetchSurah(number: verse.surahNumber)?.verseCount ?? verse.verseNumber
    }

    @EnvironmentObject var quranVM: QuranViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var audioPlayer: AudioPlayerService
    @ObservedObject private var translationService = TranslationService.shared

    @State private var showActions: Bool = false
    @State private var tappedWordIndex: Int? = nil
    @State private var wordTranslations: [Int: String] = [:]
    @State private var transliterationText: String? = nil
    @State private var fetchedTranslation: String? = nil

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

            // Transliteration (PRD QR-06)
            if settingsVM.showTransliteration, let translit = transliterationText, !translit.isEmpty {
                Text(translit)
                    .font(.footnote.italic())
                    .foregroundStyle(.secondary.opacity(0.8))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if settingsVM.showTranslation {
                let displayText = fetchedTranslation ?? verse.textEnglish ?? ""
                if !displayText.isEmpty {
                    translationText(displayText)
                }
            }

            Divider().padding(.top, 8)
        }
        .padding(.vertical, 8)
        .background(isCurrentlyPlaying ? Color.green.opacity(0.05) : Color.clear)
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            showActions = true
        }
        .confirmationDialog("Verse \(verse.verseKey)", isPresented: $showActions) {
            Button(isBookmarked ? "Remove Bookmark" : "Add Bookmark") {
                quranVM.toggleBookmark(surah: verse.surahNumber, verse: verse.verseNumber)
            }
            Button("Play from Here") {
                let total = resolvedTotalVerses
                audioPlayer.playSurah(
                    surah: verse.surahNumber,
                    fromVerse: verse.verseNumber,
                    totalVerses: total
                )
            }
            Button("Play This Verse Only") {
                audioPlayer.playVerse(surah: verse.surahNumber, verse: verse.verseNumber)
            }
            Button("Copy Arabic Text") {
                UIPasteboard.general.string = verse.textArabic
            }
            if let english = verse.textEnglish, !english.isEmpty {
                Button("Copy Translation") {
                    UIPasteboard.general.string = fetchedTranslation ?? english
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        // Word-by-word popover (PRD QR-04)
        .popover(isPresented: Binding(
            get: { tappedWordIndex != nil },
            set: { if !$0 { tappedWordIndex = nil } }
        )) {
            if let idx = tappedWordIndex {
                WordPopoverView(
                    word: arabicWords[safe: idx] ?? "",
                    translation: wordTranslations[idx] ?? "Loading…",
                    wordIndex: idx + 1,
                    total: arabicWords.count
                )
            }
        }
        .task(id: settingsVM.showTransliteration) {
            if settingsVM.showTransliteration && transliterationText == nil {
                await loadTransliteration()
            }
        }
        // Reload translation whenever the selected language changes
        .task(id: translationService.selectedLanguage.id) {
            fetchedTranslation = await translationService.fetchVerseTranslation(
                surah: verse.surahNumber,
                verse: verse.verseNumber
            )
        }
    }

    // MARK: - Arabic words helper

    private var arabicWords: [String] {
        verse.textArabic.components(separatedBy: " ")
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

            // Play button — plays from this verse to end of surah
            Button {
                if isCurrentlyPlaying {
                    audioPlayer.togglePlayPause()
                } else {
                    let total = resolvedTotalVerses
                    audioPlayer.playSurah(
                        surah: verse.surahNumber,
                        fromVerse: verse.verseNumber,
                        totalVerses: total
                    )
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

    // MARK: - Arabic Text
    // Always renders tappable words so the word-meaning popover always works.
    // Word-level highlighting takes priority when audio is playing with timestamps.

    private var arabicText: some View {
        let verseEndMarker = " \u{06DD}\(verse.arabicVerseNumber)"

        if isCurrentlyPlaying && !audioPlayer.wordTimestamps.isEmpty {
            return AnyView(highlightedArabicText(verseEndMarker: verseEndMarker))
        }

        return AnyView(tappableArabicText(verseEndMarker: verseEndMarker))
    }

    /// Tappable word-by-word Arabic text.
    /// Each word tap opens the translation popover (PRD QR-04).
    private func tappableArabicText(verseEndMarker: String) -> some View {
        let words = arabicWords
        return HStack(spacing: 4) {
            ForEach(words.indices.reversed(), id: \.self) { index in
                Text(words[index])
                    .font(.custom(AppConstants.arabicFontName, size: settingsVM.fontSize, relativeTo: .title))
                    .foregroundStyle(settingsVM.theme.textColor)
                    .onTapGesture {
                        tappedWordIndex = index
                        Task { await loadWordTranslations() }
                    }
            }
            Text(verseEndMarker)
                .font(.custom(AppConstants.arabicFontName, size: settingsVM.fontSize, relativeTo: .title))
                .foregroundStyle(settingsVM.theme.textColor.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .environment(\.layoutDirection, .rightToLeft)
        .lineSpacing(settingsVM.fontSize * 0.5)
    }

    private func highlightedArabicText(verseEndMarker: String) -> some View {
        let words = arabicWords
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
            fullText = index > 0 ? fullText + Text(" ") + wordText : wordText
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

    // MARK: - Data loading

    private func loadWordTranslations() async {
        let results = await TranslationService.shared.fetchWordTranslations(
            surah: verse.surahNumber,
            verse: verse.verseNumber
        )
        wordTranslations = results
    }

    private func loadTransliteration() async {
        let urlStr = "https://api.quran.com/api/v4/verses/by_key/\(verse.verseKey)?words=true&word_fields=transliteration"
        guard let url = URL(string: urlStr) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let v = json?["verse"] as? [String: Any],
                  let words = v["words"] as? [[String: Any]] else { return }
            let parts = words.compactMap { w -> String? in
                if let translit = w["transliteration"] as? [String: Any] {
                    return translit["text"] as? String
                }
                return w["transliteration"] as? String
            }
            transliterationText = parts.joined(separator: " ")
        } catch {}
    }
}

// MARK: - Word Popover (PRD QR-04)

private struct WordPopoverView: View {
    let word: String
    let translation: String
    let wordIndex: Int
    let total: Int

    var body: some View {
        VStack(spacing: 12) {
            Text(word)
                .font(.system(size: 32, weight: .regular))
                .environment(\.layoutDirection, .rightToLeft)
                .foregroundStyle(.primary)

            Divider()

            Text(translation)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("Word \(wordIndex) of \(total)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(20)
        .frame(minWidth: 200, maxWidth: 280)
        .presentationCompactAdaptation(.popover)
    }
}

// MARK: - Safe Array Subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
