import Foundation
import AVFoundation
import MediaPlayer
import Combine

// MARK: - Reciter Model

struct Reciter: Identifiable, Hashable {
    let id: Int
    let name: String
    let arabicName: String
    let style: String
    let audioBaseURL: String
    let quranComRecitationId: Int?
}

// MARK: - Word Timestamp

struct WordTimestamp: Identifiable {
    let id = UUID()
    let wordIndex: Int
    let startTime: TimeInterval
    let endTime: TimeInterval
}

// MARK: - Playback State

enum PlaybackState: Equatable {
    case idle
    case loading
    case playing
    case paused
    case error(String)
}

enum PlaybackMode: Equatable {
    case singleVerse
    case continuous
}

// MARK: - Audio Player Service

@MainActor
class AudioPlayerService: NSObject, ObservableObject {
    
    static let shared = AudioPlayerService()
    
    @Published var playbackState: PlaybackState = .idle
    @Published var currentSurah: Int = 0
    @Published var currentVerse: Int = 0
    @Published var playbackMode: PlaybackMode = .continuous
    @Published var playbackSpeed: Float = 1.0
    @Published var repeatCount: Int = 1
    @Published var highlightedWordIndex: Int = -1
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var wordTimestamps: [WordTimestamp] = []
    @Published var currentReciter: Reciter = AudioPlayerService.defaultReciters[0]
    
    static let defaultReciters: [Reciter] = [
        Reciter(
            id: 7, name: "Mishary Al-Afasy", arabicName: "مشاري العفاسي",
            style: "Murattal",
            audioBaseURL: "https://cdn.islamic.network/quran/audio/128/ar.alafasy/",
            quranComRecitationId: 7
        ),
        Reciter(
            id: 1, name: "Abdul-Basit (Murattal)", arabicName: "عبد الباسط عبد الصمد",
            style: "Murattal",
            audioBaseURL: "https://cdn.islamic.network/quran/audio/128/ar.abdulbasitmurattal/",
            quranComRecitationId: 1
        )
    ]
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var versesToPlay: [(surah: Int, verse: Int)] = []
    private var currentPlayIndex: Int = 0
    private var currentRepeat: Int = 0
    private var cancellables = Set<AnyCancellable>()
    
