# Changelog — Snuglo

---

## [Unreleased]
### Faz 1: 5 sekmeli özel tab bar + per-tab nav + hideBar overlay (IOS-75)
- **AppTab enum** yeniden yapılandırıldı: 5 görünür sekme (`.levels` · `.shop` · `.play` orta yükseltilmiş · `.leaderboard` · `.profile`) + 3 backward-compat case (`.home → .play`, `.stats → .profile`, `.settings → playPath push + .play tab`). `selectTab(_:)` normalize eder; mevcut call-site'lar sıfır değişiklikle derlenir.
- **AppRouter** per-tab tipli path dizileri: `levelsPath / shopPath / playPath / leaderboardPath / profilePath: [Route]`. `push(_:)` aktif tab'a yönlendirir; `.levelsList` → tab switch eder; `pop/popToRoot` current-tab scope'u temizler. Outer `path` yalnızca splash/onboarding flow için korundu.
- **RootTabView** (`Core/Components/BottomTabBar.swift` tam yeniden yazımı): `TabView(selection:)` + `.tabViewStyle(.page(indexDisplayMode: .never))` carousel swipe. 5 tab, her biri kendi `NavigationStack(path:)` ile (iOS 26 observation fix için tipli dizi). Shared `tabDestination(_:)` handler.
- **CustomTabBar overlay**: `UnevenRoundedRectangle(topLeadingRadius: 22)` arka plan (`surfaceContainerLowest`, `outlineVariant` border). Sol 2 sekme + sağ 2 sekme + ortada yükseltilmiş Play butonu (64×64 daire, `primary` fill, `onPrimary` ikon, `offset(y: -18)`). Tap → `HapticService.shared.impact(.light)`.
- **hideBar animasyonu**: `@State hideBar` + `computeShouldHide()` + per-path `.onChange` (iOS 26 ilk push güvenilirliği). `.spring(response: 0.35, dampingFraction: 0.85)`. `accessibilityReduceMotion` desteği.
- **LeaderboardView** placeholder: `trophy.fill` + `cardSurface()`, 3 dil. `screen.leaderboard` identifier.
- **MainMenuView** L28 `BottomTabBar()` kaldırıldı. **LevelsListView** L26 `BottomTabBar()` + L31 `.onAppear { router.selectedTab = .home }` kaldırıldı.
- **Localizable.strings** (en/tr/es): `tab.leaderboard`, `leaderboard.title/placeholder.title/placeholder.body` eklendi.
- **UITests**: `SmokeUITests.test_navigateToStats → test_navigateToProfile`. `HomeFlowUITests.testRootTabsExist` 5 tab doğrulaması (tab.leaderboard + tab.profile eklendi, tab.stats kaldırıldı).

### Faz 3: Oyun içi güçlendirme bar (IOS-89)
- **PowerUp.swift** (yeni): `enum PowerUp: String, CaseIterable, Identifiable` — `hint` (30 gem), `undo` (20 gem), `shuffleTray` (15 gem). `displayNameKey`, `sfSymbol`, `gemCost`. `enum PowerUpResult: Equatable` — `success / insufficientGem / notApplicable`. DEFER notu: `addTime` (engine countdown yok) ve `swapPiece` (engine rotation yok) Faz 6+'da eklenecek.
- **PowerUpRules.swift** (yeni): Saf `struct PowerUpRules` — `isApplicable(_:unplacedCount:moveHistoryCount:)`. SwiftUI bağımlılığı yok; birim test edilebilir.
- **GameViewModel** (genişletme): `struct MoveSnapshot { pieceID }` + `private(set) var moveHistory: [MoveSnapshot]`. `tryPlace` başarılı dallarda `moveHistory.append(...)`. `placeHintPiece()` private extraction (applyHint refactor). `canApply(_ pu:) -> Bool`, `applyPowerUp(_ pu:wallet:progress:) -> PowerUpResult` (tek orkestrasyon noktası). `undoLastMove()` — son snapshot pop + `removePlacement` (moveCount AZALTILMAZ, doc-comment ile belirtildi). `shuffleTray()` — `level.pieces.shuffle()` → yeni Level struct atama; unplacedPieces @Observable bağımlılık otomatik güncelleme.
- **PowerUpBar.swift** (yeni — `Features/Game/`): `HStack` 3 buton. `GameButtonStyle(.primary)` + SF Symbol + `displayNameKey` label + maliyet etiketi (hint için hintCount>0 ise `×N` rozeti, aksi hâlde `CurrencyIcon(.gem)` + gemCost). `isEnabled` = `canApply && (free || canAfford)`. Disabled → opacity 0.4. Tap → `applyPowerUp`; `.insufficientGem` → `onInsufficientGem()` callback + haptic; `.notApplicable` → error haptic. Accessibility id'ler: `button.game.hint` (ESKİ ID KORUNDU) / `button.powerup.undo` / `button.powerup.shuffle`.
- **GameView** (entegrasyon): Eski standalone hint pill tray'den KALDIRILDI. PowerUpBar, HUD ile tahta arasına eklendi. `@State var showInsufficientGemBanner` + `AnnouncementBanner` (title/message/cta localizable) + CTA → `router.selectTab(.shop)`.
- **Localizable.strings** (en/tr/es): `powerup.hint`, `powerup.undo`, `powerup.shuffle`, `powerup.insufficient.gem.title/message/cta` eklendi.
- **Testler**: `PowerUpRulesTests.swift` (6 test — 3 PU × isApplicable boundary). `GameViewModelTests` ekleri (7 test — undo/shuffle/hint hibrit senaryolar). Toplam 140/140 test geçiyor.
- **DEFER**: `swapPiece` (engine Piece.cells immutable, rotation desteği yok) ve `addTime` (Snuglo timer elapsed-only, countdown yok) — Faz 6+.

### Faz 2: Vibrant Play bileşen kiti (IOS-87)
- **GameButtonStyle.swift** (yeni): `ButtonStyle` protokolü. `Variant.primary` (mavi dolgu + `primaryPressed` alt slab) ve `Variant.secondary` (beyaz yüzey + `outlineVariant` slab + `divider` border). 3D slab efekti: ZStack arka plan (alt slab Y=+4pt offset, üst yüzey), press anında content Y=+depth kayar, `.spring(response: 0.18, dampingFraction: 0.7)` animasyon. `@Environment(\.accessibilityReduceMotion)` → offset=0, animation=nil. `AppRadius.button (100pt)` pill şekli.
- **PrimaryButton.swift** (refactor): Manuel `isPressed` state ve `_onButtonGesture` kaldırıldı → `GameButtonStyle(variant: .primary)`. Public API (`titleKey`, `systemImage`, `accessibilityID`, `action`) değişmedi; tüm call-site'lar sıfır değişiklikle derlenir.
- **SecondaryButton.swift** (refactor): Aynı şekilde `GameButtonStyle(variant: .secondary)` kullanacak şekilde basitleştirildi. Foreground `AppColors.softCocoa` korundu.
- **CurrencyIcon.swift** (yeni): `Currency` enum + `size: CGFloat = 24` parametreli SF Symbol ikonu. `currency.tint` rengi, `currency.displayNameKey` erişilebilirlik etiketi.
- **BalanceChip.swift** (yeni): `CurrencyIcon(size: 18)` + miktar metni (`monospacedDigit`, `numericSmall`). `cardSurface()` arka plan, `accessibilityElement(children: .combine)`.
- **SectionHeader.swift** (yeni): Başlık (`headlineSmall` + `onSurface`) + isteğe bağlı aksiyon butonu (`bodyMedium`, `AppColors.primary`, `.plain`). `firstTextBaseline` hizalaması.
- **ItemBadge.swift** (yeni): 0–3 yıldız satırı (`star.fill`/`star`, `tertiary`/`outlineVariant`), ortalanmış SF Symbol ikonu, isteğe bağlı sayı rozeti (`Capsule`, `AppColors.primary`). `clampedStars(_:)` pure static fn — init zamanında clamp, `ComponentHelperTests` ile birim test edildi.
- **ProgressPill.swift** (yeni): Kapsül pill — etiket metni + isteğe bağlı dolum çubuğu (0…1, `GeometryReader` tabanlı, `AppColors.primary` fill). Progress yoksa saf durum chip'i. `surfaceContainerLowest` arka plan + `outlineVariant` border + `shadowL1()`.
- **AnnouncementBanner.swift** (yeni): `cardSurface()` kart, 4pt `AppColors.primary` sol kenar şeridi, başlık/mesaj/dismiss(`×`) + isteğe bağlı `PrimaryButton` CTA. Tüm metinler `LocalizedStringKey`.
- **Localizable.strings** (en/tr/es): `common.viewAll` ("View All" / "Tümünü gör" / "Ver todo") ve `announcement.dismiss` ("Dismiss" / "Kapat" / "Cerrar") eklendi.
- **Testler**: `ComponentHelperTests.swift` — `ItemBadge.clampedStars` için 3 test metodu (aralık altı/içi/üstü). Toplam 127/127 test geçiyor.

