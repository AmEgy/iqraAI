import SwiftUI
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    
    @Published var fontSize: CGFloat {
        didSet { saveSetting("font_size", value: String(Int(fontSize))) }
    }
    
    @Published var theme: AppTheme {
        didSet { saveSetting("theme", value: theme.rawValue) }
    }
    
    @Published var showTranslation: Bool {
        didSet { saveSetting("translation_visible", value: showTranslation ? "true" : "false") }
    }
    
    @Published var showTajweedColors: Bool {
        didSet { saveSetting("tajweed_colors", value: showTajweedColors ? "true" : "false") }
    }
    
    @Published var showTransliteration: Bool {
        didSet { saveSetting("transliteration", value: showTransliteration ? "true" : "false") }
    }
    
    private let db = QuranDatabase.shared
    
    init() {
        let storedSize = Double(db.getSetting("font_size") ?? "") ?? Double(AppConstants.defaultArabicFontSize)
        self.fontSize = CGFloat(storedSize)
        
        let storedTheme = db.getSetting("theme") ?? "system"
        self.theme = AppTheme(rawValue: storedTheme) ?? .system
        
        let storedTranslation = db.getSetting("translation_visible") ?? "true"
        self.showTranslation = storedTranslation == "true"
        
        let storedTajweed = db.getSetting("tajweed_colors") ?? "true"
        self.showTajweedColors = storedTajweed == "true"
        
        let storedTranslit = db.getSetting("transliteration") ?? "false"
        self.showTransliteration = storedTranslit == "true"
    }
    
    private func saveSetting(_ key: String, value: String) {
        db.setSetting(key, value: value)
    }
}