    private let cacheDir: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("QuranAudio", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()
    
    // Standard verse counts for global ayah calculation
    private let verseCounts = [
        7,286,200,176,120,165,206,75,129,109,123,111,43,52,99,128,111,110,98,135,
        112,78,118,64,77,227,93,88,69,60,34,30,73,54,45,83,182,88,75,85,54,53,89,
        59,37,35,38,29,18,45,60,49,62,55,78,96,29,22,24,13,14,11,11,18,12,12,30,
        52,52,44,28,28,20,56,40,31,50,40,46,42,29,19,36,25,22,17,19,26,30,20,15,
        21,11,8,8,19,5,8,8,11,11,8,3,9,5,4,7,3,6,3,5,4,5,6
    ]
    
    private override init() {
        super.init()
        setupAudioSession()
        setupRemoteCommands()
    }
    
    // MARK: - Setup
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("❌ Audio session error: \(error)")
        }
    }
    
    private func setupRemoteCommands() {
        let cc = MPRemoteCommandCenter.shared()
        cc.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.resume() }
            return .success
        }
        cc.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.pause() }
            return .success
        }
        cc.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.playNext() }
            return .success
        }
        cc.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.playPrevious() }
            return .success
        }
    }
    
    // MARK: - URL Helpers
    
    private func globalAyahNumber(surah: Int, verse: Int) -> Int {
        var total = 0
        for i in 0..<(surah - 1) { total += verseCounts[i] }
        return total + verse
    }
    
    private func audioURL(surah: Int, verse: Int) -> URL {
        let num = globalAyahNumber(surah: surah, verse: verse)
        return URL(string: "\(currentReciter.audioBaseURL)\(num).mp3")!
    }
    
    private func cachePath(surah: Int, verse: Int) -> URL {
        cacheDir.appendingPathComponent("\(currentReciter.id)_\(surah)_\(verse).mp3")
    }
    
    // MARK: - Play Controls
    
    func playVerse(surah: Int, verse: Int) {
        versesToPlay = [(surah, verse)]
        currentPlayIndex = 0
        currentRepeat = 0
        playbackMode = .singleVerse
        playCurrentItem()
    }
    
    func playSurah(surah: Int, fromVerse: Int = 1, totalVerses: Int) {
        versesToPlay = (fromVerse...totalVerses).map { (surah, $0) }
        currentPlayIndex = 0
        currentRepeat = 0
        playbackMode = .continuous
        playCurrentItem()
    }
    
    func playRange(surah: Int, fromVerse: Int, toVerse: Int) {
        versesToPlay = (fromVerse...toVerse).map { (surah, $0) }
        currentPlayIndex = 0
        currentRepeat = 0
        playbackMode = .continuous
        playCurrentItem()
    }
    
    private func playCurrentItem() {
        guard currentPlayIndex < versesToPlay.count else {
            stop()
            return
        }
        
        let item = versesToPlay[currentPlayIndex]
        currentSurah = item.surah
        currentVerse = item.verse
        playbackState = .loading
        highlightedWordIndex = -1
        wordTimestamps = []
        
        let local = cachePath(surah: item.surah, verse: item.verse)
        let url = FileManager.default.fileExists(atPath: local.path) ? local : audioURL(surah: item.surah, verse: item.verse)
        
        // Cache in background
        if !FileManager.default.fileExists(atPath: local.path) {
            let remoteURL = audioURL(surah: item.surah, verse: item.verse)
            Task.detached {
                try? await URLSession.shared.data(from: remoteURL).0.write(to: local, options: .atomic)
            }
        }
        
        // Fetch word timestamps
        Task {
            await fetchWordTimestamps(surah: item.surah, verse: item.verse)
        }
        
        removeTimeObserver()
        playerItem = AVPlayerItem(url: url)
        
        if player == nil {
            player = AVPlayer(playerItem: playerItem)
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }
        
        player?.rate = playbackSpeed
        
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying),
                                                name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        let interval = CMTime(seconds: 0.05, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.currentTime = time.seconds
                if let dur = self.player?.currentItem?.duration.seconds, dur.isFinite {
                    self.duration = dur
                }
                self.updateWordHighlight(at: time.seconds)
            }
        }
        
        playerItem?.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                switch status {
                case .readyToPlay:
                    self.playbackState = .playing
                    self.player?.play()
                    self.player?.rate = self.playbackSpeed
                    self.updateNowPlayingInfo()
                case .failed:
                    self.playbackState = .error("Failed to load audio")
                default: break
                }
            }
            .store(in: &cancellables)
    }
    
    func pause() {
        player?.pause()
        playbackState = .paused
        updateNowPlayingInfo()
    }
    
    func resume() {
        player?.play()
        player?.rate = playbackSpeed
        playbackState = .playing
        updateNowPlayingInfo()
    }
    
    func stop() {
        removeTimeObserver()
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        playbackState = .idle
        highlightedWordIndex = -1
        wordTimestamps = []
        currentTime = 0
        duration = 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    func togglePlayPause() {
        if playbackState == .playing { pause() }
        else if playbackState == .paused { resume() }
    }
    
    func playNext() {
        currentPlayIndex += 1
        currentRepeat = 0
        playCurrentItem()
    }
    
    func playPrevious() {
        if currentTime > 3 {
            seek(to: 0)
        } else if currentPlayIndex > 0 {
            currentPlayIndex -= 1
            currentRepeat = 0
            playCurrentItem()
        }
    }
    
    func seek(to time: TimeInterval) {
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 600))
    }
    
    func setSpeed(_ speed: Float) {
        playbackSpeed = speed
        if playbackState == .playing { player?.rate = speed }
    }
    
    // MARK: - End of Track
    
    @objc private func playerDidFinishPlaying() {
        Task { @MainActor in
            currentRepeat += 1
            if repeatCount == 0 || currentRepeat < repeatCount {
                seek(to: 0)
                player?.play()
                player?.rate = playbackSpeed
                return
            }
            currentRepeat = 0
            currentPlayIndex += 1
            if currentPlayIndex < versesToPlay.count {
                playCurrentItem()
            } else {
                stop()
            }
        }
    }
    
    // MARK: - Word Highlighting
    
    private func updateWordHighlight(at time: TimeInterval) {
        guard !wordTimestamps.isEmpty else { return }
        for (i, ts) in wordTimestamps.enumerated() {
            if time >= ts.startTime && time < ts.endTime {
                if highlightedWordIndex != i { highlightedWordIndex = i }
                return
            }
        }
    }
    
    func fetchWordTimestamps(surah: Int, verse: Int) async {
        guard let rid = currentReciter.quranComRecitationId else { return }
        let urlStr = "https://api.quran.com/api/v4/recitations/\(rid)/by_ayah/\(surah):\(verse)"
        guard let url = URL(string: urlStr) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let files = json?["audio_files"] as? [[String: Any]],
               let first = files.first,
               let segments = first["segments"] as? [[Any]] {
                var ts: [WordTimestamp] = []
                for seg in segments {
                    guard seg.count >= 3 else { continue }
                    let wi = (seg[0] as? Int ?? 1) - 1
                    let start = Double(seg[1] as? Int ?? 0) / 1000.0
                    let end = Double(seg[2] as? Int ?? 0) / 1000.0
                    ts.append(WordTimestamp(wordIndex: wi, startTime: start, endTime: end))
                }
                self.wordTimestamps = ts
            }
        } catch {
            print("⚠️ Timestamps fetch failed: \(error)")
        }
    }
    
    // MARK: - Now Playing
    
    private func updateNowPlayingInfo() {
        let name = QuranDatabase.shared.fetchSurah(number: currentSurah)?.nameTransliteration ?? "Quran"
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: "Verse \(currentVerse)",
            MPMediaItemPropertyAlbumTitle: name,
            MPMediaItemPropertyArtist: currentReciter.name,
            MPNowPlayingInfoPropertyPlaybackRate: playbackState == .playing ? playbackSpeed : 0.0,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
        ]
        if duration > 0 { info[MPMediaItemPropertyPlaybackDuration] = duration }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    // MARK: - Cache
    
    func isVerseCached(surah: Int, verse: Int) -> Bool {
        FileManager.default.fileExists(atPath: cachePath(surah: surah, verse: verse).path)
    }
    
    func cacheSize() -> Int64 {
        let e = FileManager.default.enumerator(at: cacheDir, includingPropertiesForKeys: [.fileSizeKey])
        var total: Int64 = 0
        while let url = e?.nextObject() as? URL {
            total += Int64((try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
        }
        return total
    }
    
    func clearCache() {
        try? FileManager.default.removeItem(at: cacheDir)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }
    
    private func removeTimeObserver() {
        if let o = timeObserver { player?.removeTimeObserver(o); timeObserver = nil }
        cancellables.removeAll()
    }
    
    var isPlaying: Bool { playbackState == .playing }
    var isPaused: Bool { playbackState == .paused }
    var isActive: Bool { playbackState == .playing || playbackState == .paused || playbackState == .loading }
}
