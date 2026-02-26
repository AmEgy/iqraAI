import Foundation

/// Verifies the integrity of the Quran database on every app launch.
/// This checks structure (correct counts) and spot-checks specific verses
/// that any Muslim would immediately recognize if wrong.
enum QuranIntegrityChecker {
    
    struct IntegrityResult {
        let passed: Bool
        let surahCount: Int
        let verseCount: Int
        let errors: [String]
    }
    
    /// Run all checks. Call this on app launch.
    static func verify() -> IntegrityResult {
        var errors: [String] = []
        let db = QuranDatabase.shared
        
        // ── Check 1: Surah count must be exactly 114 ──
        let surahs = db.fetchAllSurahs()
        if surahs.count != 114 {
            errors.append("Surah count is \(surahs.count), expected 114")
        }
        
        // ── Check 2: Total verse count must be exactly 6236 ──
        var totalVerses = 0
        for surah in surahs {
            let verses = db.fetchVerses(surahNumber: surah.number)
            totalVerses += verses.count
            
            // Check each surah has the expected verse count
            if verses.count != surah.verseCount {
                errors.append("Surah \(surah.number) (\(surah.nameTransliteration)): has \(verses.count) verses, expected \(surah.verseCount)")
            }
            
            // Check verses are sequential (1, 2, 3, ...)
            for (index, verse) in verses.enumerated() {
                if verse.verseNumber != index + 1 {
                    errors.append("Surah \(surah.number) verse numbering gap at position \(index + 1)")
                    break
                }
            }
        }
        
        if totalVerses != 6236 {
            errors.append("Total verse count is \(totalVerses), expected 6236")
        }
        
        // ── Check 3: Spot-check well-known verses ──
        // Note: In the Tanzil Uthmani text, the Bismillah is included at the
        // start of verse 1 for all surahs except Al-Fatihah (where it IS verse 1)
        // and At-Tawbah (no Bismillah). So verse 1 of most surahs starts with
        // "بِسْمِ ٱللَّهِ" followed by the actual verse text.
        
        let spotChecks: [(Int, Int, String)] = [
            // (surah, verse, must contain this text somewhere in the verse)
            (1, 1, "بِسْمِ"),                 // Bismillah — Al-Fatihah verse 1
            (1, 2, "ٱلْحَمْدُ"),              // Alhamdulillah
            (2, 255, "ٱللَّهُ لَآ إِلَـٰهَ"),  // Ayat al-Kursi
            (36, 1, "يسٓ"),                   // Ya-Sin (after Bismillah)
            (112, 1, "قُلْ هُوَ ٱللَّهُ"),     // Al-Ikhlas (after Bismillah)
            (114, 6, "ٱلنَّاسِ"),              // Last verse of the Quran
        ]
        
        for (surah, verse, expectedText) in spotChecks {
            if let v = db.fetchVerse(surah: surah, verse: verse) {
                if !v.textArabic.contains(expectedText) {
                    errors.append("Spot-check FAILED: \(surah):\(verse) does not contain expected text")
                }
            } else {
                errors.append("Spot-check FAILED: verse \(surah):\(verse) not found")
            }
        }
        
        // ── Check 4: No empty Arabic text ──
        for surah in surahs {
            let verses = db.fetchVerses(surahNumber: surah.number)
            for verse in verses {
                if verse.textArabic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    errors.append("Empty text at \(surah.number):\(verse.verseNumber)")
                }
            }
        }
        
        let passed = errors.isEmpty
        
        if passed {
            print("✅ Quran integrity check PASSED — 114 surahs, \(totalVerses) verses, all spot-checks passed")
        } else {
            print("❌ Quran integrity check FAILED:")
            for e in errors { print("   - \(e)") }
        }
        
        return IntegrityResult(
            passed: passed,
            surahCount: surahs.count,
            verseCount: totalVerses,
            errors: errors
        )
    }
}
