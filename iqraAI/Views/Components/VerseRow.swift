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
    @State private var showWordByWord: Bool = false
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
            // Word by Word — PRD QR-04 (moved from in-text tap to here to preserve Arabic rendering)
            Button("Word by Word") {
                showWordByWord = true
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
        // Word by Word sheet (PRD QR-04)
        .sheet(isPresented: $showWordByWord) {
            WordByWordView(verse: verse)
                .environmentObject(settingsVM)
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
    // Rendered as a single text run so Arabic font shaping and RTL line-wrapping
    // work correctly. Never split into individual word views — that breaks shaping.

    private var arabicText: some View {
        let verseEndMarker = " \u{06DD}\(verse.arabicVerseNumber)"

        // Word-highlight mode during audio playback with timestamps
        if isCurrentlyPlaying && !audioPlayer.wordTimestamps.isEmpty {
            return AnyView(highlightedArabicText(verseEndMarker: verseEndMarker))
        }

        // Tajweed colored text
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

        // Plain Arabic — single Text view for correct shaping and RTL wrapping
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

// MARK: - Word by Word Sheet (PRD QR-04)
// Each word displayed individually with its translation below.
// Shown as a sheet from the verse action sheet ("Word by Word" button).

struct WordByWordView: View {

    let verse: Verse
    @EnvironmentObject var settingsVM: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var words: [(arabic: String, translation: String, transliteration: String)] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading word meanings…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        // RTL flow: words displayed right-to-left in a wrapping grid
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 100, maximum: 140))],
                            spacing: 12
                        ) {
                            ForEach(words.indices, id: \.self) { i in
                                WordCard(
                                    arabic: words[i].arabic,
                                    translation: words[i].translation,
                                    transliteration: words[i].transliteration,
                                    index: i + 1,
                                    fontSize: settingsVM.fontSize
                                )
                            }
                        }
                        .padding()
                        .environment(\.layoutDirection, .rightToLeft)
                    }
                }
            }
            .navigationTitle("\(verse.verseKey) — Word by Word")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task { await loadWords() }
    }

    private func loadWords() async {
        let langId = TranslationService.shared.selectedLanguage.id
        let urlStr = "https://api.quran.com/api/v4/verses/by_key/\(verse.verseKey)?words=true&word_fields=text_uthmani,transliteration,translation&translation_fields=text&translations=\(langId)"
        guard let url = URL(string: urlStr) else { isLoading = false; return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let v = json?["verse"] as? [String: Any],
                  let rawWords = v["words"] as? [[String: Any]] else {
                isLoading = false; return
            }

            words = rawWords.compactMap { w in
                // Skip the verse-end glyph (type = "end")
                guard (w["char_type_name"] as? String) != "end" else { return nil }
                let arabic = w["text_uthmani"] as? String ?? (w["text"] as? String ?? "")
                let translit: String
                if let t = w["transliteration"] as? [String: Any] { translit = t["text"] as? String ?? "" }
                else { translit = w["transliteration"] as? String ?? "" }
                let meaning: String
                if let t = w["translation"] as? [String: Any] { meaning = t["text"] as? String ?? "" }
                else { meaning = "" }
                return (arabic: arabic, translation: meaning, transliteration: translit)
            }
        } catch {}

        isLoading = false
    }
}

// MARK: - Word Card

private struct WordCard: View {
    let arabic: String
    let translation: String
    let transliteration: String
    let index: Int
    let fontSize: CGFloat

    var body: some View {
        VStack(spacing: 6) {
            Text(arabic)
                .font(.custom(AppConstants.arabicFontName, size: min(fontSize, 28), relativeTo: .title2))
                .multilineTextAlignment(.center)
                .environment(\.layoutDirection, .rightToLeft)

            if !transliteration.isEmpty {
                Text(transliteration)
                    .font(.caption2.italic())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if !translation.isEmpty {
                Text(translation)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.green.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(.green.opacity(0.15), lineWidth: 1)
                )
        )
    }
}
