# PLAN_v0.2 — Core UI

## Bağlam
v0.1 engine yeşil: 3 level JSON, LevelLoader, SolutionChecker, 18 XCTest ✓  
v0.2 hedefi: **iPhone simülatöründe açılınca tek level (level_5x5.json) oynanabilen SwiftUI ekranı.**

---

## Mimari Karar

| Katman | Konum | Sorumluluk |
|---|---|---|
| `app` | `SnugloApp/App/SnugloApp.swift` | `@main` giriş noktası |
| `features` | `SnugloApp/Features/Game/` | Oyun ekranı (GameView, GridView, BlockView, GameViewModel) |
| `core` | `SnugloApp/Core/Theme/` | Renk/tipografi/spacing token'ları |
| `engine` | `Sources/SnugloEngine/**` | **DONMUŞ** — v0.1'den değişmez |

## Stack
- Swift 5.9+, SwiftUI iOS 17+
- `@Observable` (Observation framework, iOS 17 native)
- xcodegen 2.45.3 → `SnugloApp.xcodeproj` üretir
- SnugloEngine local SPM dependency (`path: ..`)
- XCTest (unit) — GameViewModel state geçişleri

---

## Klasör Yapısı

```
SnugloApp/
├── project.yml               ← xcodegen manifest
├── App/
│   └── SnugloApp.swift       ← @main App + WindowGroup
├── Features/
│   └── Game/
│       ├── GameView.swift    ← ana ekran, drag orchestration
│       ├── GridView.swift    ← 5×5 grid + yerleşmiş bloklar
│       ├── BlockView.swift   ← tek parça görünümü
│       └── GameViewModel.swift ← @Observable, LevelLoader+SolutionChecker
└── Core/
    └── Theme/
        ├── Colors.swift      ← spec §7 renk token'ları
        ├── Typography.swift  ← SF Rounded/Mono/Pro helpers
        └── Spacing.swift     ← 4dp ızgara, yarıçaplar

SnugloAppTests/
└── GameViewModelTests.swift  ← 3 senaryo: load, place, solved
```

---

## Önemli Tasarım Kararları

1. **Drag-drop**: DragGesture `.coordinateSpace(.global)` + GridView PreferenceKey ile
   grid global çerçevesi yakalanır; bırakma noktasından hücre hesaplanır.
2. **Snap toleransı**: ±15pt (spec §2). Grid sınırları içine düşen bırakmalar snap eder.
3. **Geçersiz yerleşim**: `invalidPieceIds: Set<String>` → kırmızı kenarlık (600ms flash).
4. **Çözüm tespiti**: Tüm parçalar yerleşince SolutionChecker çalışır; `.valid` → `isSolved = true` + konsol "Solved!".
5. **Renk ataması**: Engine v0.1 Piece modelinde renk yok → index-tabanlı `colorKeys` dizisi.
6. **Cell boyutu**: `min(availableWidth / gridW, screenH * 0.33 / gridH)` — hem genişlik hem yükseklik kısıtı.
7. **Grid frame yakalama**: `.overlay(GeometryReader)` + `GridFramePreferenceKey` → drop hesaplaması.
8. **Placed block pick-up**: Grid'deki yerleşmiş bloğa tap → tray'e geri döner.

---

## Özellikler (v0.2 kapsamı)
- [x] level_5x5.json yükleme
- [x] 5×5 grid görünümü (cream arka plan, grid çizgileri)
- [x] Parça tray'i (VStack, unplaced pieces)
- [x] DragGesture ile parça sürükleme
- [x] Snap-to-grid (±15pt tolerans)
- [x] Geçersiz yerleşim: kırmızı kenarlık animasyonu
- [x] Çözüm tespiti → "Solved!" konsol + overlay
- [x] Placed block tap → tray'e iade
- [x] Spec §7 renk paleti

## Özellikler (v0.2 KAPSAMI DIŞI — BLOCKERS.md'ye eklendi)
- App icon + launch image (placeholder gerekli)
- Timer, hint butonu, pause overlay
- Level complete ekranı (v0.3'te)
- NavigationStack akışı (v0.3'te)

---

## Test Planı

| Test | Senaryo |
|---|---|
| `testLoad` | `loadLevel()` → `level != nil`, width=5, height=5, pieces.count=5 |
| `testPlace` | İlk parçayı solution origin'ine yerleştir → `placements.count == 1` |
| `testSolved` | Tüm parçaları solution origin'lerine yerleştir → `isSolved == true` |

---

## Branch & Çıktı
- Branch: `feature/v0.2-core-ui`
- xcodebuild: `xcodebuild -project SnugloApp/SnugloApp.xcodeproj -scheme SnugloApp -destination 'platform=iOS Simulator,name=iPhone 16' build`
- CHANGELOG entry: `## v0.2 — Core UI`

---

*Spec SNUGLO_SPEC.md §2 (interaction), §6 (level format), §7 (visual design) referans alındı.*  
*EXECUTION_PLAN.md v0.2 bölümü referans alındı; çelişki yok.*
