# Snuglo — App Specification

> Cozy block-logic puzzle for iOS. Fit colored blocks into a grid until every cell is covered.

**App name:** Snuglo
**Platform (v1.0):** iOS 17+, iPhone only (iPad in v1.1)
**Tech stack:** Swift 5.9+, SwiftUI, SwiftData, StoreKit 2
**Status:** Pre-development spec (v0.1)

---

## 1. Concept & Positioning

**Pitch (one sentence):**
> A casual logic puzzle: fit colored rectangular blocks into a grid so every cell is covered, no overlap, no overflow.

- **Genre:** Logic / Brain / Puzzle
- **References / competitors:** Wood Block Puzzle, Block Blast, Shikaku, Knotwords, Two Dots, Polysphere
- **Tone:** Warm, minimal, "cozy" — Saturday-morning coffee aesthetic
- **Target audience:** 25–55, daily puzzle solvers, "play during a coffee break" intent
- **Target session length:** 3–8 minutes

**Brand personality:**
- "Snug" → comfortable, warm, settled; "lo" → minimal modern suffix
- Visual: warm coral/pink background, cream board, pastel blocks, soft shadow, tactile feedback
- **Never:** harsh neon, aggressive sound, FOMO/anxiety mechanics

---

## 2. Core Game Mechanic

### Rules
1. **Grid** — fixed-size grid per level (5×5 up to 10×10)
2. **Blocks (pieces)** — each is a rectangle with a number = its area in cells
3. **Goal:** Place all blocks so they completely cover the grid
   - All cells must be covered (no gaps)
   - Blocks cannot overlap
   - Blocks cannot extend outside the grid
4. The sum of block areas always equals the grid cell count

### Interaction
- **Long-press → pick up** (light haptic)
- **Drag** — block follows finger
- **Snap** — to cell centers within ±15pt tolerance
- **Invalid placement (overlap or out-of-bounds):** red highlight on the block; on release, ease-back to start
- **Valid placement:** soft haptic + small "settle" animation
- **Auto-detect solved state** when all blocks placed validly → trigger Level Complete

### MVP decisions
| Question | Decision | Rationale |
|---|---|---|
| Rotation? | **No** | Adds complexity, steeper learning curve. Consider for v1.2. |
| Initial block layout | **Tray below grid** | Standard pattern, clear affordance |
| Undo | **Yes, multi-level stack** | Encourages exploration |
| Restart button | **Yes** | Confirmation dialog |

---

## 3. Information Architecture

### Screens
```
1. Splash (logo, ~0.8s)
2. Onboarding (first launch only, 3 swipeable screens)
3. Main Menu / Lobby
4. Levels List (pack picker)
5. Pack Detail (grid of levels)
6. Game (main play screen)
7. Pause Overlay
8. Level Complete (modal sheet)
9. Settings
10. Stats / Profile
11. Shop / IAP
12. About / Credits / Legal
```

### Navigation
- Native iOS `NavigationStack` (push) from Main → everything
- Game screen presented as full-screen modal (swipe-down dismissal disabled)

---

## 4. Screen Detail

### 4.1 Splash
- Logo (Snuglo wordmark + small grid icon)
- Background: brand coral (`#E37B7B`)
- Duration: 600–900ms, fade in/out
- During splash: prefetch data, load saved state

### 4.2 Onboarding (3 screens, first launch only)
1. **"Welcome to Snuglo"** — headline + sub: *"A cozy puzzle to fit your day."*
2. **"How to play"** — animated mini-example (3×3 grid, 2 blocks settling)
3. **"Daily puzzle, every day"** — request notification permission (soft pre-prompt first)

- "Skip" button top right
- Final screen "Start playing" → Main Menu

### 4.3 Main Menu
- Top: user progress chip (`Level 12 of 240` + thin progress bar)
- Big **"Daily Puzzle"** card (top, eye-catching)
  - Date (`24 May`)
  - "Play today's puzzle" CTA
  - If completed: ✓ + finish time
- **"Continue"** card (last played level, if any)
- **"Levels"** button → pack list
- Bottom tab bar: Home / Levels / Stats / Shop / Settings

### 4.4 Levels List (Pack list)
- Vertical scroll
- Each pack: card (pack name, icon, `12 / 30 completed` progress)
- Pack examples: "Cozy Beginnings", "Spice Route", "Mambo Nights", "Crystal Garden"…
- Locked packs: grayed out, 🔒 icon + "Complete previous pack to unlock"

