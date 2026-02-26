import SwiftUI

@main
struct iqraAIApp: App {
    
    @StateObject private var quranVM = QuranViewModel()
    @StateObject private var settingsVM = SettingsViewModel()
    @StateObject private var audioPlayer = AudioPlayerService.shared
    @State private var integrityFailed = false
    @State private var integrityErrors: [String] = []
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(quranVM)
                .environmentObject(settingsVM)
                .environmentObject(audioPlayer)
                .preferredColorScheme(settingsVM.theme.colorScheme)
                .onAppear {
                    let result = QuranIntegrityChecker.verify()
                    if !result.passed {
                        integrityFailed = true
                        integrityErrors = result.errors
                    }
                }
                .alert("Quran Data Integrity Warning", isPresented: $integrityFailed) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("The Quran database may be corrupted. Please reinstall the app.\n\nErrors: \(integrityErrors.joined(separator: ", "))")
                }
        }
    }
}
