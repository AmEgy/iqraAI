import SwiftUI

@main
struct iqraAIApp: App {

    @StateObject private var quranVM = QuranViewModel()
    @StateObject private var settingsVM = SettingsViewModel()
    @StateObject private var audioPlayer = AudioPlayerService.shared
    @StateObject private var translationService = TranslationService.shared

    /// Set to true only when the SHA-256 hash check passes.
    /// The UI is gated behind this — Quran text is never shown if false.
    @State private var integrityPassed = false
    @State private var integrityResult: QuranIntegrityChecker.IntegrityResult? = nil

    var body: some Scene {
        WindowGroup {
            Group {
                if integrityPassed {
                    HomeView()
                        .environmentObject(quranVM)
                        .environmentObject(settingsVM)
                        .environmentObject(audioPlayer)
                        .environmentObject(translationService)
                        .preferredColorScheme(settingsVM.theme.colorScheme)
                } else if integrityResult == nil {
                    // Still running checks
                    IntegrityCheckingView()
                } else {
                    // Check ran and failed
                    IntegrityFailedView(errors: integrityResult?.errors ?? [])
                }
            }
            .task {
                // Run off main thread — reads the full DB file for SHA-256
                let result = await Task.detached(priority: .userInitiated) {
                    QuranIntegrityChecker.verify()
                }.value
                integrityResult = result
                integrityPassed = result.passed
            }
        }
    }
}

// MARK: - Integrity Checking Splash

private struct IntegrityCheckingView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 56))
                .foregroundStyle(.green)
                .symbolEffect(.pulse)

            Text("Verifying Quran Text")
                .font(.title2.weight(.semibold))

            Text("Checking data integrity…")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ProgressView()
                .tint(.green)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Integrity Failed Screen
// Shown instead of the app when quran.db SHA-256 does not match.
// The user cannot proceed — they must reinstall.

private struct IntegrityFailedView: View {
    let errors: [String]

    var body: some View {
        VStack(spacing: 28) {
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 64))
                .foregroundStyle(.red)

            VStack(spacing: 8) {
                Text("Data Integrity Error")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)

                Text("The Quran database has been corrupted or tampered with. To protect the integrity of the Quran text, QariAI cannot display any content.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(errors.prefix(3), id: \.self) { error in
                    Label(error, systemImage: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 32)

            VStack(spacing: 12) {
                Text("Please delete and reinstall the app.")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.primary)

                Text("If this error persists, contact support.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
