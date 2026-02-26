import SwiftUI

struct SettingsView: View {
    
    @EnvironmentObject var settingsVM: SettingsViewModel
    
    var body: some View {
        List {
            // MARK: - Display
            Section("Display") {
                // Font size
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
                    
                    // Preview
                    Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ")
                        .font(.custom(
                            AppConstants.arabicFontName,
                            size: settingsVM.fontSize,
                            relativeTo: .title
                        ))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .rightToLeft)
                        .padding(.vertical, 4)
                }
                
                // Theme
                Picker("Theme", selection: $settingsVM.theme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                
                // Translation toggle
                Toggle("Show Translation", isOn: $settingsVM.showTranslation)
                    .tint(.green)
                
                // Tajweed toggle
                Toggle("Tajweed Colors", isOn: $settingsVM.showTajweedColors)
                    .tint(.green)
            }
            
            // MARK: - Audio (Phase 2 placeholder)
            Section("Audio") {
                HStack {
                    Label("Reciter", systemImage: "waveform")
                    Spacer()
                    Text("Coming Soon")
                        .foregroundStyle(.secondary)
                }
                .opacity(0.5)
            }
            
            // MARK: - Recitation (Phase 3 placeholder)
            Section("Recitation") {
                HStack {
                    Label("Recitation Mode", systemImage: "mic.fill")
                    Spacer()
                    Text("Coming Soon")
                        .foregroundStyle(.secondary)
                }
                .opacity(0.5)
            }
            
            // MARK: - About
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0 (Phase 1)")
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
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(SettingsViewModel())
}
