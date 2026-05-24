# Snuglo — Full Execution Plan (v0.2 → v1.0)

> Bu doküman Main agent tarafından okunup sırayla uygulanacak. SNUGLO_SPEC.md tek doğruluk kaynağıdır; bu doküman sadece koordinasyon planıdır.

---

## Genel Kurallar (Main agent'ın TÜM phase'lerde uyacağı)

1. Her version için yeni bir feature branch (`feature/vX.Y-short-name`) aç, bitince main'e merge et.
2. Her version sonunda kısa bir CHANGELOG entry'si ekle (`CHANGELOG.md` yoksa oluştur).
3. Her code task'ından sonra mutlaka reviewer'a göster (`wait_for_completion=true`).
4. Reviewer BLOCKER bulursa otomatik fix task'ı tetiklenir (zaten orkestra mekaniği).
5. Reviewer sadece IMPORTANT/NITPICK bulursa devam et — fix yapma, sadece CHANGELOG'a "known issues" diye not düş.
6. **Bir version tamamlanmadan sonrakine geçme.** Kod compile etmiyorsa veya testler kırılmışsa, fix et önce.
7. Her version sonunda `swift build` ve `swift test` (veya xcodebuild test) yeşil olmalı.
8. Bir version içinde sıkışırsan (tool yok, asset eksik, vs.) → blocker dosyası (`BLOCKERS.md`) oluştur, içine yazz, sonraki version'a geç. Asla sessizce takılma.
9. **iOS App target** için: Swift Package yerine bu sefer bir Xcode App projesi oluşturulmalı. Mevcut `SnugloEngine` Swift package'ı, app target'ın local dependency'si olarak link'lenmeli.

---

## v0.2 — Core UI

**Hedef:** iPhone simülatöründe açılınca tek bir level'ı oynayabileceğin SwiftUI ekranı.

**Yapılacaklar:**
- `SnugloApp/` klasörü altında Xcode iOS App projesi oluştur (xcodegen kullan; yoksa kur).
- `SnugloApp/project.yml` (xcodegen config) hazırla: bundle id `com.felabs.snuglo`, iOS 17+, SwiftUI.
- App target → local `SnugloEngine` Swift Package'ı dependency olarak ekle.
- Klasör yapısı (spec §9):
  ```
  SnugloApp/
    App/SnugloApp.swift
    Features/Game/{GameView, GridView, BlockView, GameViewModel}.swift
    Core/Theme/{Colors, Typography, Spacing}.swift
  ```
- `GameView`: tek bir level (Levels/level_5x5.json) yükler, grid çizer, blockları tray'den çekip yerleştirir.
- Drag-drop: SwiftUI gesture + snap-to-grid (±15pt tolerans).
- Çakışma/sınır ihlali: blok kırmızı kenarlık + ease-back animasyon.
- Tüm bloklar yerleşince: console'a "Solved!" yaz (next phase Level Complete'i ekleyecek).
- Theme: spec §7 renklerini Colors.swift'e gömle.
- **Test:** Snapshot test veya unit test (UI logic için ViewModel testleri).
- **Çıktı kontrolü:** `xcodebuild -scheme SnugloApp -destination 'platform=iOS Simulator,name=iPhone 16' build` başarılı dönmeli.

**Branch:** `feature/v0.2-core-ui`
**CHANGELOG:** "v0.2 — Core UI ekranı (tek level oynanabilir)"

---

## v0.3 — Flow

**Hedef:** Onboarding + Main Menu + Level Select + Level Complete ekranları.

**Yapılacaklar:**
- `Features/Onboarding/` — 3 ekranlı swipe-paged onboarding (spec §16 mikrokopisi).
- `Features/MainMenu/` — Daily Puzzle kartı, Continue, Levels button, alt tab bar.
- `Features/LevelSelect/` — Pack list + Pack detail (3 col grid).
- `Features/Game/LevelCompleteSheet.swift` — bottom sheet, stars, next/replay/home buttons.
- NavigationStack ile flow bağla: Splash → (Onboarding) → MainMenu → LevelSelect → Game → LevelComplete.
- `AppState` (Observable) — onboarding flag, current level pointer.
- Onboarding sadece ilk açılışta gösterilsin (UserDefaults flag).

**Branch:** `feature/v0.3-flow`
**CHANGELOG:** "v0.3 — Full ekran akışı: onboarding, main menu, level select, level complete"

---

## v0.4 — Content

> **Not (v1.0 plan):** Toplam 240 level (4 pack × 60). Pack adları: Cozy Beginnings (5×5) → Spice Route (6×6) → Mambo Nights (7×7) → Woodland Retreat (8×8). Faz D'de güncelleniyor. Aşağıdaki plan eskidir (30/pack) — Faz D'de 60/pack'e revize edilecektir.

