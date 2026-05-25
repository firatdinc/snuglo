# Blockers

Bu dosya, agent'ların takıldığı veya ilerideki version'lara bırakılan maddeler içerir.

---

## Faz A fix2 — IOS-16 (2026-05-25) ✅ KAPANDI

Reviewer task `pBQzr92rXgbgYn9VSddjy` — tüm bulgular kapatıldı:

| # | Bulgu | Fix | Sonuç |
|---|-------|-----|-------|
| 1 | `PBXResourcesBuildPhase` içinde `xcodeproj` referansı | `project.yml` `*.xcodeproj` exclude + `xcodegen generate` | pbxproj temiz ✅ |
| 2 | `onGeometryChange` iOS 18+ / deployment target 17.0 | `IPHONEOS_DEPLOYMENT_TARGET = 18.0` tüm config | 6 config × 18.0 ✅ |
| 3 | SnapCalculator buffer bug (test regresyonu) | guard `pos.x/y` tabanlı — parça boyutundan bağımsız | 8/8 test ✅ |

**xcodebuild build ✅ — TEST SUCCEEDED (8 test, 0 failure) ✅**

---

## v0.2 — Core UI

### [BLOCKER-01] App icon ve launch image placeholder
- **Durum:** Eksik — xcodegen `INFOPLIST_KEY_UILaunchScreen_Generation: YES` ile boş launch screen oluşturuldu (beyaz).
- **Etki:** App Store submission için 1024×1024 app icon gereklidir; v1.0 öncesi tamamlanmalı.
- **Planlanan:** v1.0 — `Resources/AppIcon.appiconset/` SwiftUI vektör icon + export script.
- **Aksiyon (kullanıcı):** v1.0 branch'ine kadar beklenebilir; erken test için asset katalog manuel oluşturulabilir.

### [BLOCKER-02] Parça renk field'ı engine'de yok
- **Durum:** `Piece` modeli `color` field'ı içermiyor (v0.1 kasıtlı tasarım).
- **Etki:** v0.2'de renk, `level.pieces` dizin tabanlı atanıyor (`colorKeys[index % 6]`).
- **Planlanan:** v0.4 level generator'ında parça renklerini level JSON'a eklemeyi değerlendirin, VEYA UI katmanında index-tabanlı atama yeterli kabul edilirse ilerideki version'larda da devam edilebilir.

---

## Gelecek Version'lar (placeholder)

### [BLOCKER-03] Ses dosyaları — v0.5'te gerekli
- `pickup.wav`, `tock.wav`, `thud.wav`, `complete.wav`, `shimmer.wav`, `click.wav`
- `SoundService.swift` placeholder'larla şimdilik sessiz çalışacak.

### [BLOCKER-04] App Store Connect IAP ürünleri — v0.7'de gerekli
- Product ID'leri kod tarafında tanımlanacak; ASC'de kullanıcı tarafından oluşturulmalı.

### [BLOCKER-05] TelemetryDeck App ID — v0.8'de gerekli
- Kullanıcının kendi TelemetryDeck hesabını açıp App ID eklemesi gerekecek.

---

## v1.0-B — Nordic Hearth Theme (Faz B)

### [BLOCKER-06] Dark mode renk token'ları — Faz H'de tamamlanacak
- **Durum:** Faz B'de yalnızca light theme tanımlandı. `AppColors` içinde dark variant yok.
- **Etki:** Dark Mode sistemi açık olduğunda uygulama light renklerle kalır (görsel uyumsuzluk).
- **Planlanan:** Faz H — `Colors.swift`'e `Color(light:, dark:)` çiftleri eklenecek VEYA
  Asset Catalog renk kümesi kullanılacak. Her token için dark hex değeri INDEX.md dark theming
  bölümünde tanımlanmalı (henüz yok).
- **Geçici çözüm:** Uygulama `light` appearance'ı zorla tutabilir
  (`UIApplication.shared.keyWindow?.overrideUserInterfaceStyle = .light` — Faz H'e kadar).

### [BLOCKER-07] Custom font bundle dosyaları — Faz H'de tamamlanacak
- **Durum:** Faz B'de sistem-font fallback'ler kullanıldı (SF Rounded / SF Pro / SF Mono).
  Plus Jakarta Sans, Be Vietnam Pro, Space Grotesk bundle'a eklenmedi.
- **Etki:** Tasarım görsel olarak yakın ama birebir eşleşmiyor.
- **Planlanan:** Faz H — `.ttf` / `.otf` dosyaları `SnugloApp/Resources/Fonts/` altına eklenecek,
  `Info.plist`'e `UIAppFonts` array kaydedilecek, `Typography.swift` güncellenecek.
- **Not:** `Typography.swift` başında sistem-font fallback notu ve TODOlar zaten mevcut.
