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

## Gotcha'lar
- **Scroll/parallax efektleri:** Pushed (NavigationStack) bir view'da scroll-türevli efektleri `GeometryReader` + `onPreferenceChange` + `@State` ile sürme — bu kombinasyon layout feedback cycle yaratıp, her frame'deki state yazımı pop sırasında path binding'iyle yarışarak `RootTabView.hideBar`'ı true takar → tab bar + tüm ekran hit-test'siz donar. Scroll değerine ihtiyaç yoksa **lokal `GeometryReader`** (state'siz); değer bir sibling'de gerekiyorsa (örn. tam-ekran gradient arka plan) **iOS 18 `onScrollGeometryChange`** kullan (layout loop yaratmaz, sadece gerçek scroll'da tetiklenir). Dekoratif overlay'lere `allowsHitTesting(false)` ver. Detay: Obsidian `Fixes/PackDetail Scroll Freeze`.
