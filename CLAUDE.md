# Snuglo

iOS SwiftUI cozy block-logic puzzle oyunu. Bu dosya açılışta otomatik yüklenir — projeyi sıfırdan taramana gerek yok.

**Bundle ID:** `com.snuglo.app` (RC/ASC app bundle; 2026-06-06 değişti, eski: com.felabs.snuglo) · **Repo:** `github.com/firatdinc/snuglo.git`
**Stack:** SwiftUI (iOS 18+), `SnugloEngine` lokal SPM paketi (deterministik level üretici), xcodegen, StoreKit 2 + WalletStore, Game Center, ProgressStore (UserDefaults JSON)
**Diller:** EN / TR / ES
**Obsidian:** `02 - Projeler/Snuglo/` (MOC + Fixes/ + Decisions/ + Session Log) — bkz vault `/Users/ergunyunuscengiz/Desktop/FELABS OBSIDIAN/FELabs`

## Build
```
cd SnugloApp && xcodegen generate && xcodebuild build -project SnugloApp.xcodeproj -scheme SnugloApp -destination 'generic/platform=iOS' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```
- SourceKit'in "No such module 'SnugloEngine'" uyarıları **yanlış pozitif** — gerçek build temiz.
- Build hatalarını sen kopyalama — ben build alıp tespit ederim.