### 4.5 Pack Detail
- Top: pack name + theme artwork
- Grid: 3 columns, square tiles — each tile is a level (number + completion status)
  - Completed: shows star count (1–3)
  - Active (last played or next): glow border
  - Locked: gray + 🔒

### 4.6 Game (main play screen)

**Layout (top → bottom):**
```
┌──────────────────────────────┐
│ ←   [back]   ?[hint]  ⚙[settings] │  ← topbar (48dp)
│                                  │
│         Mambo                    │  ← level name (secondary text)
│         00:01:13                 │  ← timer (monospaced)
│                                  │
│  ┌────────────────────────┐      │
│  │                        │      │
│  │     PUZZLE GRID        │      │  ← grid, padding 24dp
│  │                        │      │
│  └────────────────────────┘      │
│                                  │
│  ┌────────────────────────┐      │  ← block tray
│  │  unplaced blocks       │      │
│  └────────────────────────┘      │
│                                  │
│            💡 (3)                │  ← hint button (FAB)
└──────────────────────────────┘
```

**Topbar:**
- `←` Back (pauses + returns to menu)
- `?` Help (shows rules)
- `⚙` Settings (per-session: sound, haptics)

**Header:**
- Level name (e.g., "Mambo", small center text)
- Timer (mono, large, counts up)

**Grid:**
- Theme: cream (`#EAE0D2`), grid lines 1px (`#D5C7B5`)
- Corner radius: 16dp
- Subtle inner shadow

**Blocks:**
- Filled with own color, number centered (semi-bold)
- Drop shadow (`0,2 blur 4 alpha 0.15`)
- While dragging: scale 1.05, shadow expands
- Invalid state: red border (`#E04848`)

**Hint button:**
- Floating, bottom-center
- Subtle glow halo
- Badge with remaining hint count
- Tap → 1 random block animates to its correct position and locks

**Game state machine:**
- `playing` (default)
- `dragging(blockId)` (block lifted)
- `paused` (app background or pause)
- `solved` (validation passed) → Level Complete

### 4.7 Pause Overlay
- Semi-transparent dark layer
- Center: "Paused" + 3 buttons: Resume / Restart / Home
- Timer freezes

### 4.8 Level Complete
- Modal sheet (slides up from bottom)
- Top: ✓ animation (SwiftUI animation)
- "Level complete!"
- Stats:
  - Time: `00:01:13`
  - Stars: ⭐⭐⭐ (based on thresholds)
  - "Used X hints" (if any — caps stars at 2)
- 3 buttons: **Next level** (primary), Replay, Home
- Confetti / soft particles (one-shot)

### 4.9 Settings
- Sound effects (toggle)
- Music (toggle + slider) — if BG music shipped
- Haptics (toggle)
- Theme: Light / Dark / System
- Color palette: Default / Colorblind-friendly (pattern-based)
- Notification: Daily reminder time (time picker)
- Restore purchases (button)
- Privacy Policy / Terms (links)
- Version + build (footer)

### 4.10 Stats
- Total levels solved
- Total play time
- Fastest solve
- Daily streak
- Average solve time
- Hint usage %
- Weekly/monthly charts (Swift Charts)

### 4.11 Shop
- Hint packs: 5 hints $0.99 / 25 hints $2.99 / Unlimited $4.99
- "Remove ads" — $2.99 one-time
- "Snuglo Plus" subscription — unlimited hints + ad-free + premium themes, $1.99/mo or $14.99/yr (7-day trial)
- Restore purchases button

---

## 5. Game Systems

### 5.1 Star System
- **3 stars:** Completed under `goldTime` AND 0 hints used
- **2 stars:** Completed under `silverTime` OR ≤1 hint
- **1 star:** Completed (any time, any hints)

`goldTime` and `silverTime` predefined per level in JSON.

### 5.2 Hint System
- Start: 3 hints
- Tap hint: 1 random block animates to its correct position and locks (cannot be moved again)
- Refill methods:
  - Daily login: +1 hint
  - Watch rewarded ad: +1 hint (cooldown 5 min)
  - IAP: shop bundles

### 5.3 Timer
- Stopwatch (counts up), visual only
- Affects star tier via `goldTime`
- Pauses with game state

