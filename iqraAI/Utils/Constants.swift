import SwiftUI

enum AppConstants {
    static let appName = "iqraAI"
    
    // MARK: - Database
    static let quranDBFilename = "quran"
    static let quranDBExtension = "db"
    
    /// SHA-256 hash of the bundled quran.db file.
    /// Computed on: 2026-02-26 from Tanzil.net Uthmani Hafs text.
    /// HOW TO UPDATE: run `sha256sum iqraAI/quran.db` and paste the result here.
    /// The app will refuse to display Quran text if this does not match at launch.
    static let quranDBChecksum = "284b218150662061b4ff9d8f3e6d77c9b5aceca45a7627179926097b3e593a99"
    
    // MARK: - Quran Structure
    static let totalSurahs = 114
    static let totalVerses = 6236
    static let totalJuz = 30
    static let totalPages = 604
    
    // MARK: - Fonts
    /// KFGQPC Uthmanic Script HAFS — the official King Fahd Complex font
    /// This is the same font used in printed Qurans distributed worldwide.
    /// File: KFGQPC_Uthmanic_Script_HAFS_Regular.otf
    /// Must be registered in Info.plist under UIAppFonts
    static let arabicFontName = "KFGQPCUthmanicScriptHAFS"
    
    /// Fallback: Scheherazade New (if KFGQPC not loaded)
    static let arabicFallbackFontName = "ScheherazadeNew-Regular"
    
    // MARK: - UI Defaults
    static let defaultArabicFontSize: CGFloat = 28
    static let minFontSize: CGFloat = 18
    static let maxFontSize: CGFloat = 44
    
    // MARK: - Tajweed Colors
    // Source: islamic-network/alquran-tools Tajweed.php
    // (the official parser that generates tajweed data for AlQuran.cloud & Quran.com)
    enum TajweedColor {
        static let ghunnah         = Color(hex: "FF7E1E")  // orange
        static let ikhfaa          = Color(hex: "9400A8")  // purple
        static let ikhfaaShafawi   = Color(hex: "D500B7")  // magenta/pink
        static let iqlab           = Color(hex: "26BFFD")  // cyan/light blue
        static let idghamGhunnah   = Color(hex: "169777")  // teal
        static let idghamShafawi   = Color(hex: "58B800")  // green
        static let idghamNoGhunnah = Color(hex: "169200")  // green
        static let qalqalah        = Color(hex: "DD0008")  // red
        static let maddNecessary   = Color(hex: "000EBC")  // deep blue
        static let maddObligatory  = Color(hex: "2144C1")  // medium blue
        static let maddPermissible = Color(hex: "4050FF")  // darker blue
        static let maddNormal      = Color(hex: "537FFF")  // blue
        static let silent          = Color(hex: "AAAAAA")  // gray
        static let hamzaWasl       = Color(hex: "AAAAAA")  // gray
        static let laamShamsiyah   = Color(hex: "AAAAAA")  // gray
        static let normal          = Color.primary
    }
    
    // MARK: - Recitation Feedback Colors
    enum FeedbackColor {
        static let correct  = Color(hex: "22C55E")  // green
        static let wrong    = Color(hex: "EF4444")  // red
        static let skipped  = Color(hex: "F59E0B")  // amber
        static let extra    = Color(hex: "8B5CF6")  // purple
        static let pending  = Color(hex: "6B7280")  // gray
    }
    
    // MARK: - Bismillah
    static let bismillah = "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ"
    static let surahsWithoutBismillah: Set<Int> = [1, 9]
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
