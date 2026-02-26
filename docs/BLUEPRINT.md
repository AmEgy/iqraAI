# Quran Companion App — Technical Blueprint

**Project Codename:** *Qari* (القارئ — "The Reciter")
**Platform:** iOS (iPhone, iPad)
**Dev Machine:** MacBook Air M4 + Xcode
**Date:** February 2026

---

## 1. Executive Summary

This document maps out the full technology stack, architecture, data sources, hosting strategy, monetization model, and phased roadmap for building an iOS Quran app with the following core capabilities:

1. **Read** — Full Quran text with tajweed color-coding
2. **Listen** — Stream professional recitations (multiple reciters)
3. **Recite & Correct** — Real-time speech recognition detecting word errors and tajweed violations
4. **Memorize (Hifz)** — Ayat hidden, user recites from memory
5. **Read-Along** — Text visible, live word highlighting

**Paramount constraint:** The Quranic text must be 100% accurate. No AI generation, interpolation, or approximation. Ever.

---

## 2. Competitive Landscape

### Tarteel AI (Primary Competitor)
- React Native, NVIDIA Riva + NeMo ASR, 10M+ downloads
- Tajweed phonetic feedback: on roadmap / partial — **our opportunity**

### Our Differentiation

| Feature | Tarteel | **Qari (Ours)** |
|---|---|---|
| Real-time recitation feedback | ✅ | ✅ |
| Hidden-text hifz mode | ✅ | ✅ |
| Tajweed phonetic correction | 🟡 Partial | ✅ (Phase 2) |
| Free core experience | ❌ Limited | ✅ |
| Offline-first | 🟡 | ✅ |
| Native iOS (Swift, not React Native) | ❌ | ✅ |

---

## 3. Technology Stack

### Language & UI
**Swift + SwiftUI (primary) with UIKit bridges**
- Minimum deployment: iOS 17
- UIViewRepresentable for complex Arabic/tajweed text rendering
- Direct access to AVFoundation, CoreML, Speech — no JS bridge overhead

### Architecture
**MVVM + Clean Architecture + Swift Concurrency (async/await)**

```
Views (SwiftUI)
  └─ ViewModels (@Observable)
       └─ Use Cases / Interactors
            ├─ Repositories
            ├─ Local DB (GRDB / SwiftData)
            └─ Services (Audio, Speech, Network)
```

### Quran Text
**Primary: Quran.Foundation API v4**
- `text_uthmani` — Uthmani script with full tashkeel
- `text_uthmani_tajweed` — with inline tajweed rule annotations
- Word-by-word data with translations + timing segments

**Offline:** Download full text on first launch → store in SQLite → SHA-256 verify on every launch

**Tajweed Annotations:** `cpfair/quran-tajweed` (CC-BY 4.0)

### Audio
| Source | What It Provides |
|---|---|
| Quran.Foundation API | Verse audio + word-level timestamps (10+ reciters) |
| Al Quran Cloud API | Full surah/verse audio (100+ reciters) |
| MP3Quran.net API | Full surah MP3s, 200+ reciters |

### Speech Recognition

**Phase 1 (MVP):** Apple Speech Framework (`SFSpeechRecognizer`)
- Free, on-device Arabic, word-level edit-distance comparison

**Phase 2:** WhisperKit (CoreML) + `tarteel-ai/whisper-base-ar-quran`
- ~5.75% WER on Quranic recitation, runs fully on-device

**Phase 3:** Tajweed rule detection via `quranicphonemizer` + CoreML classifier
- Qalqalah → Madd → Ghunna → Ikhfa/Idgham → Makhaarij

### Local Database
**GRDB.swift** (SQLite) — fast queries, no migration complexity for read-heavy Quran text

### Backend (Zero-Cost)
**Firebase Spark Plan:**
- Auth (50K MAU free), Firestore (1GB, 50K reads/day)
- Cloud Functions (2M/mo), Crashlytics, Analytics, FCM — all free
- **Only hard cost: $99/year Apple Developer account**

---

## 4. Data Flow — Recitation Engine

```
[Microphone]
  └─ AVAudioEngine (16kHz mono Float32)
       └─ WhisperKit (on-device CoreML)
            └─ Raw Arabic transcription
                 └─ Comparison Engine
                      ├─ Expected text (local SQLite)
                      ├─ Levenshtein word-level distance
                      └─ Constrained vocabulary (current verse)
                           └─ UI: green / red / yellow / purple per word
```

---

## 5. Offline-First Architecture

