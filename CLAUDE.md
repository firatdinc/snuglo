# Snuglo

iOS SwiftUI cozy block-logic puzzle oyunu. Bu dosya açılışta otomatik yüklenir — projeyi sıfırdan taramana gerek yok.

**Bundle ID:** `com.felabs.snuglo` · **Repo:** `github.com/firatdinc/snuglo.git`
**Stack:** SwiftUI (iOS 18+), `SnugloEngine` lokal SPM paketi (deterministik level üretici), xcodegen, StoreKit 2 + WalletStore, Game Center, ProgressStore (UserDefaults JSON)
**Diller:** EN / TR / ES
**Obsidian:** `02 - Projeler/Snuglo/` (MOC + Fixes/ + Decisions/ + Session Log) — bkz vault `/Users/ergunyunuscengiz/Desktop/FELABS OBSIDIAN/FELabs`

## Build
```
cd SnugloApp && xcodegen generate && xcodebuild build -project SnugloApp.xcodeproj -scheme SnugloApp -destination 'generic/platform=iOS' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```
- SourceKit'in "No such module 'SnugloEngine'" uyarıları **yanlış pozitif** — gerçek build temiz.
- Build hatalarını sen kopyalama — ben build alıp tespit ederim.

## Çalışma kuralları
- **Tek-palet tema:** tüm renkler `AppColors` token'larından. Hardcoded hex **yasak**.
- Snuglo çalışmalarını Obsidian vault'taki proje alanına da kaydet.
- **Git: direkt `main`'de çalış.** Kullanıcı tercihi (2026-06-03) — feature branch + PR akışı YOK; `main` üzerinde commit'le ve `main`'e push et.