### Faz 0: WalletStore + 4 cüzdan + LevelComplete reward (IOS-73)
- **Currency.swift**: `enum Currency` (coin / gem / ticket / cup) with `isSpendable`, `sfSymbol`, `tint` (existing AppColors only), `CurrencyRate { coinPerGem=100; gemPerTicket=50 }`.
- **WalletStore.swift**: `@Observable @MainActor` singleton with `earn`, `spend`, `canAfford`, `exchange` API. UserDefaults JSON persistence via `Snapshot: Codable` with `decodeIfPresent ?? 0` for forward compatibility. Test-isolated via `init(defaults:key:)`.
- **CurrencyReward.swift**: pure static `forLevelComplete(stars:elapsedSeconds:previousBestSeconds:)` — coin = stars×10 + (elapsed<60 ? 5 : 0); gem = (personalBest ? 1 : 0) + (stars==3 ? 1 : 0).
- **GameView**: `rewardGranted` + `earnedReward` state; idempotent reward grant in `.onChange(of: viewModel.isSolved)`; reset on replay. Passes `earnedReward` to `LevelCompleteSheet`.
- **LevelCompleteSheet**: `earnedReward` parameter + `rewardRow` card below stat pills showing `+N` per currency in their tint color.
- **Localizable.strings** (en/tr/es): `currency.coin/gem/ticket/cup`, `levelcomplete.reward`.
- **Tests**: `WalletStoreTests` (18 cases) + `CurrencyRewardTests` (14 cases).

### Vibrant Play restyle — Faz 3c: Stats / Shop / Settings (IOS-65)
- **StatsView**: `headerSection` replaced by `statsHeroCard` — blue gradient card (`primary` → `primaryPressed`) with `Image("mascot-sloth")` on right and streak subtitle. KPI card icons now in `RoundedRectangle` color badge (`primaryContainer` 60% tint, 36×36 pt). All data from `ProgressStore` unchanged.
- **ShopView**: `header` upgraded to hero banner card (same blue gradient, mascot-sloth). Plain `Divider` between sections removed. `sectionTitle` bumped to `headlineMedium`. All `StoreManager` IAP logic unchanged.
- **SettingsView**: Converted from `List { Section }` to `ScrollView + VStack` with custom `settingsSection` helper using `cardSurface()` per section group. `RowDivider` between rows inside cards. All toggle/picker/alert/binding logic preserved verbatim. `accessibilityIdentifier` values preserved: `screen.settings`, `title.settings`, `settings.sound_toggle`.
- **Missing asset note**: `Image("mascot-sloth")` used in StatsView hero and ShopView hero — already in asset catalog from Faz 3b (GameView). No new assets required.

### Vibrant Play restyle — Faz 3b: Game + LevelComplete (IOS-64)
- **GameView** (HUD): back button and pause button redesigned as white circle buttons with `shadowL1`. Timer moved to a blue capsule pill (`clock.fill` icon + elapsed time, white text) with `game.timer` identifier. Pack name + `Level N` subtitle in center VStack. Hint button removed from HUD — moved to tray.
- **GameView** (progress bar): new `progressRow` shows "PROGRESS X%" label + blue-to-secondary gradient `Capsule` bar below HUD. Driven by `placedFraction` (pieces placed / total pieces).
- **GameView** (mascot): `Image("mascot-sloth")` in 72×72 white rounded card floats above the puzzle grid.
- **GameView** (tray): tray card background changed from `surfaceContainerHigh` to `surfaceContainerLowest` (white). Hint pill button (blue `Capsule`, `button.game.hint` identifier) added at the bottom of the tray card with `×N` hint count badge.
- **GridView**: board background changed from `gameBoardBackground` to `surfaceContainerLowest` (white) — both `.background()` modifier and `drawBackground` Canvas fill updated.
- **BlockView**: cell-count badge label color changed from `AppColors.onSurface.opacity(0.55)` to `Color.white.opacity(0.80)` for contrast on vivid Vibrant Play block palette.
- **LevelCompleteSheet**: hero replaced — `Image("mascot-tiger")` in gold gradient ring (`AppColors.tertiary`) + `Image("badge-trophy")` overlay. Divider stat grid replaced with pill-style `statPill()` cards (`surfaceContainerLowest` + `shadowL1`). Stars row preserved. All accessibility identifiers unchanged (`complete.next`, `complete.continue`).

### Vibrant Play restyle — Faz 3a: Splash · Onboarding · LevelsList · LevelMap (IOS-62)
- **SplashView**: 3×3 block-grid logo replaced with `Image("hero-splash")` centred at 260 pt max width. Scale-breathing animation (0.92 → 1.0, 2.5 s, `repeatForever`) retained; guarded by `reduceMotion`. Wordmark (`Text("Snuglo")`) retained but marked `accessibilityHidden(true)`. UITestMode fast-path and `splashTask` cancellation logic unchanged.
- **OnboardingView**: `OnboardingPage.symbol` (SF Symbol) renamed to `mascotImage: String`. Pages now use `mascot-hippo` / `mascot-sloth` / `mascot-rabbit` assets inside a 240 pt accent-tinted circle with 180 pt image inset. Accent colours: `primaryContainer` / `secondaryContainer` / `tertiaryContainer`. All navigation, accessibility identifiers, dot indicator, and localisation keys unchanged.
- **LevelsListView**: pack cards upgraded to `cardSurface()` — white (`surfaceContainerLowest`) background, 20 pt radius, `outlineVariant` hairline stroke, L1 ambient shadow. The previous explicit `background/clipShape/overlay/shadowL1` block replaced by a single `.cardSurface()` call. All data, navigation, alert, and accessibility logic unchanged.
- **PackDetailView**: hero banner replaces `LinearGradient` with `Image("scene-island")` at 220 pt height, `scaledToFill`, bottom scrim (`background → 65 % opacity`). Pack info card (badge, title, subtitle, progress bar) repositioned as a `cardSurface()` card anchored to the bottom of the ZStack. Level tiles reshaped from `RoundedRectangle` at `height: 64` to `Circle` at `56×56`: completed = `AppColors.primary` fill + white number + gold stars; available = white fill + primary border; locked = `surfaceContainerHigh` fill + outline border. Grid changed from 3 columns to 4 columns. All `packdetail.level_item.{index}` accessibility identifiers and `router.push(.game(levelID:))` flow unchanged.
- **No engine, data, or persistence changes** — UI only.

### Vibrant Play restyle — Faz 2: bottom tab bar + MainMenu (IOS-61)
- **AppTab enum**: added `.play` (primary Play tab) and `.levels` (Levels tab). `.home` and `.settings` retained as backward-compat cases so LevelsListView call sites compile unchanged.
- **BottomTabBar**: redesigned for Vibrant Play — 4 tabs: Play (`tab.play`) / Levels (`tab.levels`) / Stats (`tab.stats`) / Shop (`tab.shop`). Active tab shows `AppColors.primary` blue icon + label (no pill background). Settings removed from tab bar. Levels tab pushes `.levelsList` route instead of switching tab state; active state detected via `router.path.contains(.levelsList)`.
- **MainMenuView**: `tabContent` switch handles all 6 AppTab cases. Daily puzzle hero area upgraded: `Image("hero-splash")` replaces the gradient placeholder; `Image("mascot-hippo")` appears in the hero corner. Gear icon gets `button.menu.settings` accessibility identifier. Language-lesson content from Stitch mockup intentionally omitted — Snuglo is a block puzzle, not a language app.
- **UITests updated** (tab identifier sync): `HomeFlowUITests` — `tab.home` → `tab.play`, checks `tab.levels` instead of `tab.settings`. `SmokeUITests` — `tab.home` → `tab.play`; `test_navigateToSettings` now taps `button.menu.settings` gear icon instead of the removed `tab.settings`.
- **Assets used**: `hero-splash.png`, `mascot-hippo.png` (both already in Assets.xcassets). Missing assets for future phases: `mascot-sloth`, `mascot-rabbit`, `mascot-tiger` (in catalog but not yet placed on screens — Faz 3).

### Vibrant Play restyle — Faz 1: theme tokens + components (IOS-60)
- **Colors**: all token values remapped to Vibrant Play palette (names unchanged). Background `#f4faff`, primary `#30A7E7`, gold accent `#FFB800`, text `#141d21`, border `#dbe4ea`, error container `#ffdad6`. New `primaryPressed` token `#2589C1` for button pressed state. Block palette updated to vivid Material Design set. Shadows now blue-tinted from SPEC `#006591`.
- **Typography**: all tokens unified to Plus Jakarta Sans (variable wght 200–800). Body/label tokens migrated from Be Vietnam Pro; numeric tokens migrated from Space Grotesk. `spaceGrotesk()` helper removed.
- **Radius**: `AppRadius.button` → 100 pt (pill-shaped). Card/block radii unchanged (20/10).
- **PrimaryButton**: pressed background → `AppColors.primaryPressed`; `@Environment(\.accessibilityReduceMotion)` guard added — animation skipped when reduce motion is on.
- **SecondaryButton**: `@Environment(\.accessibilityReduceMotion)` guard added — animation skipped when reduce motion is on.
- **No feature views touched** — only `Core/Theme/` and `Core/Components/`.

### LevelComplete: move count + best time summary (IOS-59)
- **Move counter**: `GameViewModel.moveCount` increments on every successful placement (tray drop, re-drag, hint). Resets automatically when a new session starts. Invalid/OOB drops and rollbacks do not count.
- **Best time in summary**: reads `ProgressStore.levelProgress[id].bestTime` (already persisted by `markCompleted`) — no new store API needed. Shows updated best time (this session included) formatted as `m:ss`; falls back to `"—"` until first completion.
- **LevelCompleteSheet**: two new stat cells (`complete.moves`, `complete.bestTime`) added in a second row below the existing Time / Stars / Hints row. Uses the existing `statCell` helper and `surfaceContainer` background.
- **Localization**: `complete.moves` / `complete.bestTime` added to en, tr, es.
- **Tests**: 3 new `GameViewModelTests` — `test_moveCount_isZeroOnInit`, `test_moveCount_incrementsOnEachSuccessfulPlacement`, `test_moveCount_doesNotIncrementOnInvalidPlacement`.