## ASC otomasyonu (scripts/)
`scripts/` — ASC API otomasyonu (Worplix pattern'i): `asc_client.py` (JWT/.env/strings), `setup_leaderboards.py` (4 board), `setup_achievements.py` (35 başarım, isim Localizable.strings'ten), `setup_iap.py` (8 IAP: premium + 5 gem + removeads + hints), `setup_revenuecat.py` (RC ürün+entitlement `premium`/`ads_removed`+offering), `upload_iap_screenshots.py` (IAP review screenshot upload: reserve→PUT→commit, idempotent, FAILED'i silip replace eder). Idempotent, dry-run default, `--apply` ile yazar. `secrets/.env.local` (git-ignored: APP_STORE_KEY_ID/ISSUER_ID/KEY_PATH/.p8/APP_ID) + RC için REVENUECAT_PROJECT_ID/SECRET_KEY gerekir. `pip3 install --user "pyjwt[crypto]"`.
- **IAP review screenshot GOTCHA:** Apple `IMAGE_INCORRECT_DIMENSIONS` verir eğer görselde **alpha kanalı varsa** (screenshot alpha içeremez!) veya boyut standart değilse. Çözüm: **JPEG'e çevir (alpha düşer) + 1242×2688** (`sips -s format jpeg in.png --out out.jpg; sips -z 2688 1242 out.jpg`). Görseller `scripts/iap_screenshots/`.

## API ile tam ASC submission (2026-06-09 — Snuglo 1.1.0 gönderildi)
Build sonrası metadata+IAP+screenshot+submit'in tamamı .p8 API ile yapıldı. Script'ler: `asc_metadata.py` (sürüm/copyright/kategori/3-dil loc/yaş), `asc_screenshots.py` (App Store görselleri APP_IPHONE_67=1290×2796), `fix_iap_localizations.py`, `upload_iap_screenshots.py`. **Tam reçete + tüm tuzaklar: `~/Desktop/iOS-Release-Automation-Guide.md` "EK: API ile UÇTAN UCA ASC Submission" bölümü.** Kritik öğrenilenler:
- **IAP READY_TO_SUBMIT = 4 parça:** localization (`POST /v1/inAppPurchaseLocalizations` — /v2 DEĞİL; desc ≤45 krk) + price + screenshot (JPEG no-alpha 1242×2688) + **availability** (`POST /v1/inAppPurchaseAvailabilities`, ilişki adı **`inAppPurchase`**, tüm territory). Availability en sık unutulan → MISSING_METADATA sebebi.
- Sürüm "valid" için: **App Privacy published** (API'DE YOK → UI'dan) + **copyright** + **contentRightsDeclaration** + **Free pricing** (API kararsız → UI) + build attached.
- **iPad screenshot zorunluluğu = binary universal.** `project.yml TARGETED_DEVICE_FAMILY: "1"` ile iPhone-only.
- Açıklamada emoji/✦ yasak (`INVALID_CHARACTERS`). Yaş şeması 2025 yeni alanlar (advertising/lootBox/messagingAndChat/gunsOrOtherWeapons/userGeneratedContent/parentalControls/healthOrWellnessTopics/ageAssurance); seventeenPlus/kidsAgeBand yok.
- API ile oluşturulan boş `reviewSubmission` READY_FOR_REVIEW'a düşüp iptal edilemiyor → **son Submit'i UI'dan yap** (metadata/IAP'ı API ile hazırla).
- **ITMS-91064 (INVALID_BINARY, 2026-06-09):** `PrivacyInfo.xcprivacy`'de NSPrivacyTracking=true + boş NSPrivacyTrackingDomains = geçersiz. Reklam SDK'lı projede **NSPrivacyTracking=false + boş domain** bırak (GoogleMobileAds kendi manifest'inde tracking+domain beyan eder). Düzeltince yeni build gerekir; ASC metadata/App Privacy değişmez.

## Store görseli bölme (`scripts/split_screenshots.py`) — ONAYLI YÖNTEM (2026-06-09)
Yan-yana 5 panelli composite promo görselini tek tek 6.5" App Store screenshot'larına (1242×2688) böler. **Çalıştırıcı:** sistem Python'ında PIL/numpy yok + PEP 668 pip'i bloke ediyor → `jarvis-local`'in venv'i kullanılır: `/Users/ergunyunuscengiz/Desktop/jarvis-local/.venv/bin/python3 scripts/split_screenshots.py <kaynak.png> <çıktı_dizini>`. (Script snuglo'da, sadece yorumlayıcı jarvis-local'den.)
- **DOĞRU YAKLAŞIM (uzun deneme-yanılma sonucu, başka şey deneme):** Paneller arası ayraç = **açık-gri çubuk** (neutral ~#E5E5E5, panel zeminlerinde HİÇ yok → piksel-hassas anchor) + lacivert boşluk. Her paneli **gri çubuğu hariç tutan, lacivert boşluktan kesen "divider-aligned slot"** olarak al: `[önceki gri-çubuk sonu, kendi gri-çubuk başı]`. Paneller eşit pitch'li olduğundan her dilim ~582px = tam 6.5" oranı (0.461≈0.462) → **direkt resize**, distorsiyon yok.
- **YAPMA:** yatay dolgu (kenar/satır-rengi padding sündürür/şerit bırakır), eşit-N bölme (gri çubuğu/boşluğu panele katar), dikey kırpma (başlık/splash tepe-tabana kadar dolu, kesilir), keskinleştirme (kullanıcı istemedi). Kaynak ~520px/panel olduğundan upscale yumuşak — gerçek netlik için yüksek-çöz. kaynak gerekir, uydurma sharpen değil.

## Enerji & bölümler (2026-06-05)
`EnergyStore` (Core/Energy): max 50, oyun −5, 3dk'da +1, timestamp offline regen, premium sınırsız (`StoreManager.isPremium`), UITest bypass. Gate `AppRouter.push(.game/.gamePlay)`'de (zen/endless `endless-*` ÜCRETSIZ); yetmezse `EnergyGateSheet`. MainMenu: enerji HUD + Zen kartı + rewards FAB dropdown. **1020 bölüm** (MockData 17 pack×60, hepsi progresyonla açık, `MockData.totalLevels`). Pack-IAP kaldırıldı.

## Monetizasyon & Ekonomi
Ekonomi/monetizasyon tasarımının tek doğruluk kaynağı: **`MONETIZATION_AND_ECONOMY.md`** (repo kökü). Felsefe: **nazik** (kozmetik + convenience + reklamsız abonelik; ilerleme bloklanmaz). coin=yumuşak, gem=sert/kıt. Zen/Endless = relaxed (günlük cap'li ödül, gem yok). Fazlar: 1) ekonomi rebalance 2) zen çeşitlilik 3) gem sink'leri 4) GameCenter 5) AdMob 6) RevenueCat.

