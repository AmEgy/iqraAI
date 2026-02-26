import Foundation
import GRDB

// MARK: - Quran Database Service

final class QuranDatabase {
    
    static let shared = QuranDatabase()
    
    private var quranDB: DatabaseQueue?
    private var userDB: DatabaseQueue?
    
    private init() {
        setupQuranDB()
        setupUserDB()
    }
    
    // MARK: - Setup
    
    private func setupQuranDB() {
        guard let dbPath = Bundle.main.path(
            forResource: AppConstants.quranDBFilename,
            ofType: AppConstants.quranDBExtension
        ) else {
            print("⚠️ quran.db not found in bundle!")
            return
        }
        
        do {
            var config = Configuration()
            config.readonly = true
            quranDB = try DatabaseQueue(path: dbPath, configuration: config)
            print("✅ Quran database loaded: \(dbPath)")
        } catch {
            print("❌ Failed to open Quran database: \(error)")
        }
    }
    
    private func setupUserDB() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        
        do {
            try fileManager.createDirectory(at: appSupport, withIntermediateDirectories: true)
            let userDBPath = appSupport.appendingPathComponent("user_data.db").path
            userDB = try DatabaseQueue(path: userDBPath)
            
            try userDB?.write { db in
                try db.execute(sql: """
                    CREATE TABLE IF NOT EXISTS bookmarks (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        surah_number INTEGER NOT NULL,
                        verse_number INTEGER NOT NULL,
                        created_at TEXT NOT NULL DEFAULT (datetime('now')),
                        note TEXT,
                        UNIQUE(surah_number, verse_number)
                    )
                """)
                
                try db.execute(sql: """
                    CREATE TABLE IF NOT EXISTS user_settings (
                        key TEXT PRIMARY KEY,
                        value TEXT NOT NULL
                    )
                """)
            }
            print("✅ User database ready: \(userDBPath)")
        } catch {
            print("❌ Failed to setup user database: \(error)")
        }
    }
    
    // MARK: - Helper to build Verse from Row
    
    private func verseFromRow(_ row: Row) -> Verse {
        Verse(
            id: row["id"],
            surahNumber: row["surah_number"],
            verseNumber: row["verse_number"],
            textArabic: row["text_arabic"],
            textEnglish: row["text_english"],
            textTajweed: row["text_tajweed"],
            juzNumber: row["juz_number"],
            pageNumber: row["page_number"] ?? 0
        )
    }
    
    // MARK: - Surahs
    
    func fetchAllSurahs() -> [Surah] {
        guard let db = quranDB else { return [] }
        
        do {
            return try db.read { db in
                let rows = try Row.fetchAll(db, sql: """
                    SELECT number, name_arabic, name_transliteration, name_english,
                           revelation_type, verse_count
                    FROM surahs ORDER BY number
                """)
                
                return rows.map { row in
                    Surah(
                        id: row["number"],
                        nameArabic: row["name_arabic"],
                        nameTransliteration: row["name_transliteration"],
                        nameEnglish: row["name_english"],
                        revelationType: row["revelation_type"],
                        verseCount: row["verse_count"]
                    )
                }
            }
        } catch {
            print("❌ Failed to fetch surahs: \(error)")
            return []
        }
    }
    
    func fetchSurah(number: Int) -> Surah? {
        guard let db = quranDB else { return nil }
        
        do {
            return try db.read { db in
                guard let row = try Row.fetchOne(db, sql: """
                    SELECT number, name_arabic, name_transliteration, name_english,
                           revelation_type, verse_count
                    FROM surahs WHERE number = ?
                """, arguments: [number]) else { return nil }
                
                return Surah(
                    id: row["number"],
                    nameArabic: row["name_arabic"],
                    nameTransliteration: row["name_transliteration"],
                    nameEnglish: row["name_english"],
                    revelationType: row["revelation_type"],
                    verseCount: row["verse_count"]
                )
            }
        } catch {
            print("❌ Failed to fetch surah \(number): \(error)")
            return nil
        }
    }
    
    // MARK: - Verses
    
    func fetchVerses(surahNumber: Int) -> [Verse] {
        guard let db = quranDB else { return [] }
        
        do {
            return try db.read { db in
                let rows = try Row.fetchAll(db, sql: """
                    SELECT id, surah_number, verse_number, text_arabic, text_english,
                           text_tajweed, juz_number, page_number
                    FROM verses WHERE surah_number = ? ORDER BY verse_number
                """, arguments: [surahNumber])
                
                return rows.map { verseFromRow($0) }
            }
        } catch {
            print("❌ Failed to fetch verses for surah \(surahNumber): \(error)")
            return []
        }
    }
    
    func fetchVerse(surah: Int, verse: Int) -> Verse? {
        guard let db = quranDB else { return nil }
        
        do {
            return try db.read { db in
                guard let row = try Row.fetchOne(db, sql: """
                    SELECT id, surah_number, verse_number, text_arabic, text_english,
                           text_tajweed, juz_number, page_number
                    FROM verses WHERE surah_number = ? AND verse_number = ?
                """, arguments: [surah, verse]) else { return nil }
                
                return verseFromRow(row)
            }
        } catch {
            print("❌ Failed to fetch verse \(surah):\(verse): \(error)")
            return nil
        }
    }
    
    func fetchVerses(juzNumber: Int) -> [Verse] {
        guard let db = quranDB else { return [] }
        
        do {
            return try db.read { db in
                let rows = try Row.fetchAll(db, sql: """
                    SELECT id, surah_number, verse_number, text_arabic, text_english,
                           text_tajweed, juz_number, page_number
                    FROM verses WHERE juz_number = ?
                    ORDER BY surah_number, verse_number
                """, arguments: [juzNumber])
                
                return rows.map { verseFromRow($0) }
            }
        } catch {
            print("❌ Failed to fetch verses for juz \(juzNumber): \(error)")
            return []
        }
    }
    
    func searchVerses(query: String, limit: Int = 50) -> [Verse] {
        guard let db = quranDB else { return [] }
        
        do {
            return try db.read { db in
                let rows = try Row.fetchAll(db, sql: """
                    SELECT id, surah_number, verse_number, text_arabic, text_english,
                           text_tajweed, juz_number, page_number
                    FROM verses
                    WHERE text_arabic LIKE ? OR text_english LIKE ?
                    ORDER BY surah_number, verse_number
                    LIMIT ?
                """, arguments: ["%\(query)%", "%\(query)%", limit])
                
                return rows.map { verseFromRow($0) }
            }
        } catch {
            print("❌ Search failed: \(error)")
            return []
        }
    }
    
    // MARK: - Bookmarks
    
    func fetchAllBookmarks() -> [Bookmark] {
        guard let db = userDB else { return [] }
        
        do {
            return try db.read { db in
                let rows = try Row.fetchAll(db, sql: """
                    SELECT id, surah_number, verse_number, created_at, note
                    FROM bookmarks ORDER BY created_at DESC
                """)
                
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                return rows.map { row in
                    let dateStr: String = row["created_at"]
                    let date = formatter.date(from: dateStr) ?? Date()
                    return Bookmark(
                        id: row["id"],
                        surahNumber: row["surah_number"],
                        verseNumber: row["verse_number"],
                        createdAt: date,
                        note: row["note"]
                    )
                }
            }
        } catch {
            print("❌ Failed to fetch bookmarks: \(error)")
            return []
        }
    }
    
    func isBookmarked(surah: Int, verse: Int) -> Bool {
        guard let db = userDB else { return false }
        do {
            return try db.read { db in
                let count = try Int.fetchOne(db, sql: """
                    SELECT COUNT(*) FROM bookmarks
                    WHERE surah_number = ? AND verse_number = ?
                """, arguments: [surah, verse]) ?? 0
                return count > 0
            }
        } catch { return false }
    }
    
    @discardableResult
    func addBookmark(surah: Int, verse: Int, note: String? = nil) -> Bool {
        guard let db = userDB else { return false }
        do {
            try db.write { db in
                try db.execute(sql: """
                    INSERT OR IGNORE INTO bookmarks (surah_number, verse_number, note)
                    VALUES (?, ?, ?)
                """, arguments: [surah, verse, note])
            }
            return true
        } catch {
            print("❌ Failed to add bookmark: \(error)")
            return false
        }
    }
    
    @discardableResult
    func removeBookmark(surah: Int, verse: Int) -> Bool {
        guard let db = userDB else { return false }
        do {
            try db.write { db in
                try db.execute(sql: """
                    DELETE FROM bookmarks
                    WHERE surah_number = ? AND verse_number = ?
                """, arguments: [surah, verse])
            }
            return true
        } catch {
            print("❌ Failed to remove bookmark: \(error)")
            return false
        }
    }
    
    func toggleBookmark(surah: Int, verse: Int) -> Bool {
        if isBookmarked(surah: surah, verse: verse) {
            removeBookmark(surah: surah, verse: verse)
            return false
        } else {
            addBookmark(surah: surah, verse: verse)
            return true
        }
    }
    
    // MARK: - User Settings
    
    func getSetting(_ key: String) -> String? {
        guard let db = userDB else { return nil }
        do {
            return try db.read { db in
                try String.fetchOne(db, sql: "SELECT value FROM user_settings WHERE key = ?", arguments: [key])
            }
        } catch { return nil }
    }
    
    func setSetting(_ key: String, value: String) {
        guard let db = userDB else { return }
        do {
            try db.write { db in
                try db.execute(sql: """
                    INSERT INTO user_settings (key, value) VALUES (?, ?)
                    ON CONFLICT(key) DO UPDATE SET value = excluded.value
                """, arguments: [key, value])
            }
        } catch {
            print("❌ Failed to save setting \(key): \(error)")
        }
    }
    
    // MARK: - Reading Position
    
    func getLastReadPosition() -> ReadingPosition {
        let surah = Int(getSetting("last_surah") ?? "1") ?? 1
        let verse = Int(getSetting("last_verse") ?? "1") ?? 1
        return ReadingPosition(surahNumber: surah, verseNumber: verse)
    }
    
    func saveLastReadPosition(_ position: ReadingPosition) {
        setSetting("last_surah", value: String(position.surahNumber))
        setSetting("last_verse", value: String(position.verseNumber))
    }
}
