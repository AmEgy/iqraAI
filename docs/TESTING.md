# QariAI — Friend Testing Checklist
**Device:** iPhone iOS 18 · **Build:** Pull `main` and run from Xcode

---

## 🚀 Launch
- [x] App opens with a green shield spinner briefly, then loads normally
- [x] **Red shield "Data Integrity Error"** screen = DB corrupted → tell Ahmed immediately

---

## 📖 Reading

### Surah List
- [x] 114 surahs with Arabic names, English names, verse counts
- [x] Search bar filters by Arabic, English, or transliteration
- [ ] **Navigation tabs:** Surah / Juz / **Page** / **Hizb** all appear and work
  - Page tab: 604 pages, tap one → opens its verses 
  - Hizb tab: 60 hizbs with "Juz X, 1st/2nd half" subtitle

### Verse Reader
- [x] Arabic text renders with full diacritics (no boxes or ?)
- [ ] Tap a verse → reading position saved
- [x] Bookmark icon fills green when tapped
- [x] Long-press verse → action sheet (Bookmark / Copy Arabic / Copy Translation)
- [ ] **Tap any Arabic word** ⭐ → popover shows word + English meaning + "Word X of Y"

---

## ⚙️ Settings

### Display
- [x] Font size slider (18–44pt) updates preview live
- [x] Theme: Light / Dark / Sepia / System
- [x] Show Translation → English appears/disappears below verses
- [x] **Transliteration** ⭐ → romanized Arabic appears below each verse (e.g. "Bismillah...")
- [x] Tajweed Colors → colored Arabic text with rule highlighting

### Translation Language ⭐
- [ ]  5 options: English, Urdu, French, Turkish, Indonesian 
- [ ] Switch language → tap a word → popover shows meaning in new language

### Offline Downloads ⭐
- [x] Settings → Offline Downloads → shows all 114 surahs
- [x] Tap ⬇ on Al-Fatihah (7 verses, fast) → progress bar fills → icon becomes 🗑️
- [x] **Airplane Mode test** ⭐ (most important):
  1. Download Al-Fatihah
  2. Enable Airplane Mode
  3. Close and reopen the app
  4. Play Al-Fatihah → audio must play from cache with no internet
- [x] Tap 🗑️ → download icon returns
- [x] "Clear All" removes all cached audio

---

## 🎵 Audio

### Playback
- [x] "Play Surah" starts from verse 1, currently playing verse has green background
- [ ] Words highlight one-by-one in sync with the reciter
- [x] Auto-scrolls to keep playing verse in view
- [x] Individual ▶ on each verse plays just that verse
- [ ] Lock screen / Control Center shows track with play/pause/skip

### Controls
- [x] Speed cycles: 0.5× / 0.75× / 1× / 1.25× / 1.5×
- [x] **Repeat button** ⭐ cycles **1× → 2× → 3× → ∞**, turns green when active
- [ ] Reciter picker: Mishary Al-Afasy ↔ Abdul-Basit
- [x] Stop button stops playback; mini player bar persists when navigating away

---

## 🔖 Bookmarks
- [x] Bookmarks tab shows all saved bookmarks with surah name + verse number
- [x] Swipe-to-delete removes bookmark
- [ ] Tap bookmark → opens correct surah

---

## 🔄 Persistence (close & reopen the app)
- [x] Font size stays the same after restart
- [x] Theme (dark/light/sepia) stays the same
- [x] Transliteration toggle state is remembered
- [ ] Selected translation language is remembered
- [x] Bookmarks are still there
- [ ] Last read position remembered (app resumes where you left off)

---

## 🐛 Report These If You See Them
| Symptom | What to say |
|---|---|
| Arabic text shows boxes/? | Font not loading — check console |
| Word popover shows "Loading…" forever | API not reachable |
| Transliteration shows nothing | API not reachable |
| App crashes on launch | Send crash log from Xcode |
| Offline audio doesn't play after download | Cache path issue |
