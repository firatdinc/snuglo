# Snuglo — Resume & Finish Prompt

> Bu prompt'u Snuglo projesi seçili iken **Main** agent'a (chat input'a) yapıştır. Tek seferde çalıştır.

---

## Snuglo'yu v1.0'a kadar bitir (resume)

### Bağlam ve neden duraksadık

- Önceki oturum **internet bağlantısı koptuğu için** kesildi — mantık/logic hatası değil. Top bar'daki "4 kesintiyi devam ettir" butonundaki task'lar **geçerli işlerdir**, devam ettir.
- 6 adet `failed` task var (çoğu `Fix BLOCKERs`, `manuel code review (reviewer proxy)`, `EXECUTION_PLAN doğrula`). Bunları gözden geçir; gerçek bir mantık hatası varsa yeniden plan kur, aksi takdirde retry et.
- Hedef: tek seferde **Snuglo iOS uygulamasını v1.0 ship-ready** duruma getirmek. Aşağıdaki Definition of Done karşılanana kadar **durma**.

### Yeni gerçek: Stitch tasarımları artık workspace'te

Bu oturumda Stitch'ten 11 ekran (HTML + PNG) bu projeye aktarıldı. **Önce şu dosyayı oku, design system'i ve ekran akışını içselleştir, sonra yola çık:**

- `Designs/INDEX.md` — design system token'ları (Nordic Hearth), ekran-ekran manifest, oyun mekaniği netleştirmesi
- `Designs/html/01-splash.html` … `Designs/html/11-settings.html` — Her ekranın HTML mockup'ı (token isimleri, ölçüler, hiyerarşi gerçekçi)
- `Designs/screenshots/01-splash.png` … `Designs/screenshots/11-settings.png` — Görsel referans (her ekran için 1 PNG)

**Tasarımlar bağlayıcıdır:** Spec'teki coral/cream renk paleti **artık geçerli değil** — Nordic Hearth (lavender CTA `#65587A`, kağıt-beyazı surface `#FDF8FB`, soft pastel block fills) bağlayıcı yeni paletdir. `SnugloApp/Core/Theme/Colors.swift` dahil tüm tema dosyalarını Nordic Hearth'a göre yenile. SNUGLO_SPEC.md'yi de tutarlı şekilde **v0.2 design update** olarak güncelle (eski paleti silmek yerine "superseded by Nordic Hearth" notu ekle).

### Önemli içerik güncellemeleri (Stitch'ten çıkan)

- **Toplam 240 level** (önceki 120 değil). Main Menu'de "Level 12 / 240" pill'i bunu doğruluyor. Pack yapısını PLAN_v0.2.md'de gözden geçir. Pratik öneri: **4 pack × 60 level**. Pack adları (kanonik): **Cozy Beginnings** (5×5, 60 level) → **Spice Route** (6×6, 60) → **Mambo Nights** (7×7, 60) → **Woodland Retreat** (8×8, 60).
- **Bloklarda sayısal etiket var** (1/2/3/…) — hücre sayısı kadar. Bu hem accessibility (color-blind) hem mekanik bilgi. `Piece` modeline `displayLabel` (computed: cells.count) ekle ve `BlockView`'da göster.
- **Timer count-up'tır** (level başlangıcından itibaren artar). Pause'da donar.
- **3 yıldız sistemi**: süre + hint kullanımı kombine. Reference: `Designs/screenshots/08-level-complete.png` (hints=0, süre=02:45 → 3 yıldız).
- **Daily Puzzle**: gün başına 1 deterministik puzzle, gece yarısı sıfırlanır. Main Menu'de geri sayım gösterilir.
- **Streak**: ardışık günlerde daily puzzle çözme.
- **Tab bar**: PLAY / LEVELS / STATS / SHOP (4 sekme).
- **Settings ekranı**: Music / Sound effects / Haptics toggle + Theme picker (System/Light/Dark) + Daily Reminder (time picker) + Restore Purchases + Privacy + Terms. Footer'da version (`SNUGLO V1.0.4` formatı).
- **Shop ekranı**: Snuglo Plus subscription ($4.99/ay), Hints pack'leri (5 @ $0.99, 25 @ $2.99 "POPULAR", Unlimited), Remove Ads ($3.99 one-time).

### Adım adım yürüt (faz planı)

Her fazda PM agent'ı plan kurar, doğrudan koderlere `delegate_task` ile dağıt. Her faz sonunda **Reviewer** kontrol eder, BLOCKER varsa `request_fix` ile orijinal coder'a fix task'ı açtırır.

**Faz A — Stabilize & Resume (öncelik)**
1. "4 kesintiyi devam ettir" task'larını yeniden başlat (manuel resume).
2. 6 `failed` task'ı tek tek incele; logic hatası varsa düzelt, ağ kesintisi/araç hatası ise retry.
3. `swift build` + `swift test` (Sources/SnugloEngine) + `xcodebuild -scheme SnugloApp -destination 'platform=iOS Simulator,name=iPhone 16' build` — hepsi yeşil olana kadar fix.

**Faz B — Tema upgrade (Nordic Hearth)**
1. `SnugloApp/Core/Theme/Colors.swift`, `Typography.swift`, `Spacing.swift` — `Designs/INDEX.md` token'larına göre yeniden yaz.
2. Yeni token'lar: `primaryContainer`, `surfaceContainerLow/High/Highest`, `outlineVariant`, `shadowAmbient`, `blockRadius` (10), `cardRadius` (20), `buttonRadius` (14), pastel block fills.
3. Mevcut `GameView` / `GridView` / `BlockView`'ı yeni tema ile güncelle. Eski coral/cream paleti yokmuş gibi davran.
4. `Piece` modeline `cellCount` computed property + `BlockView`'da rakam göster (Space Grotesk → SF Mono, weight 500).

**Faz C — Navigation iskelesi**
1. `SnugloApp/Features/Navigation/RootView.swift` — tab bar (PLAY / LEVELS / STATS / SHOP). `Designs/html/03-main-menu.html` bottom tab bar'ını referans al.
2. `SplashView` (1.2 s simüle), `OnboardingView` (3 sayfa, page indicator, "Skip"), `MainMenuView`, `LevelsListView`, `PackDetailView`, `StatsView`, `ShopView`, `SettingsView`, `PauseOverlayView`, `LevelCompleteSheet`.
3. Her ekran ilgili `Designs/html/*.html` ile pixel-yakın olmalı (renkler, radius, spacing, hiyerarşi). HTML'i Read et, token isimlerini bul, SwiftUI'a çevir.
4. `@Observable AppRouter` — basit state-based navigation; NavigationStack üstüne kur.

**Faz D — Content (240 level)**
1. `Sources/SnugloEngine/LevelGenerator.swift` — deterministic procedural generator (seed → level). Algoritma: random rectangle partitioning + solver doğrulaması (her level **tek geçerli çözüme yakın** olmalı; çok-çözümlü kabul, çözümsüz yasak).
2. 60×4 = 240 level üret. Her pack zorluk eğrisi: difficulty 1→10 within pack. Build-time'da JSON resources üret (Resources/Levels/cozy-01.json … woodland-60.json).
3. Daily Puzzle: `DailyPuzzleSeeder` — `YYYY-MM-DD` → seed → tek level. Tüm cihazlarda aynı sonuç versin (deterministic).
4. Engine testleri: her üretilen level için `SolutionChecker` ile en az 1 çözümün varlığı assert.

**Faz E — Persistence & Stats**
1. `Core/Persistence/StatsStore.swift` — `UserDefaults` + JSON. Schema: solved count, total time, fastest, current streak, last daily date, per-pack progress, hints remaining, settings (sound/music/haptics/reminder time/theme).
2. `Core/Persistence/MigrationV1.swift` — v0.x'ten varsa eski state'i taşı.
3. `StatsView` — `Designs/screenshots/09-stats.png`'deki 2×2 KPI + haftalık bar chart + donut. SwiftUI `Chart` (iOS 17 Charts framework) kullan.

**Faz F — Ses, Haptik, Bildirim**
1. `Core/Services/SoundService.swift` — `AVAudioPlayer`. Asset'ler: `click.caf`, `place.caf`, `snap.caf`, `solve.caf`, `error.caf`. Settings toggle'larıyla bağla.
2. `Core/Services/HapticService.swift` — `UIImpactFeedbackGenerator` (place=light, snap=medium, solve=success, error=error).
3. `Core/Services/NotificationService.swift` — daily reminder local push (`UNUserNotificationCenter`). Settings → Reminder Time picker bağla.

**Faz G — Monetization**
1. `Core/Services/StoreService.swift` — StoreKit 2 (`Product`, `Transaction`, `Purchase`). 4 SKU:
   - `com.felabs.snuglo.plus.monthly` (subscription, $4.99/ay)
   - `com.felabs.snuglo.hints5` ($0.99)
   - `com.felabs.snuglo.hints25` ($2.99)
   - `com.felabs.snuglo.hintsUnlimited` ($9.99)
   - `com.felabs.snuglo.removeAds` ($3.99)
2. `ShopView` — `Designs/html/10-shop.html` ile birebir.
3. Receipt validation + restore purchases (Settings'tan).
4. Ad SDK (Google Mobile Ads) sadece Premium değil ve Remove Ads alınmamış kullanıcılara — interstitial level complete sonrası, frequency cap 1/3 level.

**Faz H — Accessibility, Lokalizasyon, Polish**
1. VoiceOver: her piece için `accessibilityLabel` (renk + sayı), her ekran için landmark, board için "Game grid, 6 by 6, 4 pieces placed."
2. Dynamic Type: tüm metinler `Font.system` scaled.
3. Color-blind mode: settings toggle → pieces üzerindeki rakamı zorla göster + yüksek-kontrast paleti.
4. Lokalizasyon: TR / EN / ES. `Localizable.strings` üç dilde. SwiftGen veya manuel `String(localized:)`.
5. App icon: `Designs/screenshots/01-splash.png`'deki 4×4 pastel block logosunu temel al — 1024×1024 master + tüm boyutlar (`Assets.xcassets/AppIcon.appiconset`). Designer agent üretsin (SVG/PNG).
6. Launch screen: splash ekranıyla aynı.
7. Light/Dark theme: Nordic Hearth dark variant — agent tasarlayıp Colors.swift'e ekleyecek.

**Faz I — Quality Gate (release candidate)**
1. Tüm unit testler yeşil.
2. UI test (XCUITest): happy path (boot → onboard → play 5×5 level → complete → back to menu).
3. `xcodebuild test` simulator'da geçmeli.
4. SwiftLint çalıştır (kurulu değilse `Package.swift`'e plugin ekle), 0 warning.
5. Manual checklist: 10 random level oynanabilir, daily puzzle aynı seed ile aynı puzzle veriyor, IAP sandbox satın alma testi.

**Faz J — Release artifacts**
1. `RELEASE_NOTES_v1.0.md` — özellik listesi, ekran görüntüleri, marketing copy.
2. `README.md` (proje root) — boilerplate'i sil, gerçek README yaz: ne yapar, nasıl build edilir, mimari özet, dosya haritası.
3. `CHANGELOG.md` — v1.0 entry'si.
4. `BLOCKERS.md` — sıfırla; v1.0 sonrası backlog için yeniden oluştur.
5. `App Store Connect` için copy hazırla: `marketing/store-listing-tr.md`, `marketing/store-listing-en.md` (başlık, alt başlık, açıklama, anahtar kelimeler).
6. Git: bu workspace **local-only** — `origin` remote yok, `git push` ÇALIŞTIRMA. Her faz sonunda `git commit` (anlamlı mesajla); feature branch'leri main'e `git merge --no-ff` ile birleştir. v1.0 sonunda `git tag v1.0.0` (annotated) at, tag'i `git show v1.0.0` ile doğrula. Commit ve tag local'de kalsın.

### Çalışma kuralları

- **Durma yetkisi sadece sende.** Bir task fail olursa: nedenini öğren, fix task'ı aç, devam et. **"Tamam, hazır" deyip durma** — Faz J tamam olana kadar yeni task üretmeye devam et.
- Her faz başında **PM** ile faz planını netleştir, sonra koderlere `delegate_task` et.
- Her PR/branch sonrası **Reviewer** kontrolü zorunlu (mevcut request_fix akışını kullan).
- HTML mockup'ları yorumlarken: token isimlerini birebir kopyalama (Tailwind sınıfları → SwiftUI modifier'ları). Renkleri **hex değerinden** al, isimden değil.
- HTML'de görmediğin bir mikro etkileşim varsa (örn. blok yerleştirirken "thud" hissi) **inisiyatif al** ve Nordic Hearth ruhuna uygun (gentle, tactile) tasarla.
- Performans: `Canvas`/`Path` ile çizilen grid'lerde 60 fps zorunlu. iPhone SE'de stutter yoksa ok.
- Build/test komutlarını her major change'den sonra otomatik çalıştır. Komut: `swift test` (engine için) + `xcodebuild test -scheme SnugloApp -destination 'platform=iOS Simulator,name=iPhone 16'` (app için).

### Definition of Done (v1.0)

Aşağıdakilerin **hepsi** sağlandığında dur:

- [ ] `swift build`, `swift test`, `xcodebuild build`, `xcodebuild test` — hepsi yeşil
- [ ] 11 ekran (Splash, Onboarding x3 sayfa, Main Menu, Levels List, Pack Detail, Game Play, Pause, Level Complete, Stats, Shop, Settings) implement edildi ve mockup'larla görsel olarak eşleşiyor
- [ ] 240 level (4 pack × 60) üretilmiş, JSON resources'da bundle edilmiş, hepsi solver ile doğrulanmış
- [ ] Daily Puzzle çalışıyor, deterministic, midnight refresh
- [ ] Streak + stats KPI'ları doğru hesaplanıyor
- [ ] Ses, haptik, daily reminder bildirimi entegre — settings toggle'larıyla bağlı
- [ ] StoreKit 2 ile 5 SKU tanımlı, restore purchases çalışıyor (sandbox test geçti)
- [ ] Light + Dark tema, en az 2 dil (TR + EN), VoiceOver labels
- [ ] App icon + launch screen production-grade asset olarak hazır
- [ ] CHANGELOG, README, RELEASE_NOTES güncellendi; BLOCKERS sıfırlandı
- [ ] `main` branch'inde final commit atıldı (local-only, push YOK); annotated tag `v1.0.0` oluşturuldu ve `git show v1.0.0` ile doğrulandı

Şimdi başla. İlk yapacağın iş: `Designs/INDEX.md` ve `Designs/screenshots/03-main-menu.png`'i oku, sonra "4 kesintiyi devam ettir" task'larının state'ini öğren ve Faz A'yı kuyruğa al.