```
BUNDLED (always available):
  ✓ Quran text (~3MB SQLite)
  ✓ Tajweed annotations (~1MB JSON)
  ✓ English word-by-word translations (~5MB)

DOWNLOADED ON DEMAND (cached):
  ◐ ASR model (~150MB, first launch)
  ◐ Audio files per reciter/surah (~50MB each)
  ◐ Additional languages

REQUIRES NETWORK (non-critical):
  ○ Account sync (Firestore)
  ○ Push notifications (FCM)
  ○ Subscription validation (RevenueCat ↔ App Store)
```

---

## 6. Folder Structure

```
iqraAI/
├── App/              # Entry point, app setup, DI
├── Core/
│   ├── Models/       # Surah, Ayah, Word, TajweedAnnotation, Reciter, UserProgress
│   ├── Database/     # GRDB setup, QuranDatabase, integrity checker
│   └── Networking/   # API clients (Quran.Foundation, AlQuranCloud, AudioCDN)
├── Features/
│   ├── Reading/      # SurahListView, VerseReaderView, TajweedRenderer
│   ├── Listening/    # AudioPlayerService, WordHighlighter, MiniPlayerBar
│   ├── Recitation/   # SpeechRecognition, ComparisonEngine, RecitationView
│   ├── Memorization/ # HifzView, SpacedRepetition, ProgressTracker
│   ├── Bookmarks/    # BookmarksView
│   ├── Settings/     # SettingsView, SettingsViewModel
│   ├── Onboarding/
│   └── Premium/      # PaywallView, StoreKit 2
├── Services/         # Audio, Speech, Analytics, Notifications
└── Resources/        # Fonts, integrity hashes, assets, quran.db
```

---

## 7. Arabic Text Rendering

- **Fonts:** Scheherazade New (bundled) → KFGQPC Uthmanic Script HAFS (ideal)
- **Tajweed:** `AttributedString` with character-range annotations from tajweed JSON
- **RTL:** `Environment(\.layoutDirection, .rightToLeft)` on all Quran views
- **Fallback:** `UIViewRepresentable` wrapping `UILabel` with `NSAttributedString` if SwiftUI Text has diacritic issues

---

## 8. Monetization

| Plan | Price | Features |
|------|-------|---------|
| Free | $0 | Reader, tajweed, 2 reciters, basic recitation |
| Premium Monthly | $4.99/mo | + Memorization, advanced tajweed, 10+ reciters, analytics |
| Premium Annual | $29.99/yr | Same (50% savings) |
| Free Trial | 7 days | Full premium |

**Monthly costs at launch: ~$10/month. Profitable at 3 subscribers.**

---

## 9. Scholarly Accuracy Safeguards

1. Text from Tanzil.net via Quran.Foundation API only
2. SHA-256 hash per surah, hardcoded in binary
3. Runtime verification on every launch
4. **No AI text generation. Ever.**
5. Human review before every release
6. In-app report button for text issues

---

## 10. Technology Summary

| Decision | Choice | Cost |
|---|---|---|
| Language | Swift | Free |
| UI | SwiftUI + UIKit bridges | Free |
| Persistence | GRDB (SQLite) | Free |
| Quran API | Quran.Foundation v4 | Free |
| Audio | Quran.Foundation + Al Quran Cloud CDNs | Free |
| Speech (MVP) | Apple Speech Framework | Free |
| Speech (v2) | WhisperKit on-device | Free |
| Tajweed data | cpfair/quran-tajweed (CC-BY 4.0) | Free |
| Backend | Firebase Spark | Free |
| Payments | RevenueCat + StoreKit 2 | Free |
| CI/CD | GitHub Actions | Free |
| Crash/Analytics | Firebase | Free |
| **Total recurring** | | **~$10/month** |

---

## 11. Phased Roadmap

| Phase | Weeks | Goal |
|-------|-------|------|
| 1 | 1–4 | Reading + tajweed display ✅ |
| 2 | 5–7 | Audio player + word highlighting ✅ |
| 3 | 8–12 | Recitation engine (WhisperKit) |
| 4 | 13–15 | Accounts + sync + subscriptions |
| 5 | 16–18 | Polish + TestFlight + App Store |
| 6+ | Ongoing | Tajweed ML (V2), Android, growth |

---

## 12. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Text accuracy | SHA-256 check + human review + no AI generation |
| ASR accuracy | Quran-tuned Whisper (Phase 2) + constrained vocabulary |
| Whisper slow on old iPhones | whisper-tiny for A13 and older |
| Arabic rendering bugs | UIKit fallback |
| API goes down | Full offline text from day 1 |

---

*بسم الله الرحمن الرحيم*