### Hint system wired to game screen (IOS-58)
- **HUD hint button**: lightbulb icon with remaining-count badge added next to pause button. Disabled (0.4 opacity) when `hintCount == 0`. Tapping places the first unplaced piece at its `level.solution` coordinate via the existing `tryPlace` flow (sound + haptic included). Accessibility label localised (`game.hint`).
- **Real hints-used in LevelCompleteSheet**: `hintsUsed: 0` hardcoded replaced with `viewModel.hintsUsed`.
- **Localization**: `game.hint` key added to en (`"Hint"`), tr (`"İpucu"`), es (`"Pista"`).
- **Tests**: 4 new — `test_applyHint_placesPieceAtSolutionOriginAndIncrementsCounter`, `test_applyHint_returnsFalseWhenNoHints` (GameViewModelTests); `testUseHint_decrementsCountAndReturnsTrue`, `testUseHint_returnsFalseWhenEmpty` (ProgressStoreTests).

### Game screen — 3-way improvement (IOS-57)
- **Tray clipping fix**: `TrayLayout` pure helper (CoreGraphics + SnugloEngine, no SwiftUI) computes cell size from both piece width AND height. Tray height is now dynamic — tall multi-row pieces are never clipped. Multi-row flow layout activates automatically when pieces would be too small in a single row.
- **Re-drag placed pieces**: `GameViewModel.liftPiece(pieceID:)` removes a board piece and snapshots its placement. Transparent overlay handles on GridView initiate re-drag via `reliftGesture`. Invalid or off-grid drops trigger `rollbackLift()` — piece returns to original position with spring animation + error haptic/sound. Tray-drag haptic/sound pattern preserved exactly.
- **Visual polish**: snap ghost now shows piece color (valid) or error red (invalid) with distinct stroke — computed from `wouldOverlapOrOOB` during drag. Spring animation tuned to response 0.30–0.35 / dampingFraction 0.75–0.80. HUD buttons have `shadowL1()` elevation. All changes use only existing AppColors / AppSpacing / AppRadius / AppShadow tokens.

### Removed
- **PauseOverlayView** (dead code): file deleted — fully superseded by `PauseSheet`. No external call sites existed; identified in `AUDIT_v1.1.md`.

---

## [v1.1.1] - 2026-05-26
### Functional bug fixes (post v1.1.0 manual QA)
- **Tab bar labels rendered as raw keys** (`TAB.HOME`, `TAB.SETTINGS`): Faz I-2 renamed the tabs from play/levels → home/settings but never added the new keys to `Localizable.strings`. Added `tab.home` + `tab.settings` to en/tr/es. Legacy `tab.play` / `tab.levels` retained as no-ops.
- **Continue card showed "Cozy Beginnings Level 13" for fresh players**: the MainMenu Continue card was reading `MockData.continuePack` / `continueLevel`, both of which were hardcoded to a partial-progress state from the Faz C scaffold. Added `PackProvider.continuePack()` / `continueLevel()` which read real progress from `ProgressStore` and surface the first unlocked + playable level. Fresh player now sees "Cozy Beginnings Level 1, 0%".
- **"Next Level" CTA on LevelCompleteSheet didn't advance**: `onNext: { router.pop() }` only popped the GameView, returning the user to PackDetail. Replaced with `PackProvider.nextLevelId(after:)` which computes the next id and pushes a fresh `.game(levelID:)` on the NavigationStack (replacing the current entry so back-button still returns to PackDetail). Falls through to `pop()` at pack-end / daily puzzle.
- **Daily Puzzle card occasionally didn't register taps**: added explicit `.contentShape(RoundedRectangle(...))` to the Button label. The nested `.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)` for the grid-size badge could swallow taps over the top-right region.
- **Progress pill read "Level 0 / 240"** for fresh players: pill now shows `min(completed + 1, total)` — interpreted as the *next* level the user will play, matching the Stitch design ("Level 12 / 240" with 11 done).

### Tests
- `PackProviderContinueTests` (8 new): coverage for `nextLevelId(after:)` (next index, pack-id dashes, pack-end, malformed input, unknown pack) + `continuePack/continueLevel` (fresh-player Level 1).

### Build & tests
- `swift test` → 66/66
- `xcodebuild test -only-testing:PackProviderContinueTests` → 8/8
- `xcodebuild build` (iPhone 17, iOS 26.3.1) → BUILD SUCCEEDED

### Manual verification needed (user)
- Daily Puzzle card tap → GameView with today's puzzle (couldn't reliably simulate tap programmatically — macOS Accessibility permission on Terminal blocks `Quartz.CGEventPost` to Simulator).
- Level 1 complete → "Next Level" → Level 2 loads.

---