## Game drag mekaniği (juicy refactor)
- **Hücre-hassas hit-test:** tray parçaları `.contentShape(PieceCellsShape(piece:))` ile yalnız dolu hücrelerden tutulur (L/T/Z parçanın boş köşesine dokununca yanlış parça kapma bug'ı çözüldü). `PieceCellsShape` cs'i `rect.width/cols`'tan türetir.
- **Lift:** sürüklenen parça parmağın `dragLift`(46pt) üstünde yüzer; overlay VE snap aynı `liftedPos()`'tan hesaplanır → hayalet tam parça konumuyla eşleşir, parmak parçayı/hedefi örtmez.
- **Ortak snap:** 3 gesture (tray/carousel/relift) tek `updateSnap(for:at:)` kullanır — board'a girişte medium haptik+snap sesi, hücre değişiminde `HapticService.selection()` tık.
- **Juice:** sürüklerken `dragTilt` (yatay hıza göre eğim), bırakışta "poof" transition; geçerli yerleşim `.rigid` "thunk"; geçersizde `triggerInvalidFeedback()` = error haptik/ses + kırmızı flash overlay (shake DEĞİL — geometri offset'i gridFrame ölçümünü bozar, layout-loop riskli). Snap hedefi `GridView.snapPulse` (TimelineView, sadece sürüklerken/Reduce-Motion'da kapalı) ile nefes alan halo.
- Tray ≤3 parçada artık `spacing: AppSpacing.md` + pick `minimumDistance: 6` (relift hâlâ 2). Carousel sütun-izole olduğu için index seçimi korundu.

## Streak (MainMenu)
İki streak var: `currentStreak`/`longestStreak` (yalnız daily puzzle, Game Center'a gider — DOKUNMA) ve yeni **`playStreak`/`longestPlayStreak`/`playedDays`** (herhangi bir level tamamlanınca; `markCompleted`+`markDailySolved`'da `recordPlayDay`). MainMenu'de alev rozeti. Snapshot migration `decodeIfPresent` + load'da geçmişten backfill. Lokalizasyon: `menu.streak.*` (EN/TR/ES).

## Zen Mode (rakip araştırması #1 bulgusu)
`@AppStorage("zenMode")` (Settings → Gameplay toggle). Açıkken GameView: timer count-UP olur (`formattedTimer` elapsed), süre dolunca FAIL yok (`startTimer` fail koşulu `!zenMode`), `timerIsUrgent` hep false, HUD ikonu `leaf.fill`. Lokalizasyon: `settings.gameplay.*`. Gerekçe: türün en sevilen özelliği "timer yok/relax" (Woodoku/Blockudoku), Snuglo'nun "cozy" konumlandırmasıyla fail-timer çelişiyordu.

### Zen sage teması (renk değişimi)
Zen açıkken tüm uygulama **soft sage-yeşil** palete geçer. `AppColors`'ta mood tokenleri (surface/background L0–L4, primary ailesi, onSurface/variant, outline, gameBoard/gridLine/divider/blushAccent/softCocoa + surface/gridBackground/gridLines/success aliasları) artık **computed var** + `tone(_ normal:zen:)` helper'ı; `zenActive = UserDefaults.bool("zenMode")`. Bloklar, error, secondary/tertiary accentler ve skinler DEĞİŞMEZ (kimlik/sıcak vurgu korunur). Reaktiflik: `RootView` rebuild id'si `"\(lang)|\(theme)|\(zenMode)"` — toggle olunca tüm UI sage'i yeniden okur (tema-switch ile aynı pattern). Tek-palet kuralı korunur; hex'ler yalnız Colors.swift'te.

## Faz 4 feature'ları (2026-06-02)
- **Pause menüsü:** `PauseSheet` artık Devam/İpucu/Yeniden başlat/Ayarlar/Ev. İpucu `viewModel.applyHint()` (Endless'ta veya hintCount=0 ise gizli); Ayarlar `router.push(.settings)`.
- **Undo:** zaten `PowerUpBar` + `GameViewModel.undoLastMove()` (1 ücretsiz/session + gem + reklam). Eklendi: `GameViewModel.unlimitedUndo` (computed: `level.id` "endless" prefix VEYA `zenMode`) → relaxed modlarda sınırsız ücretsiz undo, PowerUpBar ∞ gösterir; zamanlı kampanya/daily gem ekonomisini korur.
- **Ses seviyesi:** `@AppStorage musicVolume`(0.6)/`sfxVolume`(1.0). `SoundService.fire` sfxVolume ile çarpar; `MusicService.targetVolume = userVolume*0.6` + `applyVolume()`. Settings'te `volumeRow` slider'ları.
- **Geri-dönüş bildirimi:** `NotificationService.scheduleComeback()` +2g/+7g lokalize re-engagement (UNTimeInterval, repeats:false); `RootView` scenePhase active→cancel, background→(enabled ise)arm. Settings toggle `comebackRemindersEnabled` (auth ister). Mevcut sabit-saat daily reminder ayrı durur.
- **Zen yumuşak hareket:** `AppMotion.card/.pop` artık computed + zen-aware (yavaş response, yüksek damping), `staggerStep` 0.05→0.08. RootView zenMode rebuild ile yayılır.
- **Müzik parça seçici:** `@AppStorage musicTrack` (auto/calm/zen); `MusicService.desiredTrack` refresh+install validation'da kullanılır. Settings menü picker.
- **Maskot tepkileri:** `MascotView` (idle nefes/bob + `celebrate` tek-sefer sevinç hop/wiggle; Reduce-Motion safe). LevelComplete hero celebrate=true; GameView sloth idle.
- **Export/Import:** `SaveTransfer` (allow-list anahtarlar → binary plist → base64 taşınabilir kod; header doğrulamalı import). `SaveTransferSheet` (Settings→Account: kopyala/paylaş + yapıştır→geri yükle; geri yükleme app restart'ta tam etkin). Anahtar listesi SaveTransfer.keys'de — yeni persistence anahtarı eklersen oraya da ekle.

## Faz 5 (2026-06-02)
- **Lifetime stats:** ProgressStore türetilmiş aggregate'ler (`totalStarsEarned/perfectSolves/bestSolveTime/daysPlayed`, campaign-only, yeni persistence YOK); StatsView "Lifetime" section (kpiCard reuse).
- **Erişilebilirlik:** volumeRow slider VO-ayarlanabilir + %% değer (eski `.combine` kaldırıldı); SaveTransfer export kodu kısa a11y label; CoachOverlay tek combined öğe.
- **Pack completion ödülü:** `PackRewardStore` (own UD; `rewardedPacks` + persisted `pendingCompletedPack` — detect→collect kill'e dayanıklı; ödül yalnız collect'te banked, 200 coin+25 gem tek-sefer/pack). Detection `GameViewModel.persistProgress` → `GameViewModel.packId(from:)` + `MockData.levelCount` + `packCompletionCount`. `PackCompleteOverlay` MainMenu'de (RewardModal+confetti+reward sesi), level-up/streak pattern'i. **Anahtarlar SaveTransfer.keys'e eklendi.**
- **Solve çeşitliliği:** her çözümde rastgele lokalize övgü (`praise.0-5`) board üstünde kısa pop (AppMotion.pop, Reduce-Motion safe, versioned token).
- **Lokalizasyon:** en/tr/es tam parite (369 anahtar), format-specifier + duplicate denetimi temiz. Yeni anahtar eklerken 3 dile de ekle (python helper'ları repoda kullanıldı).

## Faz 6 (2026-06-02)
- **Başarımlar 10→16:** +levelLegend100, packFinisher, perfectionistMaster25, dedicated7 (longestPlayStreak≥7), comboChampion (bestWinChain≥5), speedDemon (<15s). AchievementStats'a packsCompleted/longestPlayStreak/bestWinChain eklendi; rules + reward + category + sfSymbol + EN/TR/ES.
- **Rate prompt:** `@Environment(requestReview)` (StoreKit `SKStoreReviewController`) — cihaz-içi, ağsız/hesapsız. Pack-completion collect'te, `hasRequestedReview` ile bir kez, `totalLevelsCompleted>=8` koşuluyla, 1.4s gecikmeli.
- **Başarım progress bar:** `AchievementRules.progress(_,stats)->(current,target)`; kilitli + target>1 hücrelerde ince bar + N/target.
- **Combo milestone:** ×3/×5/×8'de rigid haptik + reward sesi; ×5→+1, ×8→+2 gem, combo pop'ta 💎+N (hide/break'te sıfırlanır).
- **Today banner:** menü tepesinde ince kapsül — zaman-bazlı selam (`today.greeting.*`) + bugünkü görev sayacı (N/3). Declutter korunarak tek satır.
- Lokalizasyon paritesi: 385 anahtar, en/tr/es tam.

## Faz 7 (2026-06-02)
- **Cosmetics:** +2 block skin (sunset Lv12, aurora Lv15 — palet Colors.swift), 6 toplam; +3 board (dusk/rose/meadow, AppColors gradient), 7 toplam. Settings selector'ları otomatik dahil eder.
- **Earn-a-hint:** PowerUpBar ipucu, hint+gem bittiğinde reklam hazırsa `.rewarded` olur; `HintRewardedSheet` → `AdsManager.showRewarded` → `addHints(1)`+`applyPowerUp(.hint)`. Undo rewarded pattern'i. `onHintRewarded` callback.
- **Daily share:** `DailyShareCard` (rabbit + daily streak), ImageRenderer; günlük bitince daily card'da ShareLink.
- **Pack header fix+enrich:** heroBanner artık **canlı** `packCompletionCount` (eski statik `MockData.completedCount` bug'ı düzeltildi) + `packStarsEarned` (★ X/Y) + gridSize'dan lokalize zorluk + sloth maskot + %100'de seal. `ProgressStore.packStarsEarned()` eklendi.
- **Stats share:** `StatsShareCard` (tiger + levels/stars/perfect/longest-streak); StatsView toolbar ShareLink.
- Lokalizasyon: 401 anahtar tam parite.

## Faz 8 (2026-06-02)
- **New Best Time:** GameViewModel persist'te markCompleted'tan ÖNCE prevBest yakalanır → `newBestTime` (gerçek iyileşme, ilk çözüm değil); LevelCompleteSheet'te "New Best!" tertiary badge.
- **Ses önizleme:** Settings ses bölümünde place/snap/solve/reward/error chip'leri (aktif pack+volume çalar).
- **Görev çeşitliliği:** `.perfectSolve` görev türü; `generate()` 4-günlük rotasyon, #2 no-hint/perfect alternasyonu; `recordSolve` stars param (persist'ten).
- **Endless rekor:** `EndlessStore.record`→Bool, `GameViewModel.newEndlessBest`; endless çözümde praise overlay "New Record! 🏆" + reward sesi.
- Lokalizasyon: 405 anahtar tam parite.

## Game-feel tasarım geçişi (2026-06-02)
"Daha oyun gibi" için, cozy paleti bozmadan eklenen game-feel sinyalleri:
- **Butonlar:** GameButtonStyle üst yüzüne gloss (primary, üst yarı) + 1px beyaz top-rim highlight → mevcut 3D slab'lara candy-button parlaklığı.
- **Rakamlar:** AppTypography numeric tokenleri **SF Rounded heavy/bold** (chunky game sayıları; başlık/gövde marka fontu Plus Jakarta Sans kalır).
- **Para birimi:** `BalanceChip` parlak yükseltilmiş pill (gradient sheen + rim + L1 shadow + kalın yuvarlak rakam).
- **Progress:** yeni `GameProgressBar` (inset track + gradient dolgu + gloss + spring) → pack header, XP/profile, weekly, chest meter.
- **Kartlar:** `cardSurface()` üst rim-highlight kazandı (uygulama geneli, moulded/tactile his).

## Round-2 fix'leri (2026-06-02)
- **SoundService havuz:** her asset için 4'lü AVAudioPlayer havuzu (`pools` + `nextIndex`, `firePool` round-robin) — hızlı/üst üste sesler birbirini kesmiyor ("bazen tam çalmama" fix).
- **Pause hızlı ayarlar:** PauseSheet'te müzik/ses/titreşim quick-toggle chip'leri (oyun içinden); müzik toggle `MusicService.refresh()` çağırır.
- **Solve praise z-order:** çözüm yazısı board overlay'inden çıkıp kök ZStack zIndex 70'e taşındı (eskiden tray arkasında kalıyordu); yeni `PraiseBadge` (gradient kapsül + sparkle + radial glow, spring).
- **Chest satisfying redesign:** opak 0.92 scrim; dolu radial madalyon (eski soluk transparan symbol değil); artan sallanma+pulse anticipation + artan light haptik; açılışta beyaz flash + reward sesi + success haptik; dönen altın sunburst ışınlar; ödül overshoot spring. Reduce-Motion safe.

## Ses & Müzik (kullanıcı sağladı, 2026-06-02)
**SFX:** `Resources/Sounds/*.caf` (mono): click/place/snap/solve/error + dedike reward/levelUp/combo. `SoundService` drop-in: `<event>.caf` otomatik; opsiyonel pakete-özel `<event>_soft/_crisp.caf` (native rate); eksikse zarif fallback (reward/levelUp→solve, combo→snap). Players asset-adıyla key'li.
**Müzik:** `Resources/Audio/bgm.caf` (normal) + `bgm_zen.caf` (zen). `MusicService` (@MainActor singleton): sonsuz loop, off-main yükleme, crossfade (0.8s), `isOtherAudioPlaying` ile kullanıcının kendi müziğine saygı, arka planda duraklar. `RootView`'da scenePhase + zenMode'a, Settings müzik toggle'ına bağlı. Kaynak mp3'ler `afconvert` ile .caf'a çevrildi (SFX -c 1, müzik -c 2). xcodegen `.` taraması .caf'ları bundle köküne flat kopyalar.

## Gotcha'lar
- **`LocalizedStringKey("...\(x)...")` raw key gösterir (KRİTİK):** String-literal İÇİNDE interpolation, `\(x)`'i FORMAT ARGÜMANI sayar → aranan key `"...%@..."`/`"...%lld..."` olur, bulamaz, raw key render eder. Dinamik key'lerde ÖNCE String değişkene ata, sonra ver: `let key = "achievement.\(rawValue).title"; return LocalizedStringKey(key)`. (Pack.titleKey bu yüzden çalışıyordu, gridLabelKey/achievement.*.title bu yüzden raw'dı — `Achievement.swift`, `MockData.gridLabelKey` düzeltildi.) Build'de key'ler doğru olsa bile runtime lookup bu yüzden patlar; teşhis: `plistlib` ile built `.app/<lang>.lproj/Localizable.strings` değerleri doğru çıkar ama ekranda raw.
- **Loading-gate pattern:** yavaş/async ekranlarda `LoadingGate(isReady:) { content }` kullan (Core/Components/LoadingGate.swift) — ekran anında gelir + `LoadingView` gösterir, `isReady` true olunca içerik cross-fade. ShopView böyle (StoreKit yüklemesi `.task`'te, sonra `ready=true`). Ağır içerik build'i transition'ı bloklamaz → "System gesture gate timed out" gider.

- **Scroll/parallax efektleri:** Pushed (NavigationStack) bir view'da scroll-türevli efektleri `GeometryReader` + `onPreferenceChange` + `@State` ile sürme — bu kombinasyon layout feedback cycle yaratıp, her frame'deki state yazımı pop sırasında path binding'iyle yarışarak `RootTabView.hideBar`'ı true takar → tab bar + tüm ekran hit-test'siz donar. Scroll değerine ihtiyaç yoksa **lokal `GeometryReader`** (state'siz); değer bir sibling'de gerekiyorsa (örn. tam-ekran gradient arka plan) **iOS 18 `onScrollGeometryChange`** kullan (layout loop yaratmaz, sadece gerçek scroll'da tetiklenir). Dekoratif overlay'lere `allowsHitTesting(false)` ver. Detay: Obsidian `Fixes/PackDetail Scroll Freeze`.

- **`.page` TabView (RootTabView/BottomTabBar) — 3 kural:**
  1. **Tab tap'i `disablesAnimations` ile atlatma:** uzak tab'a animasyonsuz programatik geçiş, iç `UIPageViewController`'ın currentIndex'ini desenkronize edip sonraki tap'lerde **donduruyor**. Tab tap animasyonlu kalmalı (`router.selectTab` düz çağrı).
  2. **Tüm tab kökleri nav bar-tutarlı olmalı:** bir tab kökü görünür `navigationTitle` gösterip diğerleri `.toolbar(.hidden, for: .navigationBar)` yaparsa, swipe sırasında iki sayfanın bar'ı çakışıp `NSInternalInconsistencyException: top item belongs to a different navigation bar` ile **crash** eder. Çözüm: HER tab kökü (`MainMenu/Levels/Leaderboard/Profile/Shop`) kök nav bar'ı gizlesin; başlığı kendi custom header'ında göster (Shop = `BalanceHeader`).
  3. **Ağır tab köklerini `DeferredContent { ... }` ile sar** (Core/Components/DeferredContent.swift): tab tap/swipe yavaşlığının sebebi, page-scroll'un ara sayfaları (özellikle dev `MainMenuView`) senkron build etmesiydi → 1-2 sn ana-thread stall. `DeferredContent` önce hafif `LoadingView` gösterip 50ms yield sonrası gerçek ağaç build eder; `@State ready` page TabView ömrü boyunca kaldığından bir kez build edilir, sonraki geçişler anında. Shop zaten kendi `LoadingGate`'ine sahip, tekrar sarma.
