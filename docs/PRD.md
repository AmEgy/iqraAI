# Product Requirements Document (PRD)

## QariAI — Quran Companion App

| Field | Value |
|-------|-------|
| **Author** | — |
| **Version** | 1.0 |
| **Date** | February 19, 2026 |
| **Platform** | iOS 17+ (iPhone & iPad) |
| **Status** | Draft — Pre-Development |

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Problem Statement](#2-problem-statement)
3. [Goals & Success Metrics](#3-goals--success-metrics)
4. [User Personas](#4-user-personas)
5. [Feature Requirements](#5-feature-requirements)
6. [User Flows](#6-user-flows)
7. [Technical Architecture](#7-technical-architecture)
8. [Data Integrity Protocol](#8-data-integrity-protocol)
9. [Monetization](#9-monetization)
10. [Design & UX Guidelines](#10-design--ux-guidelines)
11. [Development Phases & Checklist](#11-development-phases--checklist)
12. [Risk Register](#12-risk-register)
13. [Open Questions](#13-open-questions)

---

## 1. Executive Summary

QariAI is a native iOS app that helps Muslims read, listen to, and practice reciting the Quran with AI-powered pronunciation feedback. It combines a beautiful Quran reader, a verse-by-verse audio player with word highlighting, and a real-time recitation checker that uses on-device speech recognition to identify mistakes in word accuracy and (in later versions) tajweed rules. Two practice modes — Reading Mode (text visible) and Memorization Mode (text hidden) — serve both learners and those working on hifz (memorization).

The app is built with a **privacy-first, offline-first** architecture: speech recognition runs entirely on-device via CoreML, requiring zero server infrastructure for the core feature. Quranic text is bundled locally from scholar-verified sources to guarantee 100% accuracy.

---

## 2. Problem Statement

**For learners:** Millions of Muslims want to improve their Quran recitation but don't have consistent access to a qualified teacher (Qari). Existing apps either lack AI feedback entirely or require expensive subscriptions ($60+/year).

**For memorizers (Huffaz):** Practicing hifz alone is unreliable — there's no one to catch mistakes when reciting from memory. Current solutions are either low-accuracy or require always-on internet.

**The gap:** No affordable iOS app combines a verified Quran reader + audio player + on-device AI recitation feedback + memorization testing in one product with an offline-first approach.

---

## 3. Goals & Success Metrics

### Product Goals

| Goal | Measure | Target (6 months post-launch) |
|------|---------|-------------------------------|
| User acquisition | Total downloads | 50,000 |
| Engagement | DAU / MAU ratio | > 25% |
| Retention | Day 30 retention | > 20% |
| Monetization | Monthly Recurring Revenue | $2,000+ |
| Accuracy trust | User-reported text errors | 0 (zero tolerance) |
| Recitation accuracy | Word-detection precision | > 90% |

### Non-Goals (V1)

- Android support (future phase)
- Full tajweed phonetic analysis (V2)
- Social features / community
- Live teacher marketplace
- Tafsir (commentary) content

---

## 4. User Personas

### Persona 1: Amina — "The Learner"

| Attribute | Detail |
|-----------|--------|
| **Age** | 24 |
| **Location** | London, UK |
| **Goal** | Improve her recitation; she reads slowly and makes pronunciation mistakes |
| **Pain** | Can't afford weekly Quran teacher sessions. Feels embarrassed reciting in front of others. |
| **Behavior** | Practices 15–20 min/day, usually before Fajr or after Isha. Prefers reading on her phone. |
| **Needs** | Word-by-word feedback, ability to listen to correct pronunciation, translation side-by-side |

### Persona 2: Yusuf — "The Memorizer"

| Attribute | Detail |
|-----------|--------|
| **Age** | 17 |
| **Location** | Cairo, Egypt |
| **Goal** | Complete hifz of the Quran. Currently on Juz 22. |
| **Pain** | No one available to test him daily. He makes small word-swap errors between similar verses and doesn't catch them. |
| **Behavior** | Recites 2–3 pages daily from memory. Needs review (muraja'ah) of previously memorized sections. |
| **Needs** | Memorization mode with hidden text, first-letter hints, progressive reveal |

### Persona 3: Khalid — "The Listener"

| Attribute | Detail |
|-----------|--------|
| **Age** | 42 |
| **Location** | Houston, TX |
| **Goal** | Listen to Quran during commute, read along with translation |
| **Pain** | Current apps are cluttered or have poor audio controls. |
| **Behavior** | Listens 30–60 min/day. Reads translation to understand meaning. |
| **Needs** | Clean audio player, continuous playback, background audio, bookmarking |

---

## 5. Feature Requirements

### 5.1 Quran Reader (FREE)

| ID | Requirement | Priority | Acceptance Criteria |
|----|------------|----------|-------------------|
| QR-01 | Display full Quran text in Uthmani script (Hafs 'an Asim) | P0 | All 6,236 verses render correctly with full tashkeel (diacritics) |
| QR-02 | Tajweed color-coding on Arabic text | P0 | Each tajweed rule category has a distinct color per standard color schemes |
| QR-03 | Navigate by Surah (114), Juz (30), Hizb (60), Page (604) | P0 | Tapping any section instantly scrolls to correct position |
| QR-04 | Word-by-word translation (English default, expandable) | P1 | Tapping a word shows its individual translation in a popover |
| QR-05 | Full verse translation (multiple languages) | P1 | At least 5 languages at launch |
| QR-06 | Transliteration toggle | P2 | Romanized pronunciation appears below Arabic text when enabled |
| QR-07 | Adjustable font size | P0 | Slider from 16pt to 40pt; persists across sessions |
| QR-08 | Dark mode / Light mode / Sepia | P1 | Respects system setting + manual override |
| QR-09 | Bookmarking | P0 | Tap to bookmark any verse; bookmarks listed in a dedicated tab |
| QR-10 | Last-read position auto-resume | P0 | App reopens to exact last-read verse |
| QR-11 | Search by surah name, verse number, or translation keyword | P1 | Results appear within 300ms for local search |
| QR-12 | Mushaf mode (page-by-page layout) | P2 | Renders text per the standard 604-page Madani mushaf layout |

### 5.2 Audio Player (FREE)

| ID | Requirement | Priority | Acceptance Criteria |
|----|------------|----------|-------------------|
| AP-01 | Verse-by-verse audio playback | P0 | Plays audio for selected verse; auto-advances to next verse |
| AP-02 | Continuous playback (surah / juz / custom range) | P0 | User selects start and end verse; plays continuously |
| AP-03 | Word-level highlighting during playback | P0 | Each word highlights in sync with audio (±200ms tolerance) |
| AP-04 | At least 2 reciters in free tier | P0 | Mishary Al-Afasy + Abdul-Basit Abdul-Samad |
| AP-05 | Playback speed control | P1 | 0.5x, 0.75x, 1.0x, 1.25x, 1.5x |
| AP-06 | Repeat verse / range N times | P1 | User sets repeat count (1–99) or infinite loop |
| AP-07 | Background audio playback | P0 | Audio continues when app is backgrounded or screen is locked |
| AP-08 | Lock screen / Control Center controls | P0 | Play/pause, skip forward/back appear in iOS media controls |
| AP-09 | Audio download for offline playback | P1 | Download by surah or juz; shows download progress |

### 5.3 Recitation Engine — Reading Mode (FREE basic, PREMIUM advanced)

| ID | Requirement | Priority | Tier | Acceptance Criteria |
|----|------------|----------|------|-------------------|
| RE-01 | Mic capture with real-time streaming | P0 | Free | Audio captured at 16kHz mono |
| RE-02 | On-device speech-to-text (WhisperKit + Quran model) | P0 | Free | Transcription runs on-device; no network request |
| RE-03 | Word-level accuracy comparison | P0 | Free | correct = green, wrong = red, skipped = yellow |
| RE-04 | Auto-advance verse tracking | P0 | Free | Next verse auto-loads on completion |
| RE-05 | "Show correct word" on tap | P0 | Free | Tapping a red/yellow word plays reference audio |
| RE-06 | Recitation session summary | P1 | Free | Accuracy %, words missed, total verses |
| RE-07 | Tajweed rule feedback | P1 | **Premium** | Rule-specific correction |
| RE-08 | Voice comparison | P2 | **Premium** | Side-by-side user vs. reciter waveform |
| RE-09 | Historical accuracy trends | P1 | **Premium** | Chart showing accuracy % over time |

### 5.4 Recitation Engine — Memorization Mode (PREMIUM)

| ID | Requirement | Priority | Acceptance Criteria |
|----|------------|----------|-------------------|
| HZ-01 | Hidden text mode | P0 | Verse text blurred/blank; only verse number shown |
| HZ-02 | Progressive reveal on error | P0 | Correct word appears briefly (1.5s) then re-hides |
| HZ-03 | "First letter hints" option | P1 | Shows only first letter of each word |
| HZ-04 | Streak tracking per surah | P1 | Consecutive correct recitations counted |
| HZ-05 | Spaced repetition scheduler | P2 | Algorithmically schedules review sessions |
| HZ-06 | Juz/Surah completion badges | P2 | Visual badges for memorization milestones |

### 5.5 User Account & Sync (FREE with account)

| ID | Requirement | Priority | Acceptance Criteria |
|----|------------|----------|-------------------|
| UA-01 | Sign in with Apple | P0 | One-tap sign in |
| UA-02 | Email/password sign in | P1 | Firebase Auth |
| UA-03 | Guest mode (no sign in) | P0 | Full free features without account |
| UA-04 | Cross-device sync (with account) | P1 | Bookmarks, position, history via Firestore |
| UA-05 | Profile with recitation stats | P1 | Total verses, accuracy average, streak |

### 5.6 Engagement & Retention (FREE)

| ID | Requirement | Priority | Acceptance Criteria |
|----|------------|----------|-------------------|
| EN-01 | Daily verse notification (opt-in) | P1 | Push notification at user-chosen time |
| EN-02 | Daily goal setting | P1 | Progress bar on home screen |
| EN-03 | Streak counter | P0 | Days of consecutive usage |
| EN-04 | "Ayah of the Day" on home screen | P2 | Curated verse displayed |

---

## 6. User Flows

### 6.1 First Launch
```
App Launch → Welcome screen → "Continue as Guest" OR "Sign In with Apple"
  → Microphone permission prompt → Home screen
```

### 6.2 Reading Flow
```
Home → Select Surah → Tap play ▶ → audio plays, words highlight
  → Tap word for translation → Bookmark → Close (position saved)
```

### 6.3 Recitation — Reading Mode
```
Home → Select Surah → "Recite" → Reading Mode
  → Verse with tajweed coloring → Tap mic → Recite
  → Words turn green/red/yellow → Auto-advance → Session summary
```

### 6.4 Recitation — Memorization Mode (Premium)
```
Home → Select Surah → "Recite" → Memorization Mode
  → [Paywall if not premium]
  → Verse number shown, text hidden → Tap mic → Recite
  → Wrong word: flashes correct word → Verse restarts
  → Complete correctly → Next verse → Session summary + streak
```

### 6.5 Subscription Purchase
```
User taps locked feature → Paywall (RevenueCat)
  → Monthly ($4.99) / Annual ($29.99, "Save 50%") / 7-day trial
  → Apple payment sheet → Success → Feature unlocked
```

---

## 7. Technical Architecture

### 7.1 Stack Summary

| Component | Technology | Cost |
|-----------|-----------|------|
| Language | Swift 5.9+ | Free |
| UI | SwiftUI (iOS 17+) | Free |
| Architecture | MVVM + async/await | Free |
| On-device ASR | WhisperKit (CoreML) | Free |
| ASR Model | tarteel-ai/whisper-base-ar-quran | Free |
| Local DB | SQLite via GRDB.swift | Free |
| Audio Engine | AVAudioEngine + AVAudioSession | Free |
| Auth | Firebase Authentication (Spark) | Free |
| Cloud DB | Firebase Firestore (Spark) | Free |
| Push | Firebase Cloud Messaging | Free |
| Crash reporting | Firebase Crashlytics | Free |
| Analytics | Firebase Analytics | Free |
| Subscriptions | RevenueCat SDK | Free |
| Quran text | Bundled SQLite (Quran Foundation) | Free |
| Quran audio | Quran Foundation CDN / MP3Quran.net | Free |
| Tajweed data | Quran Foundation API + cpfair/quran-tajweed | Free |

### 7.2 Data Flow — Recitation Engine

```
[Microphone] → [AVAudioEngine] 16kHz mono Float32
  → [WhisperKit] CoreML on-device inference
  → [Raw Transcription] Arabic text
  → [Comparison Engine]
      ├─ Expected text (local SQLite)
      ├─ Levenshtein edit distance (word-level)
      └─ Constrained matching (current/nearby verses)
  → [Result per word] correct | wrong | skipped | extra
  → [UI Update] green / red / yellow highlighting
```

### 7.3 Offline-First Architecture

```
BUNDLED (always available):
  ✓ Full Quran text (Uthmani, ~3MB SQLite)
  ✓ Tajweed annotations (JSON, ~1MB)
  ✓ Word-by-word translations (English, ~5MB)
  ✓ ASR model weights (~150MB, downloaded on first launch)

ON DEMAND (cached locally):
  ◐ Audio files per reciter per surah
  ◐ Additional translation languages

REQUIRES NETWORK (non-critical):
  ○ Account sync (Firestore)
  ○ Push notifications (FCM)
  ○ Subscription validation (RevenueCat)
```

---

## 8. Data Integrity Protocol

> **The Quran must be 100% accurate. There is no margin for error.**

| Step | Action | Verification |
|------|--------|-------------|
| 1 | Obtain Uthmani text from Tanzil.net (King Fahd Complex-verified) | Download with full tashkeel |
| 2 | Import into SQLite with surah, ayah, juz, hizb, page metadata | Row count = exactly 6,236 verses |
| 3 | Generate SHA-256 checksum of complete text database | Store in app binary |
| 4 | At app launch, verify checksum | Mismatch → refuse to display text |
| 5 | Cross-reference against Quran Foundation API | Non-matching API text rejected |

**Recitation Feedback Disclaimer (required in UI):**
> *"QariAI's recitation feedback is an assistive learning tool and does not replace a qualified Quran teacher. Always verify your recitation with a knowledgeable instructor."*

---

## 9. Monetization

| Plan | Price | Includes |
|------|-------|---------|
| **Free** | $0 | Full reader, tajweed, 2 reciters, basic recitation, bookmarks, search |
| **Premium Monthly** | $4.99/mo | + Memorization Mode, advanced tajweed, 10+ reciters, offline audio, analytics, spaced repetition |
| **Premium Annual** | $29.99/yr | Same as monthly (50% savings) |
| **Free Trial** | 7 days | Full Premium access |

**Cost at Launch:** ~$10/month total (Apple Developer: $8.25/mo, everything else free tier).

---

## 10. Design & UX Guidelines

### Tajweed Color Scheme

| Rule | Color | Hex |
|------|-------|-----|
| Ghunnah | Orange | #FF7F00 |
| Ikhfaa | Purple | #9400D3 |
| Iqlab | Green | #228B22 |
| Idgham (with ghunnah) | Orange | #FF7F00 |
| Idgham (without ghunnah) | Blue | #4169E1 |
| Qalqalah | Crimson | #DC143C |
| Madd (obligatory) | Red | #FF0000 |
| Madd (permissible) | Pink | #FF69B4 |
| Silent letters | Gray | #808080 |

### Recitation Feedback Colors

| State | Color | Hex |
|-------|-------|-----|
| Correct word | Green | #22C55E |
| Wrong word | Red | #EF4444 |
| Skipped word | Amber | #F59E0B |
| Extra word | Purple | #8B5CF6 |
| Pending | Gray | #6B7280 |

### Typography

| Use | Font |
|-----|------|
| Quran Arabic text | KFGQPC Uthmani Hafs → Scheherazade New → Amiri |
| UI Arabic | SF Arabic |
| UI English | SF Pro |

---

## 11. Development Phases & Checklist

### Phase 1: Foundation (Weeks 1–4) ✅ COMPLETE
- [x] Set up Xcode project (Swift, SwiftUI, iOS 17+, MVVM)
- [x] Configure Git repository
- [x] Import Uthmani Quran text into SQLite database
- [x] Build tajweed tag parser for color-coded rendering
- [x] Install and configure Scheherazade New font
- [x] Build Surah list screen
- [x] Build verse display screen with RTL Arabic text
- [x] Implement tajweed color-coding
- [x] Implement verse bookmarking
- [x] Implement last-read position auto-save

### Phase 2: Audio Player (Weeks 5–7) ✅ COMPLETE
- [x] Build audio player service (AVAudioEngine / AVPlayer)
- [x] Implement verse-by-verse playback with auto-advance
- [x] Build word-highlighting sync engine
- [x] Enable background audio
- [x] Implement lock screen / Control Center media controls

### Phase 3: Recitation Engine (Weeks 8–12) ⬜ NEXT
- [ ] Set up Python environment for model conversion
- [ ] Download tarteel-ai/whisper-base-ar-quran from HuggingFace
- [ ] Convert Whisper model to CoreML format
- [ ] Integrate WhisperKit Swift package via SPM
- [ ] Load CoreML model in WhisperKit
- [ ] Build mic capture pipeline (AVAudioEngine → 16kHz mono)
- [ ] Request/handle microphone permission
- [ ] Implement real-time audio streaming to WhisperKit
- [ ] Build comparison engine (transcription vs expected verse)
- [ ] Implement Levenshtein edit distance at word level
- [ ] Build Reading Mode UI (mic button, listening indicator, real-time word coloring)
- [ ] Auto-advance to next verse on completion
- [ ] "Tap to hear correct pronunciation" on wrong words
- [ ] Session summary screen (accuracy %, verses, time)
- [ ] Build Memorization Mode UI (hidden text, first-letter hints, progressive reveal)
- [ ] Add recitation feedback disclaimer
- [ ] Performance benchmarks (<2s inference, <500MB RAM)

### Phase 4: Accounts, Sync & Premium (Weeks 13–15) ⬜
- [ ] Firebase Auth (Apple Sign-In + email)
- [ ] Firestore cloud sync (bookmarks, progress)
- [ ] RevenueCat subscriptions ($4.99/mo, $29.99/yr)
- [ ] Paywall UI + 7-day free trial
- [ ] Gate premium features
- [ ] Push notifications + daily verse
- [ ] Streak counter + daily goals

### Phase 5: Polish & Launch (Weeks 16–18) ⬜
- [ ] Scholar review of text + tajweed
- [ ] TestFlight beta (50+ testers)
- [ ] Performance optimization
- [ ] Accessibility audit
- [ ] App Store assets + submission

---

## 12. Risk Register

| # | Risk | Probability | Impact | Mitigation |
|---|------|------------|--------|-----------|
| R1 | Quranic text displayed incorrectly | Low | **Critical** | Checksum verification, scholar review, bundled text |
| R2 | ASR accuracy too low | Medium | High | Constrained vocabulary matching, fallback to verse-level |
| R3 | WhisperKit model too large for older iPhones | Low | Medium | whisper-tiny for older devices |
| R4 | Arabic text rendering bugs | Medium | Medium | UIKit fallback |
| R5 | App Store rejection | Low | High | Follow Apple guidelines; scholarly content only |
| R6 | Firebase free tier exceeded | Low | Low | Offline-first; monitor; upgrade Blaze if needed |
| R7 | Reciter audio copyright | Low | Medium | Open/permissive sources only |
| R8 | Non-standard dialect pronunciation | High | Medium | State Hafs 'an Asim support; adjust matching tolerance |

---

## 13. Open Questions

| # | Question | Status |
|---|----------|--------|
| Q1 | iPad split-view Mushaf layout? | Open |
| Q2 | Which exact reciters for free tier? | Open |
| Q3 | Bundle ASR model in app or download on first launch? | Leaning: download |
| Q4 | Privacy policy review for on-device audio? | Open |
| Q5 | Partial verse hiding in memorization mode? | Open |
| Q6 | App name trademark check: QariAI? | Open |
| Q7 | Lifetime purchase option? | Open |
| Q8 | Which scholars for endorsement/review? | Open |

---

*End of PRD — update as decisions are made and phases completed.*