## Tasarım: Warm Cozy (2026-06-05)
Palet token-bazlı **Warm Cozy**: krem `#FBF4EA` zemin, terracotta `#E08A4F` primary, bal accent, sıcak kil-gül secondary, sıcak kahve metin (`Colors.swift`). Bloklar + Zen sage varyantları korundu. Kartlar (`CardSurface`) sıcak "taban dudağı" (lip) + belirgin kenar = oyunsu tile. Tema cold-launch'ta `.page` TabView'da dark'a düşebiliyor (bilinen quirk; in-app Settings toggle ile düzelir).

## Çalışma kuralları
- **Tek-palet tema:** tüm renkler `AppColors` token'larından. Hardcoded hex **yasak**.
- Snuglo çalışmalarını Obsidian vault'taki proje alanına da kaydet.
- **Git: OTOMATİK commit/push YOK (2026-06-07).** Kullanıcı açıkça "commit/push yap" demeden git'e dokunma. Dendiğinde direkt `main`'de çalış (feature branch + PR YOK), `main`'e push et.

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

## Snuglo Nook — cozy meta-layer (2026-06-10)
Rakip block-puzzle'larda olmayan farklılaştırıcı: bulmaca çözdükçe büyüyen kişisel cozy mekân (Lily's Garden meta-formülü + Snuglo maskotları). Coin sink (dekor) + gem sink (sahneler/premium dekor). Dosyalar:
- `Core/Nook/NookCatalog.swift` — statik içerik: 16 dekor (12 coin + 4 gem), 11 sahne (`scene-*` assetleri; ilki `scene-island` ücretsiz, gerisi gem), maskotlar **PackArt'tan türetilir** (her pack → bir dost).
- `Core/Nook/NookStore.swift` — `@Observable @MainActor` singleton, `snuglo.nook.v1` Codable snapshot (decodeIfPresent back-compat). `ownedDecor/ownedScenes/selectedScene` kalıcı; **maskotlar kalıcı DEĞİL** → `ProgressStore.packCompletionCount >= levelCount` ile canlı türetilir (desync olamaz). `completion` = (dekor+sahne+maskot) / toplam.
- `Features/Nook/NookView.swift` — Royal-Match-tarzı **in-scene dekorasyon** (juicy refactor 2026-06-10). Satın alma `WalletStore.spend` üzerinden.
- Route: `.nook` → `BottomTabBar.tabDestination` + `RootView.preMainDestination`. Giriş: `MainMenuView.nookCard` (towerCard'dan sonra, "cozy %" rozetli).
- Lokalizasyon: `nook.*` 45 anahtar × en/tr/es. Maskot adı yok → pack başlığını kullanır (ekstra string yok).

### Nook = Sahne Restorasyonu (2026-06-10, v2 — ANA MODEL)
**Mevcut model bu.** Decor/satın-alma tamamen kaldırıldı. Her pack'in sahnesi (`PackArt.theme(forPackId:).scene`) **3×2 = 6 parçalı**, başta **siyah silüet** (grayscale + brightness −0.55). Her **10 bölümde 1 parça hakkı** kazanılır (`earnedPieces = packCompletionCount / 10`, cap 6 — türetilmiş, runtime award hook YOK). Kullanıcı Nook'ta kazandığı parçayı (sahnenin renkli crop'u) **oyundaki gibi sürükleyip** karanlık slotuna bırakır → o bölge renk patlamasıyla açılır (flash + scale pop + `SoundService.play(.snap)` + medium haptik). 6/6 tamamlanınca sahne bütünleşir, pack maskotu sahnede belirir + konfeti (`SolveCelebration`) + reward sesi.
- `NookStore` (v2, key `snuglo.nook.v2`): yalnız `placed: [packId:Int]` persist; `earnedPieces/availablePieces/placeNextPiece/isRestored`. `completion` = yerleşen parça / (17 pack × 6). Mascot'lar hâlâ pack-tamamlamadan türetilir.
- `NookView`: dikey ScrollView YOK (drag/scroll çakışmasın) — VStack: yatay pack şeridi (her chip mini restore önizleme + n/6 + hazır-parça noktası) → `restorationCanvas` (GeometryReader, `.coordinateSpace(.named("nook.canvas.space"))`, hücre mask'leri ile silüet/renkli cell + nabız atan hedef slot) → tray (sürüklenebilir `PieceThumb` cell-crop + ipucu/kilit-ipucu) → footer (% restored bar + kurtarılan dost sayısı). `DragGesture(coordinateSpace:.named(...))`, drop `cellRectInSpace(placedN).contains` ile doğrulanır; isabetsizse light haptik (ceza yok). Alt-view'lar: `RevealedCell`, `PieceThumb`, `RestoreThumb`.
- **Engine zorluk:** `LevelGenerator.difficultyPieceCount` her 10. bölümde (`levelIndex % 10 == 0`) **+1 parça** → milestone bölümler biraz daha zor. `partitionGrid` count'u hücreyle sınırladığından güvenli; seed `levelIndex`'e bağlı, üretim deterministik kalır.
- MainMenu `nookCard`: `totalAvailablePieces>0` ise sarı "N" puzzle rozeti, değilse "% cozy".
- Yeni key'ler: `nook.drag.hint/pieces.ready/scene.done/locked.hint/restored.badge/world.restored` × en/tr/es. Eski decor/furnish key'leri kullanılmıyor (zararsız, duruyor).
- **Cam-kırığı (glass-shatter) shard'lar** (kullanıcı isteği 2026-06-10): Sahne PNG'leri **şeffaf, ada-şekilli** — dikdörtgen DEĞİL. O yüzden grid yerine `ShardGeometry` (Features/Nook): merkez-dışı bir noktadan ışıyan **6 düzensiz poligon shard** (sabit/deterministik, normalize 0–1; `shards`/`bbox`/`centroid`/`contains` + `ShardShape: Shape` rect'e scale eder). Silüet = `Image(scene).scaledToFit().colorMultiply(.black)` → **adanın siyah hali** (şeffaf bg korunur, dikdörtgen siyah değil). Açılan shard = aynı `scaledToFit().mask(ShardShape)` ile renkli. `ShardPieceView` (eski ScenePieceCrop yerine) = shard'ı bbox'a kırpıp ölçekler (tray/floating/reveal). Drag hedefi `ShardGeometry.contains(shards[placedN], normalizedPoint)` ile point-in-polygon.
- **Sürpriz-yumurta reveal — level-complete EKRANININ İÇİNDE:** her 10. bölüm İLK kez bitince `GameViewModel.persistProgress` (campaign dalı, `wasCompleted` guard) → `NookRevealCenter.shared.announce`. `NookPieceRevealOverlay` artık **`GameView`'daki `.fullScreenCover(LevelCompleteSheet)` içeriğine `.overlay`** olarak gömülü (RootView overlay cover'ın altında kalıyordu) → sürpriz tam level-complete ekranının üstünde belirir. Yumurta: sallanan gift + dönen sunburst → patlama (`SolveCelebration` + reward sesi + success haptik) → shard pop + "Şimdi yerleştir"(→`showComplete=false`+`router.push(.nook)`)/"Sonra". RootView'da `!isGameActive` fallback overlay'i de duruyor (zararsız). Reduce-Motion safe. Key'ler: `nook.reveal.title/subtitle/place/later`.
- **Hizalama fix (2026-06-10):** Açılan parça silüete tam oturmuyordu (ayrı renkli-katman + siyah-silüet subpiksel/gölge kayması). Çözüm **katman ters çevrildi**: taban HEP tam renkli sahne (`Image(scene).scaledToFit()`), üstüne *yerleştirilmemiş* shard'lar için `colorMultiply(.black).mask(ShardShape)` siyah örtü. Yerleştirince o shard'ın siyah örtüsü kalkar (canvas `.animation(value: placedN)` + `revealFlash` beyaz parlama) → aynı piksellerin üstü açıldığı için **birebir oturur**. RestoreThumb de aynı flip. `RevealedShard` kaldırıldı.
- Sonraki fazlar: shard yerleşim sırasını serbest seçtirme, iCloud sync.

### Bölüm-arası reklam flash fix (2026-06-10)
Interstitial solve anında (`onChange isSolved`) tetikleniyordu; hemen ardından `.fullScreenCover(LevelCompleteSheet)` reklamın üstüne presentlanıp reklamı ~0.5sn'de söküyordu ("reklam yanıp kayboluyor"). Çözüm: `AdsManager.shared.onLevelCompleted()` solve handler'dan **kaldırıldı**, `LevelCompleteSheet.onNext` içine **cover kapandıktan sonra 450ms gecikmeyle** taşındı (tüm geçiş yollarından önce, başta). Frequency-cap mantığı AdsManager'da aynı. Artık reklam "Next"te, bir sonraki ekranın ÜSTÜNE temiz açılıyor; kapatınca sonraki bölüm görünüyor.

### Reklam flash v2 — kararlı-VC retry (2026-06-13)
450ms sabit gecikme yine yetmiyordu: cover-dismiss + `router.replaceTop` geçişi 450ms'i aşınca `topViewController()` hâlâ kapanmakta olan VC'yi döndürüp reklam onunla sökülüyordu ("yanıp kayboluyor" devam). Çözüm `AdsManager`'da: `showInterstitial` artık reklamı `present(_:attempt:)` ile **kararlı top-VC** üstüne sunuyor. Yeni `stableTopViewController()`, zincirde `isBeingPresented`/`isBeingDismissed` olan VC varsa **nil** döner; present 200ms aralıkla ~3sn'e kadar retry eder, hiyerarşi oturunca sunar. Frequency-cap sayaçları fill'den bağımsız önce artar (testler korunur). Sabit gecikme tahmin etmek yerine geçişin gerçekten bitmesini bekliyoruz.

### (ESKİ — v1, kaldırıldı) Nook juicy redesign — Royal Match in-scene decor
Eski "dükkân grid'i" kaldırıldı; sahne artık **döşenecek köşe**. Her `Decor`'a sabit `anchor: CGPoint` (0–1 normalize, top-left) + `slotSize` eklendi (16 prop, back→front `anchor.y` sıralı çizilir = doğal katmanlama). NookView'da `GeometryReader` canvas (360pt): sahne backdrop + her dekorun slotu. **Boş slot** = nabız atan kesik-çizgi hayalet halka + soluk sembol + fiyat çipi (tıklanır). **Dolu slot** (`PlacedDecor`) = cushion + sembol + giriş pop'u (`AppMotion.pop` scale overshoot) + ilk yerleşimde genişleyen flash halkası + sürekli hafif idle bob (Reduce-Motion safe). Dokunma akışı (`tapBuy`): `buyDecor` → `justPlaced=id` + `SoundService.play(.place)` + `impact(.medium)`; yetmezse `notAfford()` (error haptik/ses + alttan toast `nook.toast.poor`). Tüm dekor alınınca `NookStore.claimNookCompleteBonus()` (tek-sefer **50 gem**, `nookCompleteRewarded` snapshot'ta persist) → `SolveCelebration` konfeti + `RewardCenter.showCurrency(.gem)` + `completeSeal`. Altta `furnishMeter` (dekor N/16 animasyonlu gradient bar) + segmented **Scenes/Friends** (decor sekmesi yok, artık canvas'ta). Yeni key'ler: `nook.furnish.title/hint.tap/toast.poor/complete`.
- Sonraki fazlar: sürükle-yerleştir (serbest konum), sezonluk sahne/dekor (event kancası), iCloud sync, maskot kurtarma anı için kendi popup'ı.

## 2026-06-13 oturumu (iCloud sync + ipucu + enerji UX)

### iCloud sync (NSUbiquitousKeyValueStore)
`Core/Persistence/CloudSync.swift` — `@MainActor @Observable` singleton. Kaydı (SaveTransfer.keys = tek doğruluk kaynağı) iCloud KVS'e şeffaf yedekler/geri yükler. **Neden KVS:** tüm save birkaç küçük JSON snapshot, KVS bütçesinin (1MB) çok altında; şema/CloudKit container gerekmez, sadece `com.apple.developer.ubiquity-kvstore-identifier` entitlement (`$(TeamIdentifierPrefix)$(CFBundleIdentifier)`, SnugloApp.entitlements'a eklendi). **Çakışma modeli:** monoton `snuglo.cloud.rev` sayacı hem UserDefaults hem KVS'te; yüksek rev kazanır (single-player için doğru tradeoff). **Lifecycle (RootView):** `bootstrap()` launch'ta store'lar UserDefaults okumadan ÖNCE çalışır — UI `cloud.ready`'ye gate'li (`LoadingView`); taze kurulumda iCloud payload'unu ~2.5sn bekleyip merge eder (yeni cihaz restore), mevcut oyuncuda anında yedekler. `pushToCloud()` background'a geçişte. Lifetime observer (`didChangeExternallyNotification`) dış değişikliği UserDefaults'a yazar (sonraki cold launch'ta uygulanır — in-memory singleton'lar mid-session hot-swap edilmez). SaveTransfer.keys'e enerji + gamesession anahtarları da eklendi.

### İpucu hibrit (önce yanlış parçayı düzelt) — `GameViewModel.placeHintPiece`
Eski: sadece tepsideki sıradaki yerleştirilmemiş parçayı auto-place ediyordu. Yeni (kullanıcı isteği): tahtada **yanlış konumdaki** parça (`misplacedPieceIDs`: current origin != solution origin) varsa ÖNCE onu düzelt — solution slot'u boşsa oraya taşı (`tryPlace`), swap/cycle ile bloke ise birini tepsiye geri al (`removePlacement`, sonraki ipucu temiz taşır). Hiç yanlış parça yoksa eski davranış (sıradaki unplaced'ı yerleştir). Additive → mevcut testler korundu. `PowerUpRules.isApplicable` `.hint`'e `misplacedCount` (default 0) param eklendi: tüm parçalar konulmuş ama yanlış yerdeyken de ipucu uygulanabilir. `absoluteCells` helper.

### Enerji UX — çift-harcama fix + harcama animasyonu + resume
- **Çift-harcama fix:** Aynı ücretli bölüme tekrar girince enerji yeniden gidiyordu. `EnergyStore.openPaidLevels: Set<String>` (persist `snuglo.energy.openlevels.v1`). `startGameIfAffordable(levelID:)` — levelID zaten open set'teyse ücretsiz (re-entry); ilk şarjda set'e ekler. `endPaidSession(levelID:)` tamamlamada (`GameViewModel.persistProgress`) çağrılır → sonraki taze başlangıç tekrar ücretlendirir. AppRouter'ın 3 şarj noktası (`push`/`replaceTop`/`launchPendingGameIfReady`) `levelID(of:)` ile çağırır. Relaxed/Endless/Tower zaten ücretsiz (nil).
- **Harcama animasyonu:** `Core/Components/EnergySpendBadge.swift` — oyuna girişte bir kez "−5 ⚡" (honey gold `AppColors.tertiary` kapsül) spring pop + yukarı süzülüp solma; Reduce-Motion fade-only. **design-motion-principles** skill'i (mobile→Jakub polish + Jhey delight; rare event=expressive OK). `EnergyStore.pendingSpendAnimation` gerçek şarjda set, `GameView.onAppear` `consumeSpendAnimation()` ile bir kez tüketir (re-entry/relaxed'de 0 → animasyon yok). Key: `energy.spent.a11y` ×3 dil.
- **Resume (kaldığı yerden devam):** `Core/Persistence/GameSessionStore.swift` (+`GameSession` Codable, persist `snuglo.gamesessions.v1` JSON). Sadece deterministik bölümler (campaign+daily; Endless/Tower random seed → `isResumable=false`). `GameViewModel.makeSession/restore` (+`levelFingerprint` = WxH|sorted-pieceIDs → stale snapshot reddi, ör. daily gün değişimi; restore overlap/OOB defensive check; `startTime` elapsed'e göre ayarlanır). `GameView`: onAppear'da fresh vm + session varsa restore + elapsedSeconds geri yükle; `saveSession()` placements onChange + onDisappear + scenePhase!=active; solve/replay/retry'da `GameSessionStore.clear`. Enerji çift-harcama fix ile eşleşir (attempt bir kez ödenir).

### Milestone Nook "back → stuck board" fix + Next enerji-gate (2026-06-13)
**Bug:** her 10. bölüm (milestone) bitince LevelComplete + Nook reveal çıkıyor; "Şimdi yerleştir" → `showComplete=false` + `router.push(.nook)` yapıp **bir sonraki bölüme geçmiyordu** → çözülmüş GameView stack'te kalıyor, Nook'tan back basınca o çözülmüş board'a düşüp takılıyordu. **Fix:** Nook `onPlace` artık `advanceBehindNook()` ile bir sonraki bölümü Nook'un ALTINA koyar (afford varsa `replaceTop`, yoksa `popToRoot`) → Nook'tan dönünce sonraki bölüm/anasayfa, asla takılı board yok. `onNext` gövdesi `goToNextLevel(fireInterstitial:)` + `scheduleInterstitial()` metotlarına çıkarıldı; LevelComplete cover'ı type-check timeout'u nedeniyle `levelCompleteCover` computed @ViewBuilder'a taşındı.
**Next enerji-gate:** `nextBlockedByEnergy` (campaign/non-last-daily + !canStartGame, endless/premium hariç) → LevelCompleteSheet'te Next butonu **"Enerji Bitti"** CTA'sına döner (`complete.outOfEnergy` ×3 dil, bolt.slash). Aksiyon `resolveNextEnergy()`: rewarded hazırsa reklam → +10 enerji → `goToNextLevel` (devam); değilse `popToRoot` + `showPaywall` (asla takılı board bırakmaz). Reklam iptal edilirse cover kalır → Home/Replay seçilebilir.


### Nook milestone place → otomatik geri dönüş (2026-06-13)
Milestone "Şimdi yerleştir" ile Nook'a gidip parçayı yerleştirince oyuncu Nook ekranında takılı kalıyordu (elle back gerekiyordu). `NookRevealCenter.autoReturnOnPlace` flag'i: GameView `onPlace`'te (advanceBehindNook + push(.nook)'tan önce) set edilir; `NookView.commitPlace` başarılı yerleşimden sonra flag set'liyse tüketip kısa gecikmeyle (`restored ? 2.6 : 1.2s`, reveal/konfeti otursun) `router.pop()` → bir önceki bölüme (advanceBehindNook ile yerleştirilmiş sonraki level) döner. NookView `onDisappear` flag'i temizler (elle back ile çıkışta sonraki normal Nook ziyaretine sızmasın). Normal MainMenu→Nook ziyaretinde flag false → auto-return yok (dekorasyon için kalır). DevOverrides (Ergün test) tamamen geri alındı.
