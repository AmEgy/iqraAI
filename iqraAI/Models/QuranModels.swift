import Foundation

// MARK: - Surah Model

struct Surah: Identifiable, Hashable {
    let id: Int  // surah number (1–114)
    let nameArabic: String
    let nameTransliteration: String
    let nameEnglish: String
    let revelationType: String  // "Meccan" or "Medinan"
    let verseCount: Int
    
    var number: Int { id }
    
    var displayTitle: String {
        "\(nameTransliteration)"
    }
}

// MARK: - Verse Model

struct Verse: Identifiable, Hashable {
    let id: Int
    let surahNumber: Int
    let verseNumber: Int
    let textArabic: String
    let textEnglish: String?
    let textTajweed: String?  // HTML-tagged tajweed text from Quran.com
    let juzNumber: Int
    let pageNumber: Int
    
    var verseKey: String {
        "\(surahNumber):\(verseNumber)"
    }
    
    var arabicVerseNumber: String {
        let arabicDigits = ["٠","١","٢","٣","٤","٥","٦","٧","٨","٩"]
        return String(verseNumber).map { arabicDigits[Int(String($0))!] }.joined()
    }
}

// MARK: - Bookmark Model

struct Bookmark: Identifiable, Hashable {
    let id: Int
    let surahNumber: Int
    let verseNumber: Int
    let createdAt: Date
    let note: String?
    
    var verseKey: String {
        "\(surahNumber):\(verseNumber)"
    }
}

// MARK: - Juz Model

struct Juz: Identifiable {
    let id: Int
    let startSurah: Int
    let startVerse: Int
    
    var number: Int { id }
}

// MARK: - Reading Position

struct ReadingPosition: Codable, Equatable {
    var surahNumber: Int
    var verseNumber: Int
    
    static let beginning = ReadingPosition(surahNumber: 1, verseNumber: 1)
}

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    case sepia = "sepia"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        case .sepia: return "Sepia"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        case .sepia: return .light
        }
    }
}

import SwiftUI

extension AppTheme {
    var backgroundColor: Color {
        switch self {
        case .sepia: return Color(hex: "F5E6C8")
        default: return Color(.systemBackground)
        }
    }
    
    var textColor: Color {
        switch self {
        case .sepia: return Color(hex: "5B4636")
        default: return Color.primary
        }
    }
}