**Hedef:** 120 oynanabilir seviye (4 pack × 30).

**Yapılacaklar:**
- `Tools/LevelGenerator/` — Swift executable. Grid'i recursive olarak dikdörtgenlere bölen procedural generator.
  - Input: grid size, target piece count range.
  - Output: Level JSON (spec §6 formatına uygun).
  - Validation: tek çözüm garantisi (basit solver ile doğrula).
- Generator'ı çalıştır → 4 pack × 30 = 120 level JSON üret:
  - Pack 1 "Cozy Beginnings" — 5×5, kolay, 30 level.
  - Pack 2 "Spice Route" — 6×6, orta-kolay, 30 level.
  - Pack 3 "Mambo Nights" — 7×7, orta-zor, 30 level.
  - Pack 4 "Crystal Garden" — 8×8, zor, 30 level.
- `Resources/Levels/` altında pack klasörleriyle organize et.
- `LevelLoader.swift`'i pack-aware yap (`loadPack(id)` → [Level]).
- Pack metadata JSON: `pack_manifest.json` (her pack için isim, level sayısı, gold/silver time thresholds).
- **Test:** Tüm 120 seviyenin solver tarafından çözülebildiğini doğrulayan test.

**Branch:** `feature/v0.4-content`
**CHANGELOG:** "v0.4 — 120 level (4 pack), procedural generator + uniqueness validator"

---

## v0.5 — Polish

**Hedef:** Hissi yumuşat — animasyon, ses, haptik, settings.

**Yapılacaklar:**
- Animasyonlar (spec §7): spring curves, pick-up, drop-snap, level complete confetti.
- Haptik: `UIImpactFeedbackGenerator` ile (pickup, snap valid, invalid, level complete) — spec §8.
- **Ses (placeholder ile):** `Resources/Sounds/` klasörü + 6 boş .wav placeholder. `BLOCKERS.md`'ye "Asset upload gerekli: pickup.wav, tock.wav, thud.wav, complete.wav, shimmer.wav, click.wav" yaz. `SoundService.swift` placeholder'ları çalsın (sessiz olur, sorun değil).
- `Features/Settings/SettingsView.swift`:
  - SFX toggle, Music toggle, Haptics toggle, Theme picker, Notification time, Colorblind mode, Restore Purchases (placeholder).
  - `UserDefaults`-backed `SettingsStore`.
- Reduce Motion accessibility — animasyonları kısalt.

**Branch:** `feature/v0.5-polish`
**CHANGELOG:** "v0.5 — Animasyon, haptik, ses servisi (placeholder), Settings ekranı"
**BLOCKERS:** Asset upload (ses dosyaları).

---

## v0.6 — Daily + Stats

**Hedef:** Günün puzzle'ı + stats ekranı + streak.

**Yapılacaklar:**
- `Features/DailyPuzzle/DailyPuzzleService.swift` — `seed = YYYYMMDD` → procedural generator çağırarak günün seviyesini üret. Aynı gün aynı sonuç.
- `Features/Stats/StatsView.swift`:
  - Toplam çözülen, toplam süre, best time, streak, avg solve time, hint usage %.
  - Swift Charts kullan (haftalık/aylık).
- `PersistenceService.swift` — SwiftData veya Core Data:
  - `LevelCompletion(levelId, stars, bestTime, hintsUsed, date)`
  - `UserProgress(totalCompleted, currentLevelPointer, hintCount, streak, lastOpenedDate)`