### 5.4 Progression / Unlock
- Each pack contains 30 levels
- Pack 1 unlocked at launch
- Next pack unlocks when ≥80% of current pack completed with ⭐⭐ or better

### 5.5 Daily Puzzle
- No server — deterministic seed: `seed = YYYYMMDD`
- All users on the same day get the same puzzle
- Completing it increments daily streak
- Skipping does not break streak (only failing to complete on a calendar day after starting it)

---

## 6. Content / Levels

### MVP launch
- **4 packs × 30 levels = 120 levels** (hybrid: manual design + procedural generation)
- Difficulty increases within each pack
- Grid scaling: Pack1 = 5×5, Pack2 = 6×6, Pack3 = 7×7, Pack4 = 8×8

### Level data format (JSON)
```json
{
  "id": "pack-mambo-12",
  "pack": "Mambo Nights",
  "name": "Mambo",
  "grid": { "cols": 7, "rows": 8 },
  "blocks": [
    { "id": "b1", "w": 1, "h": 5, "color": "purple" },
    { "id": "b2", "w": 2, "h": 2, "color": "blue" },
    { "id": "b3", "w": 1, "h": 3, "color": "red" },
    { "id": "b4", "w": 2, "h": 3, "color": "orange" },
    { "id": "b5", "w": 1, "h": 2, "color": "green" },
    { "id": "b6", "w": 4, "h": 2, "color": "purple-light" }
  ],
  "solution": [
    { "blockId": "b1", "x": 0, "y": 2 }
  ],
  "initialPlacement": "tray",
  "goldTime": 60,
  "silverTime": 120
}
```

### Procedural level generator
- Algorithm: recursive rectangular subdivision of the grid
- Validation: solution must be unique OR within target difficulty band
- Output → human curation → ship

---

## 7. Visual Design System

### Color palette
| Token | Hex | Usage |
|---|---|---|
| Brand coral | `#E37B7B` | Background, splash, primary CTA |
| Cream board | `#EAE0D2` | Grid background |
| Grid lines | `#D5C7B5` | Grid cell borders |
| Purple | `#A78BC9` | Block color |
| Blue | `#7B9DC2` | Block color |
| Red/Coral | `#D08585` | Block color |
| Orange | `#E0A865` | Block color |
| Green | `#9CC290` | Block color |
| Lilac | `#C8AAD9` | Block color |
| Text primary | `#2A2520` | Headlines, numbers |
| Text secondary | `#7A6F66` | Subtitles, metadata |
| Success | `#7CA572` | Level complete accent |
| Error | `#C9554E` | Invalid placement |

### Typography (iOS)
- Headings: **SF Rounded** semi-bold
- Numbers (timer, block sizes): **SF Mono** medium
- Body: **SF Pro** regular
- Sizes: title 24, subtitle 17, body 15, caption 12

### Iconography
- SF Symbols, outline style, stroke 2px

### Spacing & radii
- Base unit: 4dp
- Card radius: 16dp
- Button radius: 12dp
- Block radius: 8dp

### Animation
- Curves: spring (response 0.35, damping 0.7)
- Durations: 200–400ms range
- Block pick-up: scale 1.0 → 1.05, shadow expand (200ms)
- Block drop-snap: ease-out cubic 200ms
- Level complete: 600ms staggered

---

## 8. Sound Design

### Background music
- Soft jazz / lo-fi loop (optional, **default OFF**)

### SFX
| Event | Sound |
|---|---|
| Block pickup | Soft "kchok" |
| Block snap (valid) | "tock" |
| Block snap (invalid) | "thud" + buzz |
| Level complete | 3-note ascending chime |
| Hint used | "shimmer" |
| Button tap | Minimal click |

- All toggleable in Settings
- Defaults: SFX ON, Music OFF

### Haptics (iOS)
| Event | Type |
|---|---|
| Block pickup | Light impact |
| Block snap valid | Light impact |
| Block snap invalid | Medium impact + warning notification |
| Level complete | Success notification |
| Hint reveal | Soft impact |

---

## 9. Technical Architecture

### Stack
- **Language:** Swift 5.9+
- **UI:** SwiftUI (iOS 17+)
- **Animation:** SwiftUI native springs
- **Persistence:** SwiftData (preferred) or Core Data
- **Level data:** Bundle JSON files
- **State:** `@Observable` (iOS 17) or `@StateObject` patterns
- **IAP:** StoreKit 2
- **Analytics:** TelemetryDeck (privacy-first) or Mixpanel
- **Notifications:** `UNUserNotificationCenter`
- **Haptics:** `UIImpactFeedbackGenerator` + `UINotificationFeedbackGenerator`

