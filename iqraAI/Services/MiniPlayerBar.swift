import SwiftUI

struct MiniPlayerBar: View {
    
    @EnvironmentObject var audioPlayer: AudioPlayerService
    
    var body: some View {
        if audioPlayer.isActive {
            VStack(spacing: 0) {
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Color.green.opacity(0.2))
                        Rectangle().fill(Color.green)
                            .frame(width: audioPlayer.duration > 0
                                   ? geo.size.width * (audioPlayer.currentTime / audioPlayer.duration) : 0)
                    }
                }
                .frame(height: 3)
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        let surahName = QuranDatabase.shared.fetchSurah(number: audioPlayer.currentSurah)?.nameTransliteration ?? ""
                        Text(surahName)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Text("Verse \(audioPlayer.currentVerse) · \(audioPlayer.currentReciter.name)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    if audioPlayer.playbackState == .loading {
                        ProgressView().scaleEffect(0.8)
                    } else if case .error = audioPlayer.playbackState {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.body)
                    }
                    
                    Button { audioPlayer.playPrevious() } label: {
                        Image(systemName: "backward.fill").font(.body)
                    }.buttonStyle(.plain)
                    
                    Button { audioPlayer.togglePlayPause() } label: {
                        Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill").font(.title3)
                    }.buttonStyle(.plain)
                    
                    Button { audioPlayer.playNext() } label: {
                        Image(systemName: "forward.fill").font(.body)
                    }.buttonStyle(.plain)
                    
                    Button { audioPlayer.stop() } label: {
                        Image(systemName: "xmark.circle.fill").font(.body).foregroundStyle(.secondary)
                    }.buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
        }
    }
}
