import Foundation
import Combine

// MARK: - Audio Download Manager (PRD AP-09)
// Downloads full surah audio for offline playback.
// Tracks per-verse download state and exposes aggregate surah progress.

@MainActor
final class AudioDownloadManager: ObservableObject {

    static let shared = AudioDownloadManager()

    // Per-surah download progress: 0.0 → 1.0
    @Published var surahProgress: [Int: Double] = [:]
    // Which surahs are fully downloaded
    @Published var downloadedSurahs: Set<Int> = []
    // Active download tasks keyed by surahNumber
    private var activeTasks: [Int: Task<Void, Never>] = [:]

    private let verseCounts = [
        7,286,200,176,120,165,206,75,129,109,123,111,43,52,99,128,111,110,98,135,
        112,78,118,64,77,227,93,88,69,60,34,30,73,54,45,83,182,88,75,85,54,53,89,
        59,37,35,38,29,18,45,60,49,62,55,78,96,29,22,24,13,14,11,11,18,12,12,30,
        52,52,44,28,28,20,56,40,31,50,40,46,42,29,19,36,25,22,17,19,26,30,20,15,
        21,11,8,8,19,5,8,8,11,11,8,3,9,5,4,7,3,6,3,5,4,5,6
    ]

    private let cacheDir: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("QuranAudio", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private init() {
        refreshDownloadedSurahs()
    }

    // MARK: - Public API

    func isSurahDownloaded(_ surahNumber: Int) -> Bool {
        downloadedSurahs.contains(surahNumber)
    }

    func isDownloading(_ surahNumber: Int) -> Bool {
        activeTasks[surahNumber] != nil
    }

    func downloadSurah(_ surahNumber: Int, reciterId: Int, baseURL: String) {
        guard !isSurahDownloaded(surahNumber), activeTasks[surahNumber] == nil else { return }
        let verseCount = verseCounts[safe: surahNumber - 1] ?? 0
        guard verseCount > 0 else { return }

        surahProgress[surahNumber] = 0

        // Pre-compute all URLs and paths (non-isolated values) before entering the task
        let items: [(verse: Int, remote: URL, local: URL)] = (1...verseCount).map { verse in
            let globalAyah = globalAyahNumber(surah: surahNumber, verse: verse)
            let remote = URL(string: "\(baseURL)\(globalAyah).mp3")!
            let local  = cachePath(reciterId: reciterId, surah: surahNumber, verse: verse)
            return (verse, remote, local)
        }

        activeTasks[surahNumber] = Task {
            var completed = 0
            await withTaskGroup(of: Void.self) { group in
                for item in items {
                    guard !Task.isCancelled else { break }
                    // Already cached — count immediately
                    if FileManager.default.fileExists(atPath: item.local.path) {
                        completed += 1
                        self.surahProgress[surahNumber] = Double(completed) / Double(verseCount)
                        continue
                    }
                    // Capture only plain values into the nonisolated task
                    let remoteURL = item.remote
                    let localPath = item.local
                    group.addTask {
                        if let data = try? await URLSession.shared.data(from: remoteURL).0 {
                            try? data.write(to: localPath, options: .atomic)
                        }
                        await MainActor.run {
                            completed += 1
                            self.surahProgress[surahNumber] = Double(completed) / Double(verseCount)
                        }
                    }
                }
            }
            activeTasks.removeValue(forKey: surahNumber)
            refreshDownloadedSurahs()
        }
    }

    func cancelDownload(_ surahNumber: Int) {
        activeTasks[surahNumber]?.cancel()
        activeTasks.removeValue(forKey: surahNumber)
        surahProgress.removeValue(forKey: surahNumber)
    }

    func deleteSurah(_ surahNumber: Int, reciterId: Int) {
        let verseCount = verseCounts[safe: surahNumber - 1] ?? 0
        for verse in 1...max(verseCount, 1) {
            let path = cachePath(reciterId: reciterId, surah: surahNumber, verse: verse)
            try? FileManager.default.removeItem(at: path)
        }
        downloadedSurahs.remove(surahNumber)
        surahProgress.removeValue(forKey: surahNumber)
    }

    func totalCacheSize() -> Int64 {
        let e = FileManager.default.enumerator(at: cacheDir, includingPropertiesForKeys: [.fileSizeKey])
        var total: Int64 = 0
        while let url = e?.nextObject() as? URL {
            total += Int64((try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
        }
        return total
    }

    func clearAllCache() {
        try? FileManager.default.removeItem(at: cacheDir)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        downloadedSurahs.removeAll()
        surahProgress.removeAll()
    }

    // MARK: - Helpers

    private func refreshDownloadedSurahs() {
        var downloaded = Set<Int>()
        for surahIdx in 0..<verseCounts.count {
            let surahNumber = surahIdx + 1
            let verseCount = verseCounts[surahIdx]
            // Check against default reciter (id 7)
            let allCached = (1...verseCount).allSatisfy {
                FileManager.default.fileExists(atPath: cachePath(reciterId: 7, surah: surahNumber, verse: $0).path)
            }
            if allCached { downloaded.insert(surahNumber) }
        }
        downloadedSurahs = downloaded
    }

    private func cachePath(reciterId: Int, surah: Int, verse: Int) -> URL {
        cacheDir.appendingPathComponent("\(reciterId)_\(surah)_\(verse).mp3")
    }

    private func globalAyahNumber(surah: Int, verse: Int) -> Int {
        var total = 0
        for i in 0..<(surah - 1) { total += verseCounts[i] }
        return total + verse
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