### Folder structure
```
Snuglo/
├── App/
│   ├── SnugloApp.swift
│   └── AppEnvironment.swift
├── Features/
│   ├── Game/
│   │   ├── GameView.swift
│   │   ├── GridView.swift
│   │   ├── BlockView.swift
│   │   ├── GameViewModel.swift
│   │   └── GameEngine.swift
│   ├── LevelSelect/
│   ├── DailyPuzzle/
│   ├── Settings/
│   ├── Stats/
│   ├── Shop/
│   └── Onboarding/
├── Core/
│   ├── Models/
│   │   ├── Level.swift
│   │   ├── Block.swift
│   │   ├── Grid.swift
│   │   └── Placement.swift
│   ├── Engine/
│   │   ├── SolutionChecker.swift
│   │   ├── LevelLoader.swift
│   │   └── ProceduralGenerator.swift
│   ├── Services/
│   │   ├── PersistenceService.swift
│   │   ├── IAPService.swift
│   │   ├── AnalyticsService.swift
│   │   └── NotificationService.swift
│   └── Theme/
│       ├── Colors.swift
│       ├── Typography.swift
│       └── Spacing.swift
├── Resources/
│   ├── Levels/
│   ├── Sounds/
│   └── Assets.xcassets/
└── Tests/
    ├── EngineTests/
    └── ModelTests/
```

### Core data models
```swift
struct Level: Identifiable, Codable {
    let id: String
    let pack: String
    let name: String
    let grid: GridSize
    let blocks: [Block]
    let solution: [Placement]
    let goldTime: Int   // seconds
    let silverTime: Int
}

struct Block: Identifiable, Codable {
    let id: String
    let width: Int
    let height: Int
    let color: String   // semantic key, theme maps to actual color
    var area: Int { width * height }
}

struct Placement: Codable {
    let blockId: String
    let x: Int
    let y: Int
}

enum GameState {
    case playing
    case dragging(blockId: String)
    case paused
    case solved
}
```

### Solution check (pseudocode)
```
func isComplete(placements, blocks, grid) -> Bool:
    cells = Array2D<Bool>(cols: grid.cols, rows: grid.rows, default: false)
    for p in placements:
        block = blocks[p.blockId]
        for dy in 0..<block.height:
            for dx in 0..<block.width:
                cx, cy = p.x + dx, p.y + dy
                if (cx, cy) out of bounds: return false
                if cells[cy][cx]: return false   // overlap
                cells[cy][cx] = true
    return cells.allSatisfy { $0 }
```

---

## 10. Persistence

### `UserProgress`
- Completed levels: `[levelId: (stars: Int, bestTime: Int, hintsUsed: Int)]`
- Current level pointer
- Hints remaining
- Daily streak (consecutive days)
- Last opened date

### `UserSettings`
- SFX, music, haptics toggles
- Theme (Light/Dark/System)
- Colorblind mode
- Notification time

### `IAPState`
- Purchased SKUs
- Active subscription expiry

> iCloud sync deferred to v1.1.

---

## 11. Monetization

### Strategy (hybrid)
1. **Rewarded ads** (for users without ad-free IAP)
   - "Watch ad for +1 hint"
2. **IAP one-time:**
   - Hint packs ($0.99, $2.99, $4.99)
   - Remove ads ($2.99)
3. **Subscription (Snuglo Plus):**
   - $1.99/mo or $14.99/yr
   - Unlimited hints + ad-free + premium themes
   - 7-day trial

### Launch plan
- **v1.0:** Free + IAP hint packs + rewarded video only (no banners, no interstitials during gameplay)
- **v1.2:** Add subscription

---

## 12. Analytics

### Event taxonomy
| Event | Properties |
|---|---|
| `app_open` | — |
| `onboarding_step_completed` | `step` |
| `level_start` | `levelId`, `pack` |
| `level_complete` | `levelId`, `time`, `stars`, `hintsUsed` |
| `level_quit` | `levelId`, `timeSpent` |
| `hint_used` | `levelId` |
| `iap_initiated` | `productId` |
| `iap_completed` | `productId`, `revenue` |
| `ad_shown` | `placement` |
| `daily_puzzle_played` | `date` |
| `streak_updated` | `newStreak` |
| `settings_changed` | `key`, `value` |

