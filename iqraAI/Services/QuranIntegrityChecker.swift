import Foundation
import CryptoKit

// MARK: - Quran Integrity Checker
//
// Runs on every app launch. Two tiers of checks:
//
// TIER 1 — Cryptographic (SHA-256 file hash)
//   Computes the SHA-256 hash of the bundled quran.db file and compares it
//   against the value hardcoded in AppConstants.quranDBChecksum.
//   This catches any file corruption, accidental replacement, or tampering.
//   If this fails, the app will NOT display any Quranic text.
//
// TIER 2 — Structural (row counts + spot-checks)
//   Verifies 114 surahs, 6,236 verses, sequential numbering, and that
//   well-known verses contain the expected text.
//   These run even if the hash passes, as a double-check.

enum QuranIntegrityChecker {

    struct IntegrityResult {
        let passed: Bool
        let hashVerified: Bool
        let surahCount: Int
        let verseCount: Int
        let errors: [String]
    }

    // MARK: - Public entry point

    /// Call this once on app launch, off the main thread.
    static func verify() -> IntegrityResult {
        var errors: [String] = []

        // ── TIER 1: SHA-256 file hash ─────────────────────────────────────
        let hashVerified = verifyFileHash(errors: &errors)

        // ── TIER 2: Structural checks ─────────────────────────────────────
        let db = QuranDatabase.shared
        let surahs = db.fetchAllSurahs()

        // Check 1: Surah count
        if surahs.count != AppConstants.totalSurahs {
            errors.append("Surah count is \(surahs.count), expected \(AppConstants.totalSurahs)")
        }

        // Check 2: Total verse count + per-surah count + sequential numbering
        var totalVerses = 0
        for surah in surahs {
            let verses = db.fetchVerses(surahNumber: surah.number)
            totalVerses += verses.count

            if verses.count != surah.verseCount {
                errors.append("Surah \(surah.number) (\(surah.nameTransliteration)): has \(verses.count) verses, expected \(surah.verseCount)")
            }

            for (index, verse) in verses.enumerated() {
                if verse.verseNumber != index + 1 {
                    errors.append("Surah \(surah.number) numbering gap at position \(index + 1)")
                    break
                }
            }
        }

        if totalVerses != AppConstants.totalVerses {
            errors.append("Total verse count is \(totalVerses), expected \(AppConstants.totalVerses)")
        }

        // Check 3: Spot-check well-known verses
        // Any Muslim would immediately notice if these were wrong.
        let spotChecks: [(surah: Int, verse: Int, mustContain: String, label: String)] = [
            (1,   1,   "بِسْمِ",                 "Surah Al-Fatihah 1:1 (Bismillah)"),
            (1,   2,   "ٱلْحَمْدُ",              "Surah Al-Fatihah 1:2 (Alhamdulillah)"),
            (1,   5,   "إِيَّاكَ",               "Surah Al-Fatihah 1:5 (Iyyaka)"),
            (2,   255, "ٱللَّهُ لَآ إِلَـٰهَ",   "Ayat al-Kursi 2:255"),
            (18,  1,   "ٱلْحَمْدُ لِلَّهِ",      "Surah Al-Kahf 18:1"),
            (36,  1,   "يسٓ",                   "Surah Ya-Sin 36:1"),
            (55,  1,   "ٱلرَّحْمَـٰنُ",           "Surah Ar-Rahman 55:1"),
            (112, 1,   "قُلْ هُوَ ٱللَّهُ",       "Surah Al-Ikhlas 112:1"),
            (113, 1,   "قُلْ أَعُوذُ",            "Surah Al-Falaq 113:1"),
            (114, 1,   "قُلْ أَعُوذُ",            "Surah An-Nas 114:1"),
            (114, 6,   "ٱلنَّاسِ",               "Last verse of the Quran 114:6"),
        ]

        for check in spotChecks {
            if let verse = db.fetchVerse(surah: check.surah, verse: check.verse) {
                if !verse.textArabic.contains(check.mustContain) {
                    errors.append("Spot-check FAILED: \(check.label) — expected text not found")
                }
            } else {
                errors.append("Spot-check FAILED: \(check.label) — verse not found in DB")
            }
        }

        // Check 4: No empty Arabic text anywhere
        for surah in surahs {
            let verses = db.fetchVerses(surahNumber: surah.number)
            for verse in verses where verse.textArabic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.append("Empty Arabic text at \(surah.number):\(verse.verseNumber)")
            }
        }

        let passed = errors.isEmpty

        if passed {
            print("✅ Quran integrity check PASSED — hash verified, \(surahs.count) surahs, \(totalVerses) verses, all spot-checks passed")
        } else {
            print("❌ Quran integrity check FAILED (\(errors.count) error(s)):")
            for e in errors { print("   • \(e)") }
        }

        return IntegrityResult(
            passed: passed,
            hashVerified: hashVerified,
            surahCount: surahs.count,
            verseCount: totalVerses,
            errors: errors
        )
    }

    // MARK: - Tier 1: SHA-256 file hash

    private static func verifyFileHash(errors: inout [String]) -> Bool {
        guard let dbPath = Bundle.main.path(
            forResource: AppConstants.quranDBFilename,
            ofType: AppConstants.quranDBExtension
        ) else {
            errors.append("CRITICAL: quran.db not found in app bundle")
            return false
        }

        guard let fileData = try? Data(contentsOf: URL(fileURLWithPath: dbPath)) else {
            errors.append("CRITICAL: Could not read quran.db for hash verification")
            return false
        }

        let computedHash = SHA256.hash(data: fileData)
            .compactMap { String(format: "%02x", $0) }
            .joined()

        let expectedHash = AppConstants.quranDBChecksum

        if computedHash == expectedHash {
            print("✅ quran.db SHA-256 verified: \(computedHash)")
            return true
        } else {
            errors.append(
                """
                CRITICAL: quran.db SHA-256 MISMATCH
                  Expected: \(expectedHash)
                  Got:      \(computedHash)
                The Quran database has been modified or corrupted. \
                Quran text will not be displayed.
                """
            )
            return false
        }
    }
}
