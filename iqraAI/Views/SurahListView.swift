import SwiftUI

struct SurahListView: View {

    @EnvironmentObject var quranVM: QuranViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @State private var searchText: String = ""
    @State private var selectedNavMode: NavMode = .surah

    enum NavMode: String, CaseIterable {
        case surah = "Surah"
        case juz   = "Juz"
        case page  = "Page"
        case hizb  = "Hizb"
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
            Picker("Browse by", selection: $selectedNavMode) {
                ForEach(NavMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            switch selectedNavMode {
            case .surah: surahList
            case .juz:   juzList
            case .page:  pageList
            case .hizb:  hizbList
            }
        }
        .navigationTitle("QariAI")
        .searchable(text: $searchText, prompt: "Search surahs…")
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
                navRowLabel(
                    number: juzNumber,
                    title: "Juz \(juzNumber)",
                    subtitle: nil,
                    icon: "star.fill"
                )
            }
            .listRowBackground(settingsVM.theme.backgroundColor)
        }
        .listStyle(.plain)
    }

    // MARK: - Page List (PRD QR-03 — 604 pages)

    private var pageList: some View {
        List(1...604, id: \.self) { pageNumber in
            NavigationLink {
                PageReaderView(pageNumber: pageNumber)
            } label: {
                navRowLabel(
                    number: pageNumber,
                    title: "Page \(pageNumber)",
                    subtitle: nil,
                    icon: "doc.text.fill"
                )
            }
            .listRowBackground(settingsVM.theme.backgroundColor)
        }
        .listStyle(.plain)
    }

    // MARK: - Hizb List (PRD QR-03 — 60 hizbs)

    private var hizbList: some View {
        List(1...60, id: \.self) { hizbNumber in
            NavigationLink {
                HizbReaderView(hizbNumber: hizbNumber)
            } label: {
                navRowLabel(
                    number: hizbNumber,
                    title: "Hizb \(hizbNumber)",
                    subtitle: hizbSubtitle(hizbNumber),
                    icon: "book.fill"
                )
            }
            .listRowBackground(settingsVM.theme.backgroundColor)
        }
        .listStyle(.plain)
    }

    // MARK: - Shared row label

    private func navRowLabel(number: Int, title: String, subtitle: String?, icon: String) -> some View {
        HStack {
            ZStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.green.opacity(0.2))
                Text("\(number)")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
            }
            .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func hizbSubtitle(_ hizb: Int) -> String {
        // Each hizb = half a juz. Juz = (hizb + 1) / 2 rounded up
        let juz = Int(ceil(Double(hizb) / 2.0))
        let half = hizb.isMultiple(of: 2) ? "2nd half" : "1st half"
        return "Juz \(juz), \(half)"
    }
}

// MARK: - SurahRowView (unchanged)

struct SurahRowView: View {
    let surah: Surah

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Image(systemName: "diamond.fill")
                    .font(.title)
                    .foregroundStyle(.green.opacity(0.15))
                Text("\(surah.number)")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
            }
            .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(surah.nameTransliteration)
                    .font(.body.weight(.medium))
                Text(surah.nameEnglish)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

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

// MARK: - Juz Reader

struct JuzReaderView: View {
    let juzNumber: Int
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

// MARK: - Page Reader (PRD QR-03)

struct PageReaderView: View {
    let pageNumber: Int
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
        .navigationTitle("Page \(pageNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            verses = QuranDatabase.shared.fetchVerses(pageNumber: pageNumber)
        }
    }
}

// MARK: - Hizb Reader (PRD QR-03)

struct HizbReaderView: View {
    let hizbNumber: Int
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
        .navigationTitle("Hizb \(hizbNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            verses = QuranDatabase.shared.fetchVerses(hizbNumber: hizbNumber)
        }
    }
}
