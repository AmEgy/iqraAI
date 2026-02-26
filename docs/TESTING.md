# QariAI — Friend Testing Checklist
**Device:** iPhone iOS 18 · **Build:** Pull `main` and run from Xcode

---

## 🚀 Launch
- [ ] App opens with a green shield spinner briefly, then loads normally
- [ ] **Red shield "Data Integrity Error"** screen = DB corrupted → tell Ahmed immediately

---

## 📖 Reading

### Surah List
- [ ] 114 surahs with Arabic names, English names, verse counts
- [ ] Search bar filters by Arabic, English, or transliteration
- [ ] **Navigation tabs:** Surah / Juz / **Page** / **Hizb** all appear and work
  - Page tab: 604 pages, tap one → opens its verses
  - Hizb tab: 60 hizbs with "Juz X, 1st/2nd half" subtitle

### Verse Reader
- [ ] Arabic text renders with full diacritics (no boxes or ?)
- [ ] Tap a verse → reading position saved
- [ ] Bookmark icon fills green when tapped
- [ ] Long-press verse → action sheet (Bookmark / Copy Arabic / Copy Translation)
- [ ] **Tap any Arabic word** ⭐ → popover shows word + English meaning + "Word X of Y"

---

## ⚙️ Settings

### Display
- [ ] Font size slider (18–44pt) updates preview live
- [ ] Theme: Light / Dark / Sepia / System
- [ ] Show Translation → English appears/disappears below verses
- [ ] **Transliteration** ⭐ → romanized Arabic appears below each verse (e.g. "Bismillah...")
- [ ] Tajweed Colors → colored Arabic text with rule highlighting

### Translation Language ⭐
- [ ] 5 options: English, Urdu, French, Turkish, Indonesian
- [ ] Switch language → tap a word → popover shows meaning in new language

### Offline Downloads ⭐
- [ ] Settings → Offline Downloads → shows all 114 surahs
- [ ] Tap ⬇ on Al-Fatihah (7 verses, fast) → progress bar fills → icon becomes 🗑️
- [ ] Turn on **Airplane Mode** → play Al-Fatihah → audio still plays from cache
- [ ] Tap 🗑️ → download icon returns
- [ ] "Clear All" removes all cached audio

---

## 🎵 Audio

### Playback
- [ ] "Play Surah" starts from verse 1, currently playing verse has green background
- [ ] Words highlight one-by-one in sync with the reciter
- [ ] Auto-scrolls to keep playing verse in view
- [ ] Individual ▶ on each verse plays just that verse
- [ ] Lock screen / Control Center shows track with play/pause/skip

### Controls
- [ ] Speed cycles: 0.5× / 0.75× / 1× / 1.25× / 1.5×
- [ ] **Repeat button** ⭐ cycles **1× → 2× → 3× → ∞**, turns green when active
- [ ] Reciter picker: Mishary Al-Afasy ↔ Abdul-Basit
- [ ] Stop button stops playback; mini player bar persists when navigating away

---

## 🔖 Bookmarks
- [ ] Bookmarks tab shows all saved bookmarks with surah name + verse number
- [ ] Swipe-to-delete removes bookmark
- [ ] Tap bookmark → opens correct surah

---

## 🐛 Report These If You See Them
| Symptom | What to say |
|---|---|
| Arabic text shows boxes/? | Font not loading — check console |
| Word popover shows "Loading…" forever | API not reachable |
| Transliteration shows nothing | API not reachable |
| App crashes on launch | Send crash log from Xcode |
| Offline audio doesn't play after download | Cache path issue |
