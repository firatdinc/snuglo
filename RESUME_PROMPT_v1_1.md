# Snuglo v1.1 — Stitch Visual Upgrade

> Bu prompt'u Snuglo projesi seçili iken **Main** agent'a yapıştır. Tek seferde başlat.

---

## Hedef

v1.0.1 ship-ready halde tag'lendi (240 level, daily puzzle, IAP, accessibility, 3 dil). v1.1 sadece **görsel kimlik** upgrade'i:

- Stitch'teki Nordic Hearth tasarımıyla **birebir** görsel eşleşme
- Custom font'lar (Plus Jakarta Sans / Be Vietnam Pro / Space Grotesk) ekranlara gerçekten uygulansın
- Tüm 11 ekran reusable component'leri (PrimaryButton / SecondaryButton / CardSurface / RowDivider) kullansın
- Hiçbir mevcut özelliği bozma — sadece görsel/component refactor

## Önce mutlaka oku

Sırasıyla bu dosyaları aç ve içselleştir. **Atlama, fragment okuma.** Her ekran refactor'unda referans alacaksın:

1. `Designs/INDEX.md` — Nordic Hearth design system + 11 ekranın manifesti + game mechanic doğrulaması
2. `Designs/html/01-splash.html` → `Designs/html/11-settings.html` — her ekranın HTML mockup'ı (kanonik hex renkler + spacing + hiyerarşi BURADA)
3. `Designs/screenshots/01-splash.png` → `Designs/screenshots/11-settings.png` — görsel referans (PNG'leri Read tool ile aç, Claude direkt görür)
4. `PLAN_v1.1.md` — v1.1 refactor planı (varsa, IOS-53'ten geldi)
5. `CHANGELOG.md` — son commit'ler v1.1'de neyin yapıldığını anlatır

## Şu anki durum (IOS-53 branch'inden main'e merge edildi)

Main artık şunları içeriyor:
- ✅ 4 font dosyası `SnugloApp/Resources/Fonts/` altında + Info.plist `UIAppFonts` kaydı
- ✅ 4 reusable component `SnugloApp/Core/Components/` altında (PrimaryButton, SecondaryButton, CardSurface, RowDivider)
- ✅ `SnugloApp/Core/Theme/Colors.swift` + `Typography.swift` Stitch token'larına align edildi
- ✅ `Tests/SnugloAppTests/StitchTokenTests.swift` — token uyumunu test eder
- 🟡 11 ekranın **bir kısmı** yeni component'lere refactor edildi — hangileri tam bilmiyoruz, kontrol gerek

## v1.1 zorunlu kuralları

### 1. Stitch design BAĞLAYICI

Her ekran refactor'una başlamadan ÖNCE şunu yap:
- `Designs/html/<NN-screen-name>.html` dosyasını Read et — hex renkleri, spacing piksellerini, hiyerarşiyi oradan al
- `Designs/screenshots/<NN-screen-name>.png` dosyasını Read et — Claude görsel olarak karşılaştırır
- Sonra Swift dosyasını edit et

**Yaklaşık değer kullanma:** "Aşağı yukarı pembe", "yumuşak gri" gibi yorumlar yasak. Hex değerleri Designs/INDEX.md veya HTML'den birebir al.

### 2. Custom font'ları FİİLEN kullan

Şu an Typography.swift `.system(size:, weight:, design: .rounded)` kullanıyor olabilir. Custom font'lar bundle'a eklendi ve Info.plist'te kayıtlı — **SwiftUI'da gerçekten çağrılmalı**:

```swift
Font.custom("PlusJakartaSans-Regular", size: 28)
Font.custom("BeVietnamPro-Regular", size: 17)
Font.custom("SpaceGrotesk-Regular", size: 20)
```

Typography.swift'i bu pattern'le güncelle. Eski `.system` kalmamalı (test/preview hariç).

### 3. Reusable component'leri ZORUNLU kullan

`SnugloApp/Core/Components/` altındakileri her uygun yerde çağır:
- Tüm primary CTA'lar → `PrimaryButton(...)`
- Tüm secondary action'lar → `SecondaryButton(...)`
- Tüm card surface'leri → `CardSurface { ... }`
- Tüm liste/row ayırıcıları → `RowDivider()`

Eğer ekranda hâlâ `Button { ... } .background(AppColors.primary) ...` gibi inline buton stili varsa, onu PrimaryButton'a çevir.

### 4. Hiçbir özelliği bozma

- Tüm unit testler **geçmeye devam etmeli** — özellikle `Tests/SnugloAppTests/` ve `Tests/SnugloEngineTests/`
- Mevcut behavior'lar (navigation, persistence, IAP, accessibility) korunmalı
- Eğer test silinmesi gerekiyorsa, **yerine yenisi yazılmalı** (regression riski sıfır)
- Refactor'un ortasında "geçici siliyorum" deme — her commit build + test geçmeli

### 5. Faz Planı

Phase 2 = v1.1 (Phase 1 = v1.0.x bitti).

**Faz K — Audit:** Şu an her 11 ekran için durumu raporla:
   - Hangi ekran tam refactor edildi (yeni token + font + component'ler kullanılıyor)?
   - Hangisi yarım?
   - Hangisi hiç dokunulmadı?
   Tek ekrana 1 row: `screen_name | status | gaps`

**Faz L — Ekran-ekran refactor:** Audit'te yarım/dokunulmamış olanları sırayla bitir. Her ekran için:
   1. `Designs/html/NN-foo.html` ve `Designs/screenshots/NN-foo.png` Read
   2. Mevcut Swift dosyasını Read
   3. Diff hesapla: hangi token/font/component değişimi gerek
   4. Edit
   5. `swift build` + `swift test` (etkilenen modüller)
   6. Reviewer'a yolla — HTML mockup ile karşılaştırsın
   7. BLOCKER varsa fix, yoksa next ekran

**Faz M — Visual smoke:** Tüm 11 ekran açılır mı, navigation çalışır mı? Bunu **iPhone 17 (iOS 26.3.1) simulator**'unda manuel olarak doğrula (xcodebuild test ile XCUITest yazma — sadece build + tap-test).

**Faz N — Wrap-up:** CHANGELOG v1.1.0 entry, BLOCKERS güncelle, `git tag -a v1.1.0 -m "..."` (annotated). Local-only push yok.

## Definition of Done (v1.1.0)

Aşağıdakilerin **hepsi** sağlandığında dur:

- [ ] 11 ekranın hepsi audit'te "tam refactor" işaretli (Designs/INDEX.md ile birebir)
- [ ] Typography.swift `.system` kullanmıyor (custom font'lar her yerde)
- [ ] Hiçbir ekranda inline buton stili yok — PrimaryButton/SecondaryButton kullanılıyor
- [ ] `Tests/SnugloAppTests/StitchTokenTests` geçer + diğer mevcut testler kırılmadı (`swift test` 0 fail)
- [ ] `xcodebuild build` temiz (iPhone 17 + iOS 26.3.1 destination)
- [ ] CHANGELOG.md v1.1.0 entry
- [ ] BLOCKERS.md güncel (v1.1 outstanding maddeler kapatıldı)
- [ ] `git tag v1.1.0` annotated tag atıldı (local)

## Çalışma kuralları (kritik — mac soğutmak için)

1. **Aynı anda max 2 mobile-dev** (orchestrator semaphore=2). Daha fazla paralel açmaya çalışma.
2. **xcodebuild test sadece tek hedefte:** `-destination 'platform=iOS Simulator,name=iPhone 17,OS=26.3.1' -parallel-testing-enabled NO`.
3. **Her test sonrası `xcrun simctl shutdown all`** (orchestrator zaten otomatik yapar).
4. **Yeni simulator device YARATMA** — Xcode default'larını kullan.
5. **Beta runtime indirme** (iOS 18 preview, vs.) — şu an iOS 17.5 + 26.3.1 mevcut, yeterli.
6. **iCloud Drive'i tetikleyecek dosya yaratma** — workspace `/Users/firatdinc/developer/agent-board-workspaces/snuglo--AnsD1` altında, iCloud sync edilmiyor. Buranın dışına dosya yazma.

## Git (local-only)

Bu workspace'te `origin` remote YOK. `git push` ÇALIŞTIRMA.
- Her anlamlı değişiklik sonrası `git commit`
- Feature branch'leri main'e `git merge --no-ff` ile birleştir
- v1.1.0 sonunda `git tag -a v1.1.0 -m "Snuglo v1.1.0 — Stitch visual upgrade"`
- Commit ve tag local kalsın

## Durma kuralı

Definition of Done'un TÜM maddeleri ✓ olana kadar yeni task üretmeye devam et. Bir task fail olursa nedeni öğren, fix task'ı aç, devam et. "Tamam, hazır" deyip bırakma.

İlk yapacağın iş:
1. `Designs/INDEX.md` ve `Designs/screenshots/03-main-menu.png`'i Read
2. Faz K (audit) için PM'e plan delege et
3. Sonra Faz L ekran-ekran refactor'a geç

Şimdi başla.