### KPIs
- D1 / D7 / D30 retention
- Avg session length
- Sessions per DAU
- Level completion rate per level
- Avg hint usage per level
- IAP conversion rate
- ARPDAU

---

## 13. Notifications

- Daily reminder at user-selected time: *"Snuglo daily puzzle is ready 🧩"*
- Streak alert: *"You're on a 6-day streak — don't break it!"*
- New pack unlocked: *"New pack unlocked: Crystal Garden"*

All opt-in, controllable from Settings.

---

## 14. Accessibility

- **VoiceOver:** Each block labeled (`"Purple block, 5 cells"`)
- **Dynamic Type:** All text scales
- **Reduce Motion:** Springs replaced with instant snap
- **Color-blind mode:** Pattern overlays on blocks (dots, stripes, hatch)
- **High Contrast:** Stronger borders
- **Minimum touch target:** 44×44pt

---

## 15. Localization

### v1.0 languages
- English (default)
- Turkish
- Spanish

### v1.1
- French, German, Portuguese (BR), Japanese

- All copy via `Localizable.strings`, no hardcoded text
- Pack/level names: optional localized

---

## 16. Onboarding Microcopy

| Screen | Headline | Sub |
|---|---|---|
| 1 | "Welcome to Snuglo" | "A cozy puzzle to fit your day." |
| 2 | "Fill the grid" | "Drag blocks. Cover every cell. No overlap." |
| 3 | "A puzzle a day" | "Get a fresh daily challenge — keep your streak alive." |

---

## 17. App Store Metadata

- **App name:** Snuglo
- **Subtitle (30 char):** "Cozy Block Logic Puzzle"
- **Keywords (100 char):** `puzzle,block,logic,grid,brain,calm,daily,relax,zen,mind,fit,shape,wood,sudoku,shikaku`
- **Promotional Text (170 char):** "Snug, simple, satisfying. Fit colored blocks into the grid and unwind one puzzle at a time. New daily challenge every morning."
- **Description:** TBD (max 4000 char)
- **Screenshots:** 6.7" + 6.5" + 5.5" (5 frames: hero, game, daily, packs, complete)

---

## 18. Roadmap

| Version | Scope |
|---|---|
| **0.1 — Engine** | Data models, `SolutionChecker`, level loader, headless tests |
| **0.2 — Core UI** | Game screen (drag-drop, snap, validation), 5 sample levels |
| **0.3 — Flow** | Onboarding + level select + level complete |
| **0.4 — Content** | 120 levels (4 packs × 30) |
| **0.5 — Polish** | Animation, sound, haptics, settings |
| **0.6 — Daily + Stats** | Daily puzzle (deterministic seed), stats, streak |
| **0.7 — Monetization** | IAP via StoreKit 2 |
| **0.8 — Analytics** | TelemetryDeck integration |
| **0.9 — Localization + A11y** | TR/EN/ES + VoiceOver |
| **1.0 — Launch** | App Store submission |
| **1.1** | Subscription + iCloud sync |
| **1.2** | More packs + theme shop + iPad |

---

## 19. Acceptance Criteria (MVP / v0.5)

- [ ] User can open the app and play the Daily Puzzle
- [ ] At least 30 levels playable, all solutions validated
- [ ] Drag-drop is smooth (60fps), snap is correct
- [ ] Overlap & boundary violation give visual feedback
- [ ] Validation (full grid coverage) triggers Level Complete
- [ ] Star system works (gold / silver / finish)
- [ ] Hint button places one block correctly
- [ ] Pause + Resume works
- [ ] Progress auto-saves; survives app kill
- [ ] Renders correctly on iPhone 14, 15, 16 (notch + home-indicator safe)

---

## 20. Open Questions / Risks

| Question | Decision | Status |
|---|---|---|
| Rotation? | No (MVP) | Resolved |
| Online leaderboard? | No (v1.0) | Resolved |
| iPad support? | v1.1 | Resolved |
| Apple Watch companion? | No | Resolved |
| Procedural vs handcrafted? | Hybrid — first 60 manual, rest procedural | Resolved |
| Unique-solution guarantee? | Yes (procedural needs uniqueness solver) | Open |
| Pre-launch beta? | Yes — TestFlight, 20–50 testers | Resolved |
