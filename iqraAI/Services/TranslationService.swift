import Foundation
import Combine

// MARK: - Translation Language

struct TranslationLanguage: Identifiable, Hashable {
    let id: String          // Quran Foundation identifier, e.g. "en.sahih"
    let displayName: String
    let nativeName: String
}

// MARK: - On-demand Translation Service
// Fetches translations from Quran Foundation API and caches them in-memory.
// User's chosen language is persisted via QuranDatabase user_settings.
// Data is never bundled — fetched lazily when user selects a language (PRD QR-05).

@MainActor
final class TranslationService: ObservableObject {

    static let shared = TranslationService()

    // Quran Foundation translation identifiers
    static let supportedLanguages: [TranslationLanguage] = [
        TranslationLanguage(id: "en.sahih",  displayName: "English",    nativeName: "English"),
        TranslationLanguage(id: "ur.jalandhry", displayName: "Urdu",    nativeName: "اردو"),
        TranslationLanguage(id: "fr.hamidullah", displayName: "French", nativeName: "Français"),
        TranslationLanguage(id: "tr.diyanet",    displayName: "Turkish", nativeName: "Türkçe"),
        TranslationLanguage(id: "id.indonesian", displayName: "Indonesian", nativeName: "Bahasa"),
    ]

    @Published var selectedLanguage: TranslationLanguage = supportedLanguages[0]
    @Published var isLoading = false

    /// Cache: [languageId: [verseKey: translationText]]
    private var cache: [String: [String: String]] = [:]
    private let db = QuranDatabase.shared

    private init() {
        // Restore persisted language
        if let savedId = db.getSetting("translation_language"),
           let lang = Self.supportedLanguages.first(where: { $0.id == savedId }) {
            selectedLanguage = lang
        }
    }

    func setLanguage(_ language: TranslationLanguage) {
        selectedLanguage = language
        db.setSetting("translation_language", value: language.id)
    }

    /// Fetch word-by-word translation for a single verse.
    /// Returns dict keyed by 0-based word index → translation string.
    func fetchWordTranslations(surah: Int, verse: Int) async -> [Int: String] {
        let langId = selectedLanguage.id
        let verseKey = "\(surah):\(verse)"

        // Check word-level cache
        let wordCacheKey = "words_\(langId)"
        if let cached = cache[wordCacheKey]?[verseKey] {
            return parseWordCache(cached)
        }

        let urlStr = "https://api.quran.com/api/v4/verses/by_key/\(verseKey)?words=true&translation_fields=text&word_fields=text_uthmani,translation"
        guard let url = URL(string: urlStr) else { return [:] }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let verse = json?["verse"] as? [String: Any],
                  let words = verse["words"] as? [[String: Any]] else { return [:] }

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
