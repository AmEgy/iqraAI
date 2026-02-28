import Foundation
import Combine

// MARK: - Translation Language

struct TranslationLanguage: Identifiable, Hashable {
    let id: String          // Quran Foundation identifier, e.g. "en.sahih"
    let displayName: String
    let nativeName: String
    /// Numeric translation resource ID for Quran Foundation v4 API
    let quranComTranslationId: Int
}

// MARK: - On-demand Translation Service
// Fetches translations from Quran Foundation API and caches them in-memory.
// User's chosen language is persisted via QuranDatabase user_settings.
// Data is never bundled — fetched lazily when user selects a language (PRD QR-05).

@MainActor
final class TranslationService: ObservableObject {

    static let shared = TranslationService()

    static let supportedLanguages: [TranslationLanguage] = [
        TranslationLanguage(id: "en.sahih",      displayName: "English",    nativeName: "English",    quranComTranslationId: 131),
        TranslationLanguage(id: "ur.jalandhry",  displayName: "Urdu",       nativeName: "اردو",        quranComTranslationId: 97),
        TranslationLanguage(id: "fr.hamidullah", displayName: "French",     nativeName: "Français",   quranComTranslationId: 31),
        TranslationLanguage(id: "tr.diyanet",    displayName: "Turkish",    nativeName: "Türkçe",     quranComTranslationId: 77),
        TranslationLanguage(id: "id.indonesian", displayName: "Indonesian", nativeName: "Bahasa",     quranComTranslationId: 33),
    ]

    @Published var selectedLanguage: TranslationLanguage = supportedLanguages[0]
    @Published var isLoading = false

    /// Cache: [languageId: [verseKey: translationText]]
    private var cache: [String: [String: String]] = [:]
    private let db = QuranDatabase.shared

    private init() {
        if let savedId = db.getSetting("translation_language"),
           let lang = Self.supportedLanguages.first(where: { $0.id == savedId }) {
            selectedLanguage = lang
        }
    }

    func setLanguage(_ language: TranslationLanguage) {
        selectedLanguage = language
        db.setSetting("translation_language", value: language.id)
    }

    // MARK: - Full Verse Translation

    /// Fetch the full translation text for a single verse in the selected language.
    /// Returns nil if English (use the bundled DB text) or on failure.
    func fetchVerseTranslation(surah: Int, verse: Int) async -> String? {
        let lang = selectedLanguage
        // English is already bundled in DB — no network call needed
        if lang.id == "en.sahih" { return nil }

        let verseKey = "\(surah):\(verse)"
        let cacheKey = lang.id

        if let cached = cache[cacheKey]?[verseKey] {
            return cached
        }

        let urlStr = "https://api.quran.com/api/v4/verses/by_key/\(verseKey)?translations=\(lang.quranComTranslationId)"
        guard let url = URL(string: urlStr) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let verseObj = json?["verse"] as? [String: Any],
                  let translations = verseObj["translations"] as? [[String: Any]],
                  let first = translations.first,
                  let text = first["text"] as? String else { return nil }

            // Strip any HTML tags that may be in the translation
            let clean = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            if cache[cacheKey] == nil { cache[cacheKey] = [:] }
            cache[cacheKey]![verseKey] = clean
            return clean
        } catch {
            return nil
        }
    }

    // MARK: - Word-by-word Translation

    /// Fetch word-by-word translation for a single verse in the selected language.
    func fetchWordTranslations(surah: Int, verse: Int) async -> [Int: String] {
        let lang = selectedLanguage
        let verseKey = "\(surah):\(verse)"
        let wordCacheKey = "words_\(lang.id)"

        if let cached = cache[wordCacheKey]?[verseKey] {
            return parseWordCache(cached)
        }

        // Use language-specific translation ID in the request
        let urlStr = "https://api.quran.com/api/v4/verses/by_key/\(verseKey)?words=true&translation_fields=text&word_fields=text_uthmani,translation&translations=\(lang.quranComTranslationId)"
        guard let url = URL(string: urlStr) else { return [:] }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let verseObj = json?["verse"] as? [String: Any],
                  let words = verseObj["words"] as? [[String: Any]] else { return [:] }

            var result: [Int: String] = [:]
            for (index, word) in words.enumerated() {
                if let translation = word["translation"] as? [String: Any],
                   let text = translation["text"] as? String {
                    result[index] = text
                }
            }
            return result
        } catch {
            return [:]
        }
    }

    private func parseWordCache(_ raw: String) -> [Int: String] { [:] }
}
