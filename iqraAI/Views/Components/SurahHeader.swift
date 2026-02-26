import SwiftUI

struct SurahHeader: View {
    
    let surah: Surah
    @EnvironmentObject var settingsVM: SettingsViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Surah name plate
            VStack(spacing: 8) {
                // Decorative top
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.green.opacity(0.5))
                
                // Arabic name
                Text(surah.nameArabic)
                    .font(.custom(
                        AppConstants.arabicFontName,
                        size: settingsVM.fontSize + 4,
                        relativeTo: .largeTitle
                    ))
                    .foregroundStyle(settingsVM.theme.textColor)
                
                // English info
                Text("\(surah.nameEnglish) · \(surah.verseCount) Verses · \(surah.revelationType)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // Decorative bottom
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .green.opacity(0.3), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .padding(.horizontal, 40)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.green.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(.green.opacity(0.1), lineWidth: 1)
                    )
            )
            
            // No separate Bismillah here — the Tanzil text already includes
            // the Bismillah at the start of verse 1 for each surah.
            // Showing it separately would duplicate it.
        }
    }
}

#Preview {
    SurahHeader(surah: Surah(
        id: 2,
        nameArabic: "البقرة",
        nameTransliteration: "Al-Baqarah",
        nameEnglish: "The Cow",
        revelationType: "Medinan",
        verseCount: 286
    ))
    .padding()
    .environmentObject(SettingsViewModel())
}
