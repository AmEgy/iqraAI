import SwiftUI

struct SurahListView: View {
    
    @EnvironmentObject var quranVM: QuranViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @State private var searchText: String = ""
    @State private var selectedNavMode: NavMode = .surah
    
    enum NavMode: String, CaseIterable {
        case surah = "Surah"
        case juz = "Juz"
    }
    
    var filteredSurahs: [Surah] {
        if searchText.isEmpty { return quranVM.surahs }
        let query = searchText.lowercased()
        return quranVM.surahs.filter { surah in
            surah.nameTransliteration.lowercased().contains(query) ||
            surah.nameEnglish.lowercased().contains(query) ||
            surah.nameArabic.contains(searchText) ||
            String(surah.number).contains(query)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation mode picker
            Picker("Browse by", selection: $selectedNavMode) {
                ForEach(NavMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Content
            switch selectedNavMode {
            case .surah:
                surahList
            case .juz:
                juzList
            }
        }
        .navigationTitle("QariAI")
        .searchable(text: $searchText, prompt: "Search surahs...")
        .background(settingsVM.theme.backgroundColor)
    }
    
    // MARK: - Surah List
    
    private var surahList: some View {
        List(filteredSurahs) { surah in
            NavigationLink(value: surah) {
                SurahRowView(surah: surah)
            }
            .listRowBackground(settingsVM.theme.backgroundColor)
        }
        .listStyle(.plain)
        .navigationDestination(for: Surah.self) { surah in
            VerseReaderView(surahNumber: surah.number)
        }
    }
    
    // MARK: - Juz List
    
    private var juzList: some View {
        List(1...30, id: \.self) { juzNumber in
            NavigationLink {
                JuzReaderView(juzNumber: juzNumber)
            } label: {
                HStack {
                    ZStack {
                        Image(systemName: "star.fill")
                            .font(.title2)
                            .foregroundStyle(.green.opacity(0.2))
                        Text("\(juzNumber)")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                    }
                    .frame(width: 40)
                    
                    Text("Juz \(juzNumber)")
                        .font(.body)
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(settingsVM.theme.backgroundColor)
        }
        .listStyle(.plain)
    }
}

// MARK: - Surah Row

struct SurahRowView: View {
    let surah: Surah
    
    var body: some View {
        HStack(spacing: 16) {
            // Surah number in a diamond/circle
            ZStack {
                Image(systemName: "diamond.fill")
                    .font(.title)
                    .foregroundStyle(.green.opacity(0.15))
                Text("\(surah.number)")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
            }
            .frame(width: 40)
            
            // Name and info
            VStack(alignment: .leading, spacing: 2) {
                Text(surah.nameTransliteration)
                    .font(.body.weight(.medium))
                Text(surah.nameEnglish)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Arabic name and verse count
            VStack(alignment: .trailing, spacing: 2) {
                Text(surah.nameArabic)
                    .font(.title3)
                    .environment(\.layoutDirection, .rightToLeft)
                Text("\(surah.verseCount) verses · \(surah.revelationType)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Juz Reader (placeholder, loads verses by juz)

struct JuzReaderView: View {
    let juzNumber: Int
    @EnvironmentObject var quranVM: QuranViewModel
    @State private var verses: [Verse] = []
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(verses) { verse in
                    VerseRow(verse: verse)
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Juz \(juzNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            verses = QuranDatabase.shared.fetchVerses(juzNumber: juzNumber)
        }
    }
}

#Preview {
    NavigationStack {
        SurahListView()
    }
    .environmentObject(QuranViewModel())
    .environmentObject(SettingsViewModel())
}
