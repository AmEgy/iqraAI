import SwiftUI

struct BookmarksView: View {
    
    @EnvironmentObject var quranVM: QuranViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    
    var body: some View {
        Group {
            if quranVM.bookmarks.isEmpty {
                emptyState
            } else {
                bookmarkList
            }
        }
        .navigationTitle("Bookmarks")
        .background(settingsVM.theme.backgroundColor)
        .onAppear {
            quranVM.loadBookmarks()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bookmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.5))
            
            Text("No Bookmarks Yet")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
            
            Text("Long-press any verse to bookmark it,\nor tap the bookmark icon.")
                .font(.subheadline)
                .foregroundStyle(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Bookmark List
    
    private var bookmarkList: some View {
        List {
            ForEach(quranVM.bookmarks) { bookmark in
                NavigationLink {
                    VerseReaderView(surahNumber: bookmark.surahNumber)
                } label: {
                    bookmarkRow(bookmark)
                }
                .listRowBackground(settingsVM.theme.backgroundColor)
            }
            .onDelete(perform: deleteBookmarks)
        }
        .listStyle(.plain)
    }
    
    private func bookmarkRow(_ bookmark: Bookmark) -> some View {
        let surah = quranVM.surahs.first(where: { $0.number == bookmark.surahNumber })
        
        return HStack(spacing: 12) {
            Image(systemName: "bookmark.fill")
                .foregroundStyle(.green)
                .font(.body)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(surah?.nameTransliteration ?? "Surah \(bookmark.surahNumber)")
                    .font(.body.weight(.medium))
                
                Text("Verse \(bookmark.verseNumber)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let surah {
                Text(surah.nameArabic)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func deleteBookmarks(at offsets: IndexSet) {
        for index in offsets {
            let bookmark = quranVM.bookmarks[index]
            quranVM.toggleBookmark(surah: bookmark.surahNumber, verse: bookmark.verseNumber)
        }
    }
}

#Preview {
    NavigationStack {
        BookmarksView()
    }
    .environmentObject(QuranViewModel())
    .environmentObject(SettingsViewModel())
}