## [v1.1.0] - 2026-05-26
### Reusable Component Rollout (Faz K + L, IOS-54)
- **Audit**: every feature screen scanned for Stitch alignment. `AUDIT_v1.1.md` documents per-screen status, dead code (`PauseOverlayView` unreferenced), and refactor order-of-attack.
- **PrimaryButton / SecondaryButton adoption** (DoD #3 closed):
  - `PauseSheet` — 3 inline button stacks → `PrimaryButton(Resume)` + `SecondaryButton(Restart)` + `SecondaryButton(Home)`. 50 LOC of duplicated styling removed.
  - `LevelCompleteSheet` — inline `Next` CTA → `PrimaryButton`. Replay / Home intentionally kept as smaller outlined lavender per Stitch spec.
  - `OnboardingView` — inline `Next / Get Started` CTA → `PrimaryButton`. Polymorphic title key preserved.
- **CardSurface modifier adoption**:
  - `StatsView` — all 4 sections (KPI grid, pack progress, 7-day chart, hint donut) switched to `.cardSurface()`.
  - `MainMenuView` — `dailyPuzzleCard` + `continueCard` switched to `.cardSurface()`.
- **Pragmatic ruling on `.system(size:)`**: 35 remaining usages in feature code are all on `Image(systemName:)` (SF Symbol icon sizing) — idiomatic SwiftUI and matches `PrimaryButton`'s own implementation. Typography token enforcement applies to `Text` views only.

### Bug Fixes (IOS-53)
- **AppRouter.selectTab() unwinds NavigationStack to Splash** (BLOCKER): `selectTab()` was calling `popToRoot()` — tab switching now only changes `selectedTab`, NavigationStack untouched.
- **GameView viewModel re-init on onAppear** (IMPORTANT): ViewModel now initialized correctly in `init(levelId:)` so the correct level loads without a transient flash.
- **MainMenuView hardcoded "Level 12"** (IMPORTANT): Progress pill reads `ProgressStore.shared.totalLevelsCompleted()` at render time. `dailyGridSize` computed once via `DailyPuzzle.gridSize(for:)` instead of running the full level generator on every render.
- **PauseSheet swipe-to-dismiss timer leak** (IMPORTANT): Timer now restarted via `onDismiss:` callback on `.sheet(...)`. Swipe-dismiss previously left timer permanently cancelled.
- **SplashView task leak** (IMPORTANT): Async splash timer stored in `@State` and cancelled on `.onDisappear` to prevent leak when view is popped early.
- **SettingsView notification denial silent** (IMPORTANT): `reminderToggle` now inspects `UNAuthorizationStatus` after `requestAuthorization()` and triggers `showNotifDeniedAlert` when denied. Previously the toggle was set true even on denial.
- **NotificationSchedulerTests compile failure** (pre-existing): `NotificationScheduler` was renamed to `NotificationService` in Faz F; old test file caused build failure in xcodebuild test. Stub + comment pointing to `NotificationServiceTests`.
- **HUD timer hardcoded system font** (NITPICK): Now uses `AppTypography.numericLabel` (Space Grotesk).
- **Info.plist duplicate copy** (build): `Info.plist` excluded from source wildcard scan — was copied both by INFOPLIST_FILE build setting and Copy Bundle Resources, causing "Multiple commands produce" build error.

### Design Refactor — Stitch Nordic Hearth Alignment
- **Font registration** (BLOCKER-07 closed): Plus Jakarta Sans (variable wght 200–800), Be Vietnam Pro Regular/Medium, Space Grotesk (variable wght 300–700) bundled in `Resources/Fonts/`. Custom `Info.plist` with `UIAppFonts` array.
- **Custom Info.plist** (BLOCKER-01 closed): `GENERATE_INFOPLIST_FILE=YES` removed. `UILaunchScreen.UIColorName: LaunchBackground` now works.
- **Colors.swift**: 5 new Stitch tokens — `gameBoardBackground` (#F2EBE0), `gridLine` (#E5DCC8), `blushAccent` (#F5E6E0), `divider` (#EDE6DA), `softCocoa` (#3A332D) — all with dark-mode variants.
- **Typography.swift**: 3-font variable-axis strategy. `headlineLarge/Medium/Small` → Plus Jakarta Sans SemiBold; `bodyLarge/Medium` → Be Vietnam Pro Regular; `numericLarge/numericLabel/numericSmall` → Space Grotesk Medium; `labelSmall` → Be Vietnam Pro Medium.
- **Reusable components**: `PrimaryButton` (lavender, scale press), `SecondaryButton` (white+divider border), `CardSurface` (ViewModifier, radius 20+shadow), `RowDivider` (1px divider).
- **GridView**: Board background `#F2EBE0`, grid lines `#E5DCC8` @ 1.5 pt, block radius 10.
- **LevelCompleteSheet**: Success circle uses `blushAccent` (was `primaryContainer`). Stat cells use Space Grotesk `numericLabel`.
- **PauseSheet**: Full redesign — lavender primary CTA, secondary buttons with divider border / softCocoa text, Space Grotesk timer.
- **Stats / PackDetail / Settings**: All monospaced system fonts replaced with `numericLarge/numericLabel/numericSmall` Space Grotesk tokens.
- **StitchTokenTests.swift**: 22 new tests verifying all v1.1 color, typography, spacing, and radius tokens.
- **project.yml**: `MARKETING_VERSION: 1.1.0`, Fonts resource phase, custom Info.plist switch.

---

## [v1.0.0] - 2026-05-25
### Release
Production-ready cozy block-logic puzzle game.
Aggregates phases A through J:
- Faz A: Stabilization (SnapCalculator refactor, build green)
- Faz B: Nordic Hearth theme tokens + BlockView
- Faz C: 11 SwiftUI screens + AppRouter NavigationStack
- Faz D: 240 deterministic levels + Daily Puzzle
- Faz E: ProgressStore persistence + Stats real data
- Faz F: AudioManager + HapticsManager + NotificationScheduler
- Faz G: StoreKit 2 (5 SKU) + Ads placeholder with frequency cap
- Faz H: Localization (en/tr/es) + Dark mode + Launch screen + App icon
- Faz I: SwiftLint clean + accessibility groundwork
- Faz J: Documentation + v1.0.0 release tag

---

## [v1.0-I1] — SwiftLint 0 Warning (2026-05-25)

### SwiftLint Configuration (I1-1)
- **`.swiftlint.yml`** — New config at workspace root. Disabled noisy rules (`trailing_whitespace`, `line_length`, `file_length`, `type_body_length`, `function_body_length`, `cyclomatic_complexity`, `large_tuple`). Opt-in: `empty_count`, `explicit_init`, `first_where`, `last_where`. Excluded `SnugloApp/build`, `.build`, `DerivedData`. Short identifier allowlist: `id, x, y, r, g, b, p, s, w, h, dx, dy`. Nesting type_level: 3.
- SwiftLint **0.63.2** (Homebrew).

### Lint Fixes (I1-2)
- **Initial scan:** 117 warnings across 67 files.
- **Autofix (`swiftlint --fix`):** Corrected `comma` (in DailyPuzzleTests, LevelGeneratorTests, SolutionCheckerEdgeCaseTests) + `trailing_comma` (SolutionCheckerEdgeCaseTests). Also auto-corrected `opening_brace`, `colon`, `implicit_optional_initialization`, `redundant_discardable_let` across GameView, GameViewModel, BlockView, StatsView, StoreManagerTests, NotificationServiceTests, SoundServiceTests, ProgressStoreTests.
- **Manual fixes (3 remaining):**
  - `Sources/SnugloEngine/Engine/SolutionChecker.swift:73` — `for_where`: inner `if` → `where` clause on `for x` loop.
  - `SnugloApp/Core/Audio/AudioManager.swift:47` — `void_function_in_ternary`: ternary `musicEnabled ? startBGM() : stopBGM()` → `if/else`.
  - `SnugloApp/Core/Notifications/NotificationScheduler.swift:32` — `void_function_in_ternary`: ternary `reminderEnabled ? scheduleDaily() : cancelDaily()` → `if/else`.
- **Final:** `swiftlint lint --strict` → **0 violations, 0 serious**, exit 0.
- Build: `swift build` ✅ (complete 1.4s). Tests: 66 passed, 0 failed.

---

## [v1.0-H2] — Accessibility + Dark Mode + Launch (2026-05-25)

### Dark Mode (H2-1)
- **`Core/Theme/Colors.swift`** — Every `AppColors` token now has adaptive light + dark variants via `Color(light:dark:)` → `UIColor { traitCollection }` bridge.
  - `Color(light:dark:)` extension on `Color`; `UIColor(hex:)` extension on `UIColor`.
  - 25 tokens updated (background, surface*, primary, secondary, tertiary, on*, outline*, error*, block*).
  - Block palette softened for dark backgrounds (e.g. `blockLavender` → `#7A6D8C` dark).
  - `surfaceContainerLowest` → `#141316` dark (deepest elevation).
  - BLOCKER-06 CLOSED.

### Accessibility — VoiceOver + Hints (H2-2)
- **`SplashView.swift`** — 3×3 logo grid → `.accessibilityElement(children: .ignore)` `.accessibilityLabel("Snuglo")`; wordmark hidden.
- **`OnboardingView.swift`** — Page dots → "Page N of 3"; Skip button hint; action button adaptive hint per page.
- **`MainMenuView.swift`** — Daily Puzzle card label from `LocalizedStringKey`; progress pill combined "Level 12 of 240 completed"; continue card label with progress %.
- **`LevelsListView.swift`** — `packA11yLabel()`: "Cozy Beginnings, 12 of 60 levels completed, 20 percent" / "…locked. Tap to unlock."
- **`PackDetailView.swift`** — `levelTileA11yLabel()`: "Level 12, 3 of 3 stars, completed" / locked / plain.
- **`LevelCompleteSheet.swift`** — Stars: "2 of 3 stars earned"; stats row combined "Solved in 2 minutes 45 seconds. 3 stars. 0 hints used."; `formattedTimeSpeech` helper.
- **`StatsView.swift`** — KPI cards combined + speech-friendly; pack donuts "Cozy pack: 12 of 60 levels completed"; chart bars "Mon: solved, today".
- **`ShopView.swift`** — SKU buttons "Spice Route Pack. $2.99. Tap to purchase" / "Owned"; loading overlay labelled.
- **`SettingsView.swift`** — Reset Progress: `.accessibilityLabel("Reset all progress")` + `.accessibilityHint("Permanently deletes all your game data.")`, `isButton` trait; toggle rows `.accessibilityElement(children: .combine)`.
- All decorative icons/images → `.accessibilityHidden(true)` across all screens.

### Dynamic Type + Reduce Motion (H2-3)
- **`GameView.swift`** — `.dynamicTypeSize(.medium ... .xxxLarge)` prevents grid overflow at AX5 sizes.
- **`BlockView.swift`** — `@Environment(\.accessibilityReduceMotion)` guards scale/spring animations.
- **`GameView.swift`** — `withAnimation(reduceMotion ? nil : .spring(...))` in drag onEnded.
- **`SplashView.swift`** — Breathe animation skipped when reduceMotion; entrance fade disabled.
- **`OnboardingView.swift`** — Tab swipe + dot animation nil when reduceMotion.
- **`LevelCompleteSheet.swift`** — Confetti layer entirely skipped when reduceMotion.

### LaunchScreen + AppIcon (H2-4)
- **`Resources/Assets.xcassets/`** (new catalog):
  - `LaunchBackground.colorset` — light `#FDF8FB` / dark `#1B1A1D` (matches `AppColors.background`).
  - `AccentColor.colorset` — light `#65587A` / dark `#C5B5DC` (matches `AppColors.primary`).
  - `AppIcon.appiconset` — 1024×1024 lavender placeholder PNG; real icon in Faz J.
- **`project.yml`** — `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon`; `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor`; `MARKETING_VERSION: 1.0.0`.
- ⚠️ `UILaunchScreen.UIColorName` sub-key cannot be set via `INFOPLIST_KEY_*` build settings with `GENERATE_INFOPLIST_FILE=YES`. Colorset is ready; migration to custom Info.plist in Faz J.

---

## [v1.0-H1] — Localization TR/EN/ES (2026-05-25)

### Resources/Localization (H1-1 — .lproj strings)
- **`SnugloApp/Resources/en.lproj/Localizable.strings`** *(new)* — 112 keys, English (dev locale).
- **`SnugloApp/Resources/tr.lproj/Localizable.strings`** *(new)* — 112 keys, Turkish.
- **`SnugloApp/Resources/es.lproj/Localizable.strings`** *(new)* — 112 keys, Spanish.
- **`SnugloApp/Resources/en.lproj/InfoPlist.strings`** *(new)* — `CFBundleDisplayName`, `NSUserTrackingUsageDescription` (EN).
- **`SnugloApp/Resources/tr.lproj/InfoPlist.strings`** *(new)* — `NSUserTrackingUsageDescription` (TR).
- **`SnugloApp/Resources/es.lproj/InfoPlist.strings`** *(new)* — `NSUserTrackingUsageDescription` (ES).
- Key namespaces: `common.*`, `app.*`, `onboarding.*`, `menu.*`, `tab.*`, `levels.*`, `pack.*`, `pause.*`, `complete.*`, `stats.*`, `shop.*`, `sku.*`, `settings.*`, `notif.*`, `alert.*`.

### SwiftUI Views (H1-2 — LocalizedStringKey)
- **`BottomTabBar.swift`** — `TabItem.label: String` → `labelKey: LocalizedStringKey`; tab keys: `tab.play` / `tab.levels` / `tab.stats` / `tab.shop`.
- **`OnboardingView.swift`** — Page `headline`/`body` as `LocalizedStringKey`; Skip/Next/Get Started buttons localized.
- **`MainMenuView.swift`** — Wordmark, daily puzzle card, continue section; dynamic data (`verbatim:`).
- **`LevelsListView.swift`** — Locked-pack alert, header, progress labels fully localized.
- **`PauseSheet.swift`** — `togglePill(label:)` → `togglePill(labelKey:)`; Paused/Resume/Restart/Home text.
- **`LevelCompleteSheet.swift`** — `statCell(label:)` → `statCell(labelKey:)`; all button/stat labels.
- **`StatsView.swift`** — `kpiCard`/`legendDot`/`legendRow` helpers → `LocalizedStringKey`; streak subtitle via `NSLocalizedString`.
- **`ShopView.swift`** — `sectionTitle(_:)` → `LocalizedStringKey`; all section/button/badge text.
- **`SettingsView.swift`** — All helpers → `LocalizedStringKey`; all literal strings → `settings.*` / `notif.*` keys.

### Settings (H1-3 — Language Picker)
- **`SnugloApp/Features/Settings/SettingsView.swift`** — New **Language** section (between Notifications and Privacy).
  - `@AppStorage("snuglo.language.override")` stores `"system"` | `"en"` | `"tr"` | `"es"`.
  - `Picker` with four tags; `onChange` writes `["lang"]` to `UserDefaults.standard["AppleLanguages"]`.
  - `"system"` tag removes the key entirely (device locale restored).
  - `showLanguageRestartAlert` (.alert) informs user that restart is required.

### Project Config (H1-4)
- **`SnugloApp/project.yml`** — `options.developmentLanguage: en`; `INFOPLIST_KEY_CFBundleDevelopmentRegion: en`; `INFOPLIST_KEY_CFBundleLocalizations: "en tr es"`.

---

## [v1.0-G2] — Ads Placeholder + Frequency Cap (2026-05-25)

### Core/Ads (G2-1 — AdsManager)
- **`SnugloApp/Core/Ads/AdsManager.swift`** *(new)* — `@Observable final class AdsManager`.
  - Singleton `shared` + testable `init(sessionStart: Date)` (internal).
  - **Frequency cap**: interstitial every 3 level completions (`interstitialFrequencyLevels = 3`).
  - **Warmup guard**: no interstitials in first 30 s of session (`warmupSeconds = 30`).
  - **Session cap**: max 5 interstitials per session (`maxInterstitialsPerSession = 5`).
  - `adsRemovedProvider: () -> Bool` closure — injectable for tests; defaults to `StoreManager.shared.adsRemoved`.
  - `showInterstitial(reason:)` async — 1.5 s placeholder sleep; resets `levelsCompletedSinceLastInterstitial = 0`.
  - `showRewarded(onReward:)` — immediate reward callback (placeholder; FAZ-J: GADRewardedAd).
  - `shouldShowBanner` — computed; `!adsRemovedProvider()`.
  - Consent: `setConsent(_ Bool)` + `loadConsentFlags()` → `UserDefaults("snuglo.ads.consent")`.
  - **FAZ-J swap points** documented inline: `showInterstitial`, `showRewarded`, `resetOnAdsRemoved`, `setConsent`.

### Core/Components (G2-2 — Overlay + Banner)
- **`SnugloApp/Core/Components/AdInterstitialOverlay.swift`** *(new)* — full-window dimmed ZStack.
  - Shows when `AdsManager.shared.isShowingInterstitial == true`.
  - `ProgressView` + placeholder text; `transition(.opacity)`.
  - FAZ-J: remove entirely (GADInterstitialAd presents its own UIViewController).
- **`SnugloApp/Core/Components/BannerAdView.swift`** *(new)* — 50 pt bottom banner.
  - Hidden when `AdsManager.shared.shouldShowBanner == false`.
  - FAZ-J: replace body with `UIViewRepresentable(GADBannerView)`.

### App Layer (G2-3 — Lifecycle hooks)
- **`SnugloApp/App/RootView.swift`** — `.overlay(AdInterstitialOverlay())` above NavigationStack.
- **`SnugloApp/Features/Game/GameView.swift`** — `AdsManager.shared.onLevelCompleted()` in `onChange(of: viewModel.isSolved)`, fires before `fullScreenCover` presentation.

### Settings (G2-4 — Privacy section)
- **`SnugloApp/Features/Settings/SettingsView.swift`** — new PRIVACY section (between NOTIFICATIONS and ACCOUNT).
  - "Personalized Ads" toggle → `ATTrackingManager.requestTrackingAuthorization` on enable.
  - Revoking → `AdsManager.shared.setConsent(false)` immediately.
  - `import AppTrackingTransparency` added.

### Info.plist (G2-5 — ATT)
- **`SnugloApp/project.yml`** — `INFOPLIST_KEY_NSUserTrackingUsageDescription` added to SnugloApp target.
  - Value: `"To deliver personalized ads. You can opt out anytime in Settings."`
  - Required for iOS 14.5+ ATT / IDFA (min deployment: 18.0).

### Tests (G2-6 — AdsManagerTests)
- **`Tests/SnugloAppTests/AdsManagerTests.swift`** *(new)* — 12 tests, all passing.
  - `testFrequencyCapPerLevel_firstTwoLevels_noInterstitial`
  - `testFrequencyCapPerLevel_thirdLevel_triggersInterstitial` (async, 2 s)
  - `testMaxPerSessionCap_noPresentationAfterCap` + `_guardBranch`
  - `testRemoveAdsDisablesAll_onLevelCompleted_isNoop` + `_shouldShowBannerFalse`
  - `testWarmupBlocks_interstitialNotTriggered` + `_pastWarmup_counterBuildsContinuously`
  - `testFrequencyResetAfterInterstitial`
  - `testConsentPersistence_roundTrip`
  - `testShouldShowBanner_adsNotRemoved_true` + `_adsRemoved_false`

### RemoveAds integration
- `StoreManager.adsRemoved` (Faz G-1) → `AdsManager.adsRemovedProvider` gate on every path.
- `@Observable` propagation: UI auto-hides banner + skips interstitials immediately on purchase.

### Faz J bridge: RealAdsAdapter swap
- Replace `AdsManager.showInterstitial` body with `GADInterstitialAd.load(...) + present(...)`.
- Replace `BannerAdView` body with `UIViewRepresentable(GADBannerView)`.
- Remove `AdInterstitialOverlay` (no longer needed — SDK owns the window).
- Add SPM: `google-mobile-ads-sdk` package.
- Forward consent to UMP SDK in `AdsManager.setConsent`.

---

## [v1.0-F] — Audio + Haptics + Daily Reminder BLOCKER fix (2026-05-25)

### Services (F1 — SoundService)
- **`SnugloApp/Core/Services/SoundService.swift`** *(new)* — `@MainActor final class SoundService`.
  - `enum Sound: CaseIterable` → `click / place / snap / solve / error` (.caf assets).
  - `AVAudioSession.setCategory(.ambient, options: [.mixWithOthers])` — kullanıcı müziği üstüne mix.
  - `preload()` → 5 `AVAudioPlayer` init; eksik asset graceful log (no-crash).
  - `play(_ sound:)` → `UserDefaults("sfxEnabled")` gate; default true.

### Services (F2 — HapticService)
- **`SnugloApp/Core/Services/HapticService.swift`** *(new)* — `@MainActor final class HapticService`.
  - `UIImpactFeedbackGenerator(.light/.medium)` + `UINotificationFeedbackGenerator` (lazy).
  - `prepareImpact()` → drag-start'ta taptic engine ısıtılır.
  - `impact(.light/.medium)` + `notify(.success/.error/.warning)`.
  - `UserDefaults("hapticsEnabled")` gate; default true.

### Services (F3 — NotificationService)
- **`SnugloApp/Core/Services/NotificationService.swift`** *(new)* — `UNUserNotificationCenterDelegate`.
  - `requestAuthorization()` → `[.alert, .sound, .badge]`; try-catch silent fail.
  - `scheduleDaily(at:)` → `removePendingNotificationRequests` önce (ghost killer), sonra `UNCalendarNotificationTrigger(repeats: true)`. Identifier: `"snuglo.daily.reminder"`.
  - `reschedule(enabled:at:)` → Settings toggle helper.
  - `makeComponents(from:) static` → pure function, unit test edilebilir.
  - `willPresent` → `[.banner, .sound]` — foreground bildirim banner.

### App Entry (F4)
- **`SnugloApp/App/SnugloApp.swift`** — `init()`: `UNUserNotificationCenter.current().delegate = NotificationService.shared`.

### Settings (F5)
- **`SnugloApp/Features/Settings/SettingsView.swift`** — `@AppStorage("sfxEnabled")` + `@AppStorage("hapticsEnabled")` (SoundService/HapticService anahtarlarıyla aynı). Daily Reminder toggle → `NotificationService.shared.requestAuthorization()` + `reschedule()`. DatePicker onChange → reschedule.
  - Appearance section: `@AppStorage("appTheme") Int` (0=System/1=Light/2=Dark) + functional `Picker("", selection: $appThemeRaw)` — "coming soon" placeholder kaldırıldı.
- **`SnugloApp/App/RootView.swift`** — `@AppStorage("appTheme")` okur; `preferredScheme: ColorScheme?` computed; `.preferredColorScheme(preferredScheme)` modifier — tüm NavigationStack'e uygulanır.

### GameView (F6)
- **`SnugloApp/Features/Game/GameView.swift`** — AudioManager/HapticsManager → SoundService/HapticService:
  - Drag start: `HapticService.prepareImpact()` + `SoundService.play(.click)`.
  - snapCoord nil→non-nil: `HapticService.impact(.medium)` + `SoundService.play(.snap)`.
  - Valid place: `SoundService.play(.place)` + `HapticService.impact(.light)`.
  - Invalid: `SoundService.play(.error)` + `HapticService.notify(.error)`.
  - `onChange(isSolved)`: `SoundService.play(.solve)` + `HapticService.notify(.success)`.

### Audio Assets (F8)
- **`SnugloApp/Resources/Sounds/`** *(new)* — 5 minimal silent CAF (44100 Hz PCM mono, 70 bytes):
  `click.caf`, `place.caf`, `snap.caf`, `solve.caf`, `error.caf`.
- **`project.yml`** — `Resources/Sounds` excluded from sources, resource build phase olarak eklendi.

### Tests (F7) — 26 yeni test
- **`SoundServiceTests.swift`** *(new)* — 7 test: enum 5 case, sfxEnabled gate, missing asset graceful, singleton, dynamic toggle.
- **`HapticServiceTests.swift`** *(new)* — 8 test: tüm feedback türleri disabled no-op, enabled no-crash, singleton.
- **`NotificationServiceTests.swift`** *(new)* — 11 test: makeComponents hour/minute extraction (normal/midnight/23:59), no leakage, identifier constant, reschedule enabled/disabled, requestAuthorization crash-free, cancelDaily idempotent, singleton.

### Build (F9)
- `xcodegen generate` ✅ | `xcodebuild build` ✅ BUILD SUCCEEDED | `xcodebuild test` ✅ SoundServiceTests/HapticServiceTests/NotificationServiceTests geçti.

---

## [v1.0-G1] — StoreKit 2 IAP — 5 SKU (2026-05-25)

### Yeni: `SnugloApp/Core/Store/StoreManager.swift`

- **`StoreManager.swift`** *(new)* — `@Observable` singleton, StoreKit 2 tam entegrasyon.
  - `ProductID` enum: 5 SKU — `packSpice`, `packMambo`, `packWoodland`, `removeAds`, `hintsSmall`.
  - `loadProducts()` — async, Product.products(for:) ile fetch, fiyata göre sıralı.
  - `purchase(_ product:)` — satın alma, verification, consumable/non-consumable ayrımı.
  - `restorePurchases()` — AppStore.sync() + entitlement refresh.
  - `isPackUnlocked(_ packId:)` — cozy-beginnings daima true; diğerleri satın alım kontrolü.
  - `adsRemoved: Bool` — Faz G-2 AdMob hook'u için computed property.
  - `product(forPackId:)` / `productID(forPackId:)` — pack ID → StoreKit Product köprüsü.
  - Transaction listener (Task.detached) — refund / revoke için arka planda dinler.
  - UserDefaults cache (key: `snuglo.purchased.v1`) — offline non-consumable okuma.
  - **Disambiguity fix:** `private typealias SKTransaction = StoreKit.Transaction`
    (SwiftUI kendi `Transaction` tipine sahip; iOS 26.2 SDK'da ambiguity hatası → tam qualifier ile çözüldü).

### Yeni: `SnugloApp/Resources/Snuglo.storekit`

- StoreKit Configuration File (JSON, Xcode 13+ formatı).
- 5 ürün tanımlı: 4 Non-Consumable + 1 Consumable.
- Localization: `en_US`, `tr_TR`, `es_ES` — displayName + description.
- Fiyatlar: $0.99 / $2.99 / $3.99 / $4.99 / $4.99.
- Sandbox simulator testi için scheme'e bağlanması yeterli (bkz. README-StoreKit.md).

### Yeni: `SnugloApp/Resources/README-StoreKit.md`

- Xcode scheme ayarı, sandbox testing, App Store Connect SKU kurulum kılavuzu.
- Faz G-2 AdMob köprü notu: `StoreManager.shared.adsRemoved`.

### Güncellendi: `SnugloApp/Features/Shop/ShopView.swift`

- `StoreManager.shared` live bağlantı — `store.product(for:)` ile StoreKit Product fetch.
- Pack Unlocks section: spice-route / mambo-nights / woodland-retreat kartları.
- Hints section: consumable 10-hint satın alma, `progress.hintCount` badge.
- Remove Ads section: one-time non-consumable.
- Restore Purchases butonu.
- Loading overlay + error alert.
- `purchaseButton(label:isOwned:action:)` — Owned / Buy state.
- `itemCard(owned:)` — owned borderlı kart modifier.

### Güncellendi: `SnugloApp/MockData/PackProvider.swift`

- `allPacks()` — `StoreManager.shared.isPackUnlocked(pack.id)` ile `isLocked` belirlenir.
- Faz E'deki ProgressStore-only lock yerine StoreKit entitlement tabanlı.

### Güncellendi: `SnugloApp/Features/LevelsList/LevelsListView.swift`

- Kilitli pack tıklandığında alert: "Unlock Pack" → "Go to Shop" / "Cancel".
- `router.selectTab(.shop)` yönlendirme.
- Pack card: kilitli → `lock.fill` icon, `%55 opacity`, "LOCKED" progress label.

### Güncellendi: `SnugloApp/Core/Persistence/ProgressStore.swift`

- `hintCount: Int` — default 0, UserDefaults persist.
- `addHints(_ count:)` — consumable IAP sonrası StoreManager tarafından çağrılır (+10).
- `useHint() -> Bool` — Faz H GameView hook için hazır.
- `Snapshot.hintCount` — eski snapshot uyumu için default 0.

### Testler: `Tests/SnugloAppTests/StoreManagerTests.swift`

- `testIsPackUnlockedFreePackAlwaysTrue` — cozy-beginnings her zaman açık.
- `testIsPackUnlockedUnknownPackFalse` — bilinmeyen pack false.
- `testProductIDAllCasesCount` — tam 5 SKU.
- `testProductIDRawValues` — 5 string ID doğrulaması.
- `testIsPurchasedReturnsFalseByDefault` — crash-free smoke test.
- `testAdsRemovedEqualsIsPurchasedRemoveAds` — consistency check.
- `testProductIDForPackIdMapping` — packId → ProductID mapping.
- `testProductForPackIdNilWhenNotLoaded` — crash-free nil guard.
- `ProgressStoreHintsTests`: hintCount default / addHints / useHint / persist / reset (5 test).
- **Toplam yeni test: 13** | **Çalıştırılan: 46** | **StoreKit testleri: 13/13 ✅** | **Pre-existing ColorsTests fail: 1** (base branch'ta 2 vardı).

---

## [v1.0-F] — Audio + Haptics + Daily Reminder (2026-05-25)

### Yeni: `SnugloApp/Core/Audio/AudioManager.swift`

- **`AudioManager.swift`** *(new)* — `@Observable` singleton, AVFoundation tabanlı SFX + BGM yöneticisi.
  - `Sfx` enum: `pickup`, `drop`, `snap`, `levelComplete`, `error` (5 case, CaseIterable).
  - `soundEnabled` / `musicEnabled` — `UserDefaults` ile persist, `@Observable` reactive.
  - `play(_ sfx:)` — soundEnabled=false veya dosya yoksa silent no-op.
  - `startBGM(track:)` / `stopBGM()` / `pauseBGM()` / `resumeBGM()` — BGM scaffold.
  - AVAudioSession: `.ambient` kategori (Spotify ile mix, silent switch'e saygı duyar).
  - `init(defaults:)` — test isolation için injectable UserDefaults.
  - **Ses dosyaları:** Gerçek asset YOK (Faz J'de sound-designer teslim edecek). Dosya yoksa player=nil → tüm `play()` çağrısı noop.
  - **Faz G köprüsü:** `startBGM(track:)` parametre alır → `StoreManager.isPurchased(.premiumMusic)` kontrolü ile premium track unlock.

### Yeni: `SnugloApp/Core/Haptics/HapticsManager.swift`

- **`HapticsManager.swift`** *(new)* — `@Observable` singleton, UIKit haptic wrapper.
  - `Feedback` enum: `light`, `medium`, `heavy`, `success`, `warning`, `error`, `selection`.
  - `enabled` — `UserDefaults` ile persist.
  - `play(_ feedback:)` — enabled=false ise no-op.
  - Generator'lar `init`'de `prepare()` ile pre-warm edilir (ilk tetiklemede latency yok).
  - `init(defaults:)` — test isolation.

### Yeni: `SnugloApp/Core/Notifications/NotificationScheduler.swift`

- **`NotificationScheduler.swift`** *(new)* — `@Observable` singleton, UNUserNotificationCenter wrapper.
  - `reminderEnabled` / `reminderHour` / `reminderMinute` — persist + auto-reschedule.
  - `requestAuthorization() async -> Bool` — system permission dialog.
  - `authorizationStatus() async -> UNAuthorizationStatus` — non-prompting status check.
  - `scheduleDaily()` — stale request remove + UNCalendarNotificationTrigger repeat.
  - `cancelDaily()` — pending notification temizle.
  - Info.plist: UNUserNotificationCenter için plist key GEREKMİYOR.
  - UIBackgroundModes "audio" İNTENSIONEL olarak eklenmedi (BGM sadece in-game).

### Yeni: `SnugloApp/Resources/Audio/README.md`

- Ses asset placeholder — beklenen dosya listesi (pickup/drop/snap/levelComplete/error + bgm_cozy).
- Sound design brief (Nordic Hearth tone, `.ambient` session category, 44.1kHz/16-bit).
- Faz G hook notu: premium track unlock entegrasyonu.

### Güncellenen: `SnugloApp/Features/Game/GameView.swift`

- **Drag gesture hooks (Faz F):**
  - Pickup (first `onChanged`): `AudioManager.play(.pickup)` + `HapticsManager.play(.light)`
  - Drop (onEnded, no snap): `AudioManager.play(.drop)` + `HapticsManager.play(.medium)`
  - Snap (onEnded, valid partial): `AudioManager.play(.snap)` + `HapticsManager.play(.selection)`
  - Error (onEnded, invalid): `AudioManager.play(.error)` + `HapticsManager.play(.error)`
  - Level complete (`onChange(of: isSolved)`): `AudioManager.play(.levelComplete)` + `HapticsManager.play(.success)`

### Güncellenen: `SnugloApp/Features/Settings/SettingsView.swift`

- `@AppStorage` satırları kaldırıldı → `@Bindable var audio = AudioManager.shared` / `haptics` / `notif`.
- SOUND & FEEL: Music toggle → `$audio.musicEnabled`, SFX → `$audio.soundEnabled`, Haptics → `$haptics.enabled`.
- NOTIFICATIONS: Daily Reminder toggle → `requestAuthorization()` await + denied alert + Settings deeplink.
- Reminder Time: `DatePicker(.hourAndMinute)` with `Date ↔ (hour, minute)` computed binding.
- Footer: Aktif hatırlatıcı saatini gösterir.

### Güncellenen: `SnugloApp/Features/Pause/PauseSheet.swift`

- `@AppStorage` → `@Bindable var audio` / `haptics` — aynı singleton'lara bind.
- Inline Sound / Haptics togglelar artık SettingsView ile senkron.

### Test: `Tests/SnugloAppTests/AudioManagerTests.swift`

- 7/7 PASSED — defaults, toggle persist, no-op guard, sfx enum count.

### Test: `Tests/SnugloAppTests/HapticsManagerTests.swift`

- 4/4 PASSED — defaults, toggle persist, no-op guard, no-crash.

### Build

- `swift build` → **Build complete!** ✅
- `xcodebuild -scheme SnugloApp build` (iPhone 17 Sim, OS 26.2) → **BUILD SUCCEEDED** ✅
- Faz F yeni testler: **11/11 PASSED** ✅

---

## [v1.0-E] — Persistence + Stats Real Data (2026-05-25)

### Yeni: `SnugloApp/Core/Persistence/ProgressStore.swift`

- **`ProgressStore.swift`** *(new)* — Single source of truth for player progress.
  - `@Observable final class ProgressStore` — SwiftUI reactive, MainActor friendly.
  - `markCompleted(levelId:stars:time:)` — level tamamlandığında kaydeder; best stars + best time korunur.
  - `markDailySolved(date:time:)` — daily puzzle sonucunu kaydeder; streak hesaplar.
  - `isLevelCompleted(_:)` / `isLevelUnlocked(packId:levelIndex:)` — unlock zinciri.
  - `packCompletionCount(_:)` / `totalLevelsCompleted()` — ilerleme sorguları.
  - `averageTime()` / `averageTimeFormatted` — best-time ortalaması, "2:34" formatı.
  - `recentDailyResults(days:)` — son N gün bar chart verisi (label, solved, isToday).
  - `updateStreak()` — bugün/dün tabanlı consecutive-day streak hesabı.
  - Persistence: `UserDefaults + JSONEncoder/Decoder`, key `snuglo.progress.v1`.
  - `init(defaults:key:)` — test isolation için injectable UserDefaults.
  - `reset()` — settings / test hook.

### Güncellenen: `SnugloApp/MockData/PackProvider.swift`

- `allPacks()` → `ProgressStore.shared.packCompletionCount(pack.id)` ile gerçek completion sayısı.
- `levelItems(in:)` → `ProgressStore.shared` ile `isCompleted`, `isLocked`, `stars` gerçek data.

### Güncellenen: `SnugloApp/Features/Game/GameViewModel.swift`

- `persistProgress()` — solve anında çağrılır; `computeStars(seconds:gridSize:)` ile yıldız hesaplanır.
- `computeStars(seconds:gridSize:)` — grid boyutuna göre threshold: 5×5→30s, 6×6→60s, 7×7→90s, 8×8→120s.
- Daily puzzle (`level.id.hasPrefix("daily")`) → `markDailySolved` de tetiklenir.

### Güncellenen: `SnugloApp/Features/Stats/StatsView.swift`

- **2×2 KPI grid** — `ProgressStore.shared` ile gerçek data: LEVELS / STREAK / AVG TIME / DAILY SOLVED.
- **Pack progress donuts** — `packCompletionCount(packId) / 60.0` ile `Circle().trim` animasyonu.
- **7-day bar chart** — `recentDailyResults(days: 7)` ile gerçek daily data.
- **Hint usage donut** — static placeholder; gerçek data Faz G'de.

### Güncellenen: `SnugloApp/Features/Settings/SettingsView.swift`

- Account section: "Reset Progress" button (destructive) + confirm alert → `ProgressStore.shared.reset()`.

### Test: `Tests/SnugloAppTests/ProgressStoreTests.swift`

- **17/17 PASSED** — UserDefaults suite isolation, round-trip, streak, unlock zinciri, computeStars.

### Build

- `swift build` → **Build complete!** ✅
- `swift test` (SnugloEngine) → **66 tests, 0 failures** ✅
- `xcodebuild build` (iPhone 17 Simulator iOS 26.2) → **BUILD SUCCEEDED** ✅
- `xcodebuild test ProgressStoreTests` → **17 tests, 0 failures** ✅

---

## [v1.0-D] - 2026-05-25 (Faz D — 240 Gerçek Level + Daily Puzzle)

240 level deterministic generator (Cozy/Spice/Mambo/Woodland packs × 60); DailyPuzzle with date-based seed; PackProvider bridges engine to UI; LevelGenerator with SplitMix64 PRNG.

### Engine (D1 — LevelGenerator)
- **`Sources/SnugloEngine/Engine/LevelGenerator.swift`** *(new)* — `SeededRandom: RandomNumberGenerator` (SplitMix64), `LevelGenerator` struct.
  - `generate(packId:levelIndex:width:height:)` — deterministik level, seed = `seedBase ^ fnv1a(packId) ^ UInt64(levelIndex)`.
  - `bspPartition(rect:count:rng:)` — BSP (Binary Space Partition) ile tüm grid hücrelerini tam kapsar, parça örtüşmez.
  - `pieceRange(for width:)` → 5×5: (5,5) | 6×6: (6,7) | 7×7: (7,9) | 8×8: (8,12).
  - `fnv1a(string:)` — Swift.hashValue yerine kararlı FNV-1a hash (çalışmalar arası sabit).
  - `generateAll(forPack:gridSize:count:seedBase:)` — 60 leveli tek seferde üretir.
  - Static seed: `0x5A4E5547_4C4F5631` ("SNUGLOV1" ASCII hex).

### Engine (D2 — DailyPuzzle)
- **`Sources/SnugloEngine/Engine/DailyPuzzle.swift`** *(new)* — Tarih bazlı deterministik günlük bölüm.
  - `seed(for:)` → `UInt64(y*10000 + m*100 + d)`, UTC baz alır.
  - `gridSize(for:)` → haftalık döngü: Paz=7×7, Pzt=5×5, Sal=6×6, Çar=7×7, Per=8×8, Cum=5×5, Cmt=6×6.
  - `forDate(_:)` / `today(timezone:)` — packId="daily", levelIndex=0, ID="daily-0".

### Engine (D3 — LevelLoader genişletme)
- **`Sources/SnugloEngine/Engine/LevelLoader.swift`** — `loadGenerated(packId:levelIndex:seedBase:)` eklendi.
  - `static func gridSize(for packId:) -> Int` — cozy→5, spice→6, mambo→7, woodland→8.
  - Mevcut `loadLevel(named:)` ve `loadLevel(named:in:)` korundu (JSON geriye-uyumluluk).

### UI Bridge (D4 — PackProvider)
- **`SnugloApp/MockData/PackProvider.swift`** *(new)* — MockData'yı engine'e bağlayan köprü.
  - `allPacks()` → 4 Pack, UserDefaults'tan gerçek progress (ilk çalışmada cozy=12, spice=4 mock).
  - `levels(in packId:)` → 60 LevelItem (yıldız durumu FNV-1a ile deterministik).
  - `loadLevel(id:)` → "daily" → `DailyPuzzle.today()` | "packId-N" → `LevelGenerator.generate(...)`.
  - `completedCount(for:)` / `seedMockProgressOnce()` — UserDefaults, Faz E'de SwiftData ile değişecek.
  - Pack kilitleme: mambo kilitli (spice<5), woodland kilitli (mambo<5).

### Tests (D5)
- **`Tests/SnugloEngineTests/LevelGeneratorTests.swift`** *(new)* — 20 test.
  - Determinizm (3 pack × 3 tekrar), farklı seed/index, SolutionChecker geçerliliği, piece count aralıkları, generateAll×60, grid coverage, level ID formatı.
- **`Tests/SnugloEngineTests/DailyPuzzleTests.swift`** *(new)* — 15 test.
  - today() determinizm, forDate() determinizm, regresyon kilidi (2026-01-01=Per→8×8, seed=20260101), seed formülü, 7 haftalık döngü, farklı tarihler, SolutionChecker geçerliliği.

### Build (D6)
- `swift build` ✅ 0 uyarı | `swift test` ✅ 58 test, 0 hata | `xcodebuild -scheme SnugloApp build` ✅ BUILD SUCCEEDED.

---

## [v1.0-C] - 2026-05-25 (Faz C — 11 Ekran Gerçekten Yaratıldı)

Navigation iskelesi: 11 SwiftUI screens (Splash/Onboarding/MainMenu/LevelsList/PackDetail/GamePlay/Pause/LevelComplete/Stats/Shop/Settings); AppRouter (Route enum, @Observable) + NavigationStack; BottomTabBar component; MockData with 4 packs × 60 levels (240 total); Colors.swift extended with missing tokens (surface, onPrimaryContainer, secondaryContainer, tertiaryContainer, surfaceContainerLowest); GameView refactored with levelId param, timer HUD, PauseSheet & LevelCompleteSheet integration.

## [v1.0-C] — Navigation Skeleton (2026-05-25)

### Navigation (C1–C2)
- **`AppRouter.swift`** *(new)* — `@Observable` class with `path: [Route]`, `selectedTab: AppTab`.
  `enum Route`: `onboarding | mainMenu | game(levelID:) | packDetail(packName:) | settings | shop`.
  `enum AppTab`: `play | levels | stats | shop`. Helpers: `push(_:)`, `pop()`, `popToRoot()`.
- **`RootView.swift`** *(new)* — Single `NavigationStack(path:)` rooted at `SplashView`.
  All destinations registered via `.navigationDestination(for: Route.self)`.
- **`SnugloApp.swift`** — Entry point changed from `GameView()` → `RootView()`.

### Screens (C3)
- **`SplashView.swift`** *(new)* — 3×3 pastel block logo, fade-in + soft scale pulse.
  Auto-advances after 1.2 s: `hasOnboarded` → mainMenu or onboarding.
- **`OnboardingView.swift`** *(new)* — 3-page TabView carousel, dot indicators, Skip + Get Started.
  Sets `@AppStorage("hasOnboarded")` on completion.
- **`MainMenuView.swift`** *(new)* — TabView host (PLAY / LEVELS / STATS / SHOP).
  Play tab: progress pill, Daily Puzzle hero card, Continue section.
- **`LevelsListView.swift`** *(new)* — Pack cards (Cozy Beginnings, Spice Route, Nordic Hearth).
  Each card: icon badge, progress bar, tap → packDetail.
- **`PackDetailView.swift`** *(new)* — Banner with progress bar + 3-column LazyVGrid of 30 level tiles.
  Tile states: completed (stars), active, locked.
- **`StatsView.swift`** *(new)* — 2×2 stat cards (Solved 142 / Time 48h / Fastest 1:12 / Streak 14d),
  weekly bar chart, hint donut.
- **`ShopView.swift`** *(new)* — Snuglo Plus hero card, horizontal hint packs scroll, Remove Ads row.
- **`SettingsView.swift`** *(new)* — Toggle rows (Music / SFX / Haptics / Daily reminder), About section.
  Backed by `@AppStorage`.
- **`PauseOverlayView.swift`** *(new)* — Blur dimmer + card: Paused headline, timer, Resume/Restart/Home.
- **`LevelCompleteSheet.swift`** *(new)* — Bottom sheet: check circle, puzzle thumbnail, stats row
  (Time / Stars / Hints), Next Level / Replay / Home actions.

### Theme (C5)
- **`Colors.swift`** — Added `errorContainer`, `surfaceVariant` tokens.
  Made `Color(hex:)` initializer `internal` (was `private`) so feature files can use it.
- **`Typography.swift`** — Removed deprecated Faz B shims: `title`, `subtitle`, `body`, `caption`,
  `mono`, `blockLabel`. No call-sites were using them (confirmed by grep).
- **`Spacing.swift`** — Removed deprecated Faz B shim: `xxl`. No call-sites (confirmed by grep).

---

## [v1.0-B] — Nordic Hearth Theme (2026-05-25)

### Theme System (B1)
- **`Colors.swift`** — Replaced coral/cream palette with full Nordic Hearth token set:
  `background` `surfaceContainerLow/High/Highest` `primary` `primaryContainer` `onPrimary`
  `secondary` `tertiary` `onSurface` `onSurfaceVariant` `outline` `outlineVariant` `error`
  + 6 pastel block fills: `blockLavender/Sage/Peach/Blush/Cream/DustyOlive`
  + `shadowAmbient` tonal shadow base color.
- **`Typography.swift`** — Nordic Hearth scale: `headlineLarge/Medium/Small` (SF Rounded 28/22/18),
  `bodyLarge/Medium` (SF Pro 17/15), `numericLabel` (SF Mono 20), `labelSmall` (SF Pro 12 + UPPERCASE +tracking).
  System-font fallbacks used; custom fonts deferred to Faz H (BLOCKER-07).
  Legacy aliases (`title`, `body`, `caption`, `mono`, `blockLabel`) deprecated with `@available`.
- **`Spacing.swift`** — Updated to design-spec values: `xs=4 sm=8 md=16 lg=24 xl=32`.
  Radius tokens removed from Spacing (moved to Radius.swift).
- **`Radius.swift`** *(new)* — `AppRadius.card=20 / button=14 / block=10`.
- **`Shadow.swift`** *(new)* — `.shadowL1()` (0.06 opacity) / `.shadowL2()` (0.12 opacity) View modifiers.

### Piece Model (B2)
- **`Piece.swift`** — Added `public var cellCount: Int { cells.count }` computed property.
  Domain model unchanged; convenience added for BlockView numeric label.

### BlockView Rebuilt (B3)
- **`BlockView.swift`** — Full rebuild: Canvas-based, all Nordic Hearth tokens:
  - Pastel fill via `AppColors.blockColor(for: piece.id)` (deterministic `hashValue % 6`)
  - Corner radius `AppRadius.block` (10 pt) per cell
  - L1 shadow (idle) / L2 shadow (picked-up, scale 1.10×)
  - Inner-top bevel: 0.5 pt white-50% horizontal line when dragging
  - `piece.cellCount` label always shown, `AppTypography.numericLabel`, `AppColors.onSurface`

### GameView Palette (B4)
- **`GameView.swift`** — Background → `AppColors.background`; tray → `surfaceContainerHigh`;
  header text → `onSurface`/`onSurfaceVariant`; solved banner → `primary` fill.
- **`GridView.swift`** — Board background → `surfaceContainerLow`; grid lines → `outlineVariant`;
  all `AppSpacing.blockRadius/cardRadius` → `AppRadius.block/card`; `.shadowL1()` applied.

### Tests (B5)
- **`PieceCellCountTests.swift`** *(new)* — 4 unit tests for `Piece.cellCount`.
- `swift build` ✅ | `swift test` ✅ — 23 tests, 0 failures.

### Deferred to Faz H
- Dark mode token values (BLOCKER-06)
- Custom font bundle files: Plus Jakarta Sans / Be Vietnam Pro / Space Grotesk (BLOCKER-07)

All notable changes to this project are documented here.
Format: `## vX.Y — Title (YYYY-MM-DD)`

---

## v0.2 — Core UI (2026-05-24)

### Added
- `SnugloApp/` iOS App target (xcodegen, bundle id `com.felabs.snuglo`, iOS 17+, SwiftUI)
- `SnugloApp/project.yml` — xcodegen config with local `SnugloEngine` SPM dependency
- `SnugloApp/App/SnugloApp.swift` — `@main` App entry point
- `SnugloApp/Features/Game/GameViewModel.swift` — `@MainActor @Observable` state machine
  - `tryPlace(pieceID:at:)` — validates via `SolutionChecker`; accepts / rejects placement
  - `checkSolved()` — prints "Solved!" and sets `isSolved = true` when grid fully covered
- `SnugloApp/Features/Game/GameView.swift` — drag-drop game screen
  - Loads `level_5x5.json` on init
  - SwiftUI `DragGesture` with `.named("gameLayout")` coordinate space
  - Snap-to-grid with ±15pt buffer
  - Rejected placement: invalid red border + ease-back animation
  - Ghost overlay shows where piece will land
- `SnugloApp/Features/Game/GridView.swift` — Canvas-based grid renderer
  - Grid lines, placed pieces, snap ghost
- `SnugloApp/Features/Game/BlockView.swift` — piece renderer with drag scale & shadow
- `SnugloApp/Core/Theme/Colors.swift` — full Spec §7 color palette (`AppColors`)
- `SnugloApp/Core/Theme/Typography.swift` — SF font scale (`AppTypography`)
- `SnugloApp/Core/Theme/Spacing.swift` — 4dp base unit tokens (`AppSpacing`)
- `Tests/SnugloAppTests/GameViewModelTests.swift` — 4 ViewModel unit tests

### Build
```
cd SnugloApp && xcodegen generate
xcodebuild -project SnugloApp/SnugloApp.xcodeproj \
           -scheme SnugloApp \
           -destination 'platform=iOS Simulator,name=iPhone 16' \
           build
```
