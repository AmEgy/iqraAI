import SwiftUI

struct SettingsView: View {

    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var audioPlayer: AudioPlayerService
    @StateObject private var downloader = AudioDownloadManager.shared
    @ObservedObject private var translationService = TranslationService.shared
    @State private var showDownloadManager = false

    var body: some View {
        List {
            // MARK: - Display
            Section("Display") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Arabic Font Size")
                        Spacer()
                        Text("\(Int(settingsVM.fontSize))pt")
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: $settingsVM.fontSize,
                        in: AppConstants.minFontSize...AppConstants.maxFontSize,
                        step: 2
                    )
                    .tint(.green)
                    Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ")
                        .font(.custom(AppConstants.arabicFontName, size: settingsVM.fontSize, relativeTo: .title))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .rightToLeft)
                        .padding(.vertical, 4)
                }

                Picker("Theme", selection: $settingsVM.theme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }

                Toggle("Show Translation", isOn: $settingsVM.showTranslation)
                    .tint(.green)
                Toggle("Transliteration", isOn: $settingsVM.showTransliteration)
                    .tint(.green)
                Toggle("Tajweed Colors", isOn: $settingsVM.showTajweedColors)
                    .tint(.green)
            }

            // MARK: - Translation Language (PRD QR-05)
            Section("Translation Language") {
                Picker("Language", selection: Binding(
                    get: { translationService.selectedLanguage },
                    set: { translationService.setLanguage($0) }
                )) {
                    ForEach(TranslationService.supportedLanguages) { lang in
                        Text("\(lang.displayName) — \(lang.nativeName)").tag(lang)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()

                Text("Translation is fetched on-demand from the Quran Foundation API and is not bundled with the app.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // MARK: - Audio
            Section("Audio") {
                Picker("Reciter", selection: $audioPlayer.currentReciter) {
                    ForEach(AudioPlayerService.defaultReciters) { reciter in
                        Text(reciter.name).tag(reciter)
                    }
                }
                .onChange(of: audioPlayer.currentReciter) { _, _ in
                    if audioPlayer.isActive { audioPlayer.stop() }
                }

                // Download Manager entry (PRD AP-09)
                Button {
                    showDownloadManager = true
                } label: {
                    HStack {
                        Label("Offline Downloads", systemImage: "arrow.down.circle")
                        Spacer()
                        Text(formatBytes(downloader.totalCacheSize()))
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .foregroundStyle(.primary)
            }

            // MARK: - Recitation placeholder
            Section("Recitation") {
                HStack {
                    Label("Recitation Mode", systemImage: "mic.fill")
                    Spacer()
                    Text("Coming in Phase 3")
                        .foregroundStyle(.secondary)
                }
                .opacity(0.5)
            }

            // MARK: - About
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Quran Text")
                    Spacer()
                    Text("Uthmani (Hafs)")
                        .foregroundStyle(.secondary)
                }
                Link(destination: URL(string: "https://quran.com")!) {
                    HStack {
                        Text("Data Source")
                        Spacer()
                        Text("Quran Foundation")
                            .foregroundStyle(.green)
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }

            // MARK: - Disclaimer
            Section {
                Text("QariAI is an assistive learning tool. The Quranic text is sourced from scholar-verified databases. Always verify your recitation with a qualified Quran teacher.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .listStyle(.insetGrouped)
        .sheet(isPresented: $showDownloadManager) {
            DownloadManagerView()
                .environmentObject(downloader)
                .environmentObject(audioPlayer)
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let mb = Double(bytes) / 1_048_576
        if mb < 1 { return "\(bytes / 1024) KB" }
        return String(format: "%.1f MB", mb)
    }
}

// MARK: - Download Manager Sheet (PRD AP-09)

struct DownloadManagerView: View {

    @EnvironmentObject var downloader: AudioDownloadManager
    @EnvironmentObject var audioPlayer: AudioPlayerService
    @State private var surahs: [Surah] = []
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List(surahs) { surah in
                SurahDownloadRow(surah: surah)
                    .environmentObject(downloader)
                    .environmentObject(audioPlayer)
            }
            .listStyle(.plain)
            .navigationTitle("Offline Downloads")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if downloader.totalCacheSize() > 0 {
                        Button("Clear All", role: .destructive) {
                            downloader.clearAllCache()
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .task {
                surahs = QuranDatabase.shared.fetchAllSurahs()
            }
        }
    }
}

// MARK: - Per-Surah Download Row

private struct SurahDownloadRow: View {
    let surah: Surah
    @EnvironmentObject var downloader: AudioDownloadManager
    @EnvironmentObject var audioPlayer: AudioPlayerService

    private var isDownloaded: Bool { downloader.isSurahDownloaded(surah.number) }
    private var isDownloading: Bool { downloader.isDownloading(surah.number) }
    private var progress: Double { downloader.surahProgress[surah.number] ?? 0 }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(surah.nameTransliteration)
                    .font(.body.weight(.medium))
                Text("\(surah.verseCount) verses · \(surah.revelationType)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(surah.nameArabic)
                .font(.body)
                .foregroundStyle(.secondary)

            // Action button
            Group {
                if isDownloaded {
                    Button {
                        downloader.deleteSurah(surah.number, reciterId: audioPlayer.currentReciter.id)
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red.opacity(0.8))
                    }
                } else if isDownloading {
                    VStack(spacing: 4) {
                        ProgressView(value: progress)
                            .frame(width: 44)
                            .tint(.green)
                        Button {
                            downloader.cancelDownload(surah.number)
                        } label: {
                            Text("Cancel")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Button {
                        downloader.downloadSurah(
                            surah.number,
                            reciterId: audioPlayer.currentReciter.id,
                            baseURL: audioPlayer.currentReciter.audioBaseURL,
                            urlFormat: audioPlayer.currentReciter.urlFormat
                        )
                    } label: {
                        Image(systemName: "arrow.down.circle")
                            .foregroundStyle(.green)
                            .font(.title3)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(SettingsViewModel())
    .environmentObject(AudioPlayerService.shared)
}
