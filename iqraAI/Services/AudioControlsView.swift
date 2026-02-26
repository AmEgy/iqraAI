import SwiftUI

/// Full audio controls shown in the verse reader toolbar
struct AudioControlsView: View {
    
    let surahNumber: Int
    let totalVerses: Int
    
    @EnvironmentObject var audioPlayer: AudioPlayerService
    @State private var showReciterPicker = false
    @State private var showSpeedPicker = false
    
    private var isPlayingThisSurah: Bool {
        audioPlayer.currentSurah == surahNumber && audioPlayer.isActive
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Play / Pause entire surah
            Button {
                if isPlayingThisSurah {
                    audioPlayer.togglePlayPause()
                } else {
                    audioPlayer.playSurah(surah: surahNumber, fromVerse: 1, totalVerses: totalVerses)
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isPlayingThisSurah && audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                    Text(isPlayingThisSurah && audioPlayer.isPlaying ? "Pause" : "Play Surah")
                        .font(.caption.weight(.medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.15))
                .foregroundStyle(.green)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            // Stop
            if isPlayingThisSurah {
                Button {
                    audioPlayer.stop()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.caption)
                        .padding(6)
                        .background(Color.red.opacity(0.15))
                        .foregroundStyle(.red)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            // Speed
            Menu {
                ForEach([0.5, 0.75, 1.0, 1.25, 1.5], id: \.self) { speed in
                    Button {
                        audioPlayer.setSpeed(Float(speed))
                    } label: {
                        HStack {
                            Text("\(speed, specifier: "%.2g")x")
                            if Float(speed) == audioPlayer.playbackSpeed {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Text("\(audioPlayer.playbackSpeed, specifier: "%.2g")x")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            // Reciter picker
            Menu {
                ForEach(AudioPlayerService.defaultReciters) { reciter in
                    Button {
                        audioPlayer.currentReciter = reciter
                        // Restart if playing
                        if audioPlayer.isActive {
                            audioPlayer.stop()
                        }
                    } label: {
                        HStack {
                            Text(reciter.name)
                            if reciter.id == audioPlayer.currentReciter.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "person.wave.2")
                    .font(.caption)
                    .padding(6)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}
