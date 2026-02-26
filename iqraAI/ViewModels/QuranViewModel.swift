import SwiftUI
import Combine

// MARK: - Quran ViewModel

@MainActor
final class QuranViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published var surahs: [Surah] = []
    @Published var currentSurah: Surah?
    @Published var currentVerses: [Verse] = []
    @Published var bookmarkedVerseKeys: Set<String> = []
    @Published var bookmarks: [Bookmark] = []
    @Published var searchResults: [Verse] = []
    @Published var searchQuery: String = ""
    @Published var isSearching: Bool = false
    @Published var lastReadPosition: ReadingPosition = .beginning
    
    private let db = QuranDatabase.shared
    private var searchTask: Task<Void, Never>?
    
    // MARK: - Init
    
    init() {
        loadSurahs()
        loadBookmarks()
        lastReadPosition = db.getLastReadPosition()
    }
    
    // MARK: - Surah Loading
    
    func loadSurahs() {
        surahs = db.fetchAllSurahs()
    }
    
    func loadSurah(_ surahNumber: Int) {
        currentSurah = db.fetchSurah(number: surahNumber)
        currentVerses = db.fetchVerses(surahNumber: surahNumber)
        refreshBookmarkState()
    }
    
    // MARK: - Navigation
    
    /// Save reading position when user views a verse
    func updateReadingPosition(surah: Int, verse: Int) {
        let position = ReadingPosition(surahNumber: surah, verseNumber: verse)
        lastReadPosition = position
        db.saveLastReadPosition(position)
    }
    
    /// Get the surah to navigate to when app opens
    var lastReadSurahNumber: Int {
        lastReadPosition.surahNumber
    }
    
    // MARK: - Bookmarks
    
    func loadBookmarks() {
        bookmarks = db.fetchAllBookmarks()
        bookmarkedVerseKeys = Set(bookmarks.map { $0.verseKey })
    }
    
    func isBookmarked(surah: Int, verse: Int) -> Bool {
        bookmarkedVerseKeys.contains("\(surah):\(verse)")
    }
    
    func toggleBookmark(surah: Int, verse: Int) {
        let isNowBookmarked = db.toggleBookmark(surah: surah, verse: verse)
        let key = "\(surah):\(verse)"
        
        if isNowBookmarked {
            bookmarkedVerseKeys.insert(key)
        } else {
            bookmarkedVerseKeys.remove(key)
        }
        
        // Reload full bookmark list
        loadBookmarks()
    }
    
    private func refreshBookmarkState() {
        bookmarkedVerseKeys = Set(db.fetchAllBookmarks().map { $0.verseKey })
    }
    
    // MARK: - Search
    
    func performSearch() {
        searchTask?.cancel()
        
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else {
            searchResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        searchTask = Task {
            // Small debounce
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
            guard !Task.isCancelled else { return }
            
            let results = db.searchVerses(query: query)
            
            guard !Task.isCancelled else { return }
            searchResults = results
            isSearching = false
        }
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
        isSearching = false
        searchTask?.cancel()
    }
}
