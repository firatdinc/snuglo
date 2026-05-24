# Changelog

Tüm önemli değişiklikler bu dosyada belgelenir.
Format: [Keep a Changelog](https://keepachangelog.com/tr/1.0.0/), Semantic Versioning.

---

## v0.2 — Core UI (2026-05-24)

### Eklendi
- `SnugloApp/` iOS uygulama target'ı (xcodegen 2.45.3)
- `project.yml` xcodegen manifest — bundle id `com.felabs.snuglo`, iOS 17+
- `@main SnugloApp` + `WindowGroup → GameView`
- `GameViewModel` (`@Observable`) — LevelLoader entegrasyonu, parça yerleştirme/kaldırma, SolutionChecker ile çözüm tespiti
- `GameView` — SwiftUI ekran, DragGesture drag-drop, snap-to-grid (±15pt tolerans), floating piece overlay, solved overlay
- `GridView` — Canvas ile 5×5 grid (cream arka plan, grid çizgileri), placed BlockView'lar, tap-to-pickup
- `BlockView` — Parça görsel temsili (tray + grid), geçersiz yerleşim kırmızı kenarlık animasyonu, drag scale efekti
- `Core/Theme/Colors.swift` — Spec §7 renk paleti (coral, cream, 6 blok rengi, error/success)
- `Core/Theme/Typography.swift` — SF Rounded/Mono/Pro font factory'leri
- `Core/Theme/Spacing.swift` — 4dp ızgara, kart/düğme/blok yarıçapları
- `SnugloAppTests/GameViewModelTests.swift` — 3 unit test (load, place, solved)
- `PLAN_v0.2.md` — v0.2 mimari kararlar ve tasarım dokümantasyonu

### Teknik Notlar
- Engine (v0.1) değişmedi; local SPM dep olarak `path: ..` ile link'lendi
- SnugloEngine swift test: 19/19 ✓
- SnugloAppTests: 3/3 ✓
- xcodebuild iPhone 15 simulator: BUILD SUCCEEDED

---

## v0.1 — Engine (2026-05-24)

### Eklendi
- `SnugloEngine` Swift Package (SPM)
- `Level`, `Piece`, `Coord`, `Placement`, `PlacementResult` modelleri
- `LevelLoader` — bundle JSON yükleme, 3 hata türü (notFound/readFailed/decodingFailed)
- `SolutionChecker` — fail-fast doğrulama (6 kontrol: emptyGrid/boş/unknownPiece/outOfBounds/overlap/incompleteCoverage)
- Level JSON'ları: `level_5x5.json`, `level_6x6.json`, `level_7x7.json`
- `SnugloEngineTests` — 19 XCTest (sanity + edge-case)