- Streak mantığı: günün daily puzzle'ı tamamlandığında +1, gün atlandığında 0'a iner.
- Stats canlı (her level complete'te güncellenir).

**Branch:** `feature/v0.6-daily-stats`
**CHANGELOG:** "v0.6 — Günün puzzle'ı (deterministic seed), stats ekranı, streak sistemi"

---

## v0.7 — Monetization

**Hedef:** IAP iskeleti — StoreKit 2.

**Yapılacaklar:**
- `Core/Services/IAPService.swift` — StoreKit 2 entegrasyonu:
  - Product IDs: `com.felabs.snuglo.hints.5`, `hints.25`, `hints.unlimited`, `removeAds`, `plus.monthly`, `plus.yearly`.
  - Purchase, restore, listen for transaction updates.
- `Features/Shop/ShopView.swift` — Product list + purchase buttons.
- Hint sistemi entegrasyonu: hint count'u IAPService'ten okusun.
- `Configuration.storekit` test config dosyası (Xcode StoreKit Testing).
- **Note (BLOCKERS):** Gerçek IAP'lar App Store Connect'te kaydedilmeli. Bu code-side iskelet, ürünler senin tarafında oluşturulmalı.

**Branch:** `feature/v0.7-monetization`
**CHANGELOG:** "v0.7 — StoreKit 2 IAP iskeleti, Shop ekranı, hint count entegrasyonu"
**BLOCKERS:** App Store Connect'te IAP ürünleri tanımlanmalı (kullanıcı).

---

## v0.8 — Analytics

**Hedef:** Event tracking.

**Yapılacaklar:**
- `Core/Services/AnalyticsService.swift` — protocol tabanlı (provider değiştirebilir).
- TelemetryDeck SDK ekle (privacy-first, ücretsiz tier var).
- Spec §12'deki tüm event'leri implement et: app_open, level_start, level_complete, hint_used, iap_*, ad_shown, daily_puzzle_played, streak_updated, settings_changed.
- **Note:** TelemetryDeck App ID placeholder bırak — user kendi hesabını açıp ekleyecek.

**Branch:** `feature/v0.8-analytics`
**CHANGELOG:** "v0.8 — TelemetryDeck entegrasyonu, event tracking"
**BLOCKERS:** TelemetryDeck hesabı + App ID (kullanıcı).

---

## v0.9 — Localization + Accessibility

**Hedef:** TR/EN/ES + VoiceOver.

**Yapılacaklar:**
- `Localizable.strings` (EN base + TR + ES). Tüm hardcoded string'leri replace et.
- Onboarding, settings, level complete, shop — hepsi localized.
- VoiceOver: her block için label (`"Purple block, 5 cells"`), grid için label.
- Dynamic Type scaling (font sizes spec §7'deki sistem font kullanılıyorsa otomatik).
- Reduce Motion: animasyon durations'ı 0'a yaklaştır.
- Colorblind mode: bloklara pattern overlay (Settings'te aç/kapat).

**Branch:** `feature/v0.9-i18n-a11y`
**CHANGELOG:** "v0.9 — 3 dil (EN/TR/ES), VoiceOver, Dynamic Type, Reduce Motion, Colorblind mode"

---

## v1.0 — Launch Prep

**Hedef:** App Store submission'a hazırlık. (Submission'ın kendisi manuel.)

**Yapılacaklar (AGENT'LARIN YAPACAĞI):**
- App icon: SwiftUI'da çizilmiş bir vektör icon → 1024×1024 PNG export script'i.
- `Resources/AppIcon.appiconset/` — tüm boyutları script'le üret.
- Screenshot generation: `xcrun simctl` kullanan bir script (6.7", 6.5", 5.5"). Test verisiyle 5 screenshot çek (hero, game, daily, packs, complete).
- App Store metadata draft'ı: `APPSTORE_METADATA.md`:
  - App name, subtitle, keywords (spec §17)
  - Description (4000 char) — agent yazsın
  - Promotional text
  - What's New (v1.0 için).
- Privacy Policy ve Terms of Service draft'ları → `legal/` klasörüne MD olarak yaz.
- Build configuration: Release scheme, dSYM, bitcode off, App Sandbox doğru ayarlanmış.
- `pre-submission-checklist.md` oluştur: imzalama, provisioning, IAP review, screenshot upload, TestFlight beta.

**Branch:** `feature/v1.0-launch-prep`
**CHANGELOG:** "v1.0 — Launch hazırlığı: icon, screenshot script, metadata, legal draft'ları, submission checklist"

**MANUEL ADIMLAR (KULLANICI YAPACAK):**
- Apple Developer Program kaydı + sertifika
- App Store Connect'te app kaydı + provisioning profile
- IAP ürünleri ekleme (v0.7'deki product ID'lerle)
- TestFlight beta dağıtımı
- App Store Review'a submission
- Privacy & Terms hosting (web sitesi gerekli)

---

## Bitiş Kriteri

Tüm version'lar tamamlandığında:
- `git log main --oneline` → en az 9 merge commit (v0.2 → v1.0)
- `xcodebuild test -scheme SnugloApp` → tüm testler yeşil
- iPhone simülatöründe app açılıyor, daily puzzle oynanabiliyor, level select çalışıyor, settings/shop/stats görünür
- `CHANGELOG.md`, `BLOCKERS.md`, `APPSTORE_METADATA.md`, `pre-submission-checklist.md` workspace'te
- Main agent toplam özet raporu yaz (`COMPLETION_REPORT.md`): ne yapıldı, ne yapılmadı, kullanıcının yapması gereken adımlar.
