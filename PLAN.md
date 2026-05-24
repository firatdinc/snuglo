# PLAN.md — Snuglo Engine v0.1

## Hedef

v0.1 kapsamı yalnızca **headless engine** + **XCTest**: UI yok, persistence yok, network yok.
`SolutionChecker` + `LevelLoader` iskeletini doğrulayan test suite'i yeşile alıp bir sonraki
milestone için sağlam bir temel bırakmak.

---

## Stack

| Bileşen       | Seçim                                      |
|---------------|--------------------------------------------|
| Dil           | Swift 5.9+                                 |
| Paket yöneticisi | Swift Package Manager (saf SPM, Xcode proj yok) |
| Platform      | iOS 17 · macOS 13 (swift test için)        |
| Temel kütüphane | Foundation only (UI/network/persistence yok) |
| Test framework | XCTest                                     |

---

## Layer Tablosu

```
Tests  ──depends──▶  Engine  ──depends──▶  Models
                       │
                  Resources (bundle JSON)
```

| Layer     | Klasör                              | İzin verilen bağımlılıklar     |
|-----------|-------------------------------------|-------------------------------|
| Models    | `Sources/SnugloEngine/Models/`      | Foundation                    |
| Engine    | `Sources/SnugloEngine/Engine/`      | Models + Foundation           |
| Resources | `Sources/SnugloEngine/Resources/`   | —  (veri dosyaları)           |
| Tests     | `Tests/SnugloEngineTests/`          | Engine + Models + XCTest      |

**Yasak bağımlılıklar:** SwiftUI · UIKit · SwiftData · StoreKit · Network · AVFoundation

---

## Klasör Hiyerarşisi

```
snuglo--AnsD1/
├── Package.swift
├── PLAN.md
├── SNUGLO_SPEC.md
├── Sources/
│   └── SnugloEngine/
│       ├── Models/
│       │   ├── Coord.swift
│       │   ├── Piece.swift
│       │   ├── Placement.swift
│       │   ├── PlacementResult.swift
│       │   └── Level.swift
│       ├── Engine/
│       │   ├── SolutionChecker.swift
│       │   └── LevelLoader.swift
│       └── Resources/
│           └── Levels/          ← *.json buraya (sonraki task)
└── Tests/
    └── SnugloEngineTests/
        └── SolutionCheckerSanityTests.swift
```

---

## SolutionChecker Kontratı

```swift
public struct SolutionChecker {
    public func check(level: Level, placements: [Placement]) -> PlacementResult
}
```

### Kontrol sırası (fail-fast)

| # | Koşul                              | Dönüş                                  |
|---|------------------------------------|----------------------------------------|
| 1 | `width ≤ 0 \|\| height ≤ 0`        | `.emptyGrid`                           |
| 2 | `placements` boş (ama grid var)    | `.incompleteCoverage(missing: tümGrid)` |
| 3 | `pieceId` level'da tanımlı değil  | `.unknownPiece(id: String)`            |
| 4 | Herhangi absolute koord bound dışı | `.outOfBounds(at: Coord)`              |
| 5 | Herhangi hücre zaten dolu          | `.overlap(at: Coord)`                  |
| 6 | Bazı grid hücreleri boş kaldı      | `.incompleteCoverage(missing: [Coord])`|
| 7 | Tüm hücreler dolu                  | `.valid`                               |

**Absolute koordinat hesabı:**
`absX = piece.cells[i].x + placement.origin.x`
`absY = piece.cells[i].y + placement.origin.y`

---

## PlacementResult

```swift
public enum PlacementResult: Equatable, Sendable {
    case valid
    case overlap(at: Coord)
    case outOfBounds(at: Coord)
    case incompleteCoverage(missing: [Coord])
    case emptyGrid
    case unknownPiece(id: String)
}
```

---

## Level JSON Şeması

`LevelLoader` v0.1'de tam çalışır; `LoaderError.notFound` / `.readFailed` / `.decodingFailed`
döndürür. Bundle JSON formatı:

```json
{
  "id": "level_5x5",
  "width": 5,
  "height": 5,
  "pieces": [
    { "id": "p1", "cells": [{"x":0,"y":0},{"x":1,"y":0},{"x":2,"y":0}] },
    { "id": "p2", "cells": [{"x":0,"y":0},{"x":0,"y":1},{"x":0,"y":2}] },
    { "id": "p3", "cells": [{"x":0,"y":0},{"x":1,"y":0},{"x":1,"y":1},{"x":0,"y":1}] }
  ],
  "solution": [
    { "pieceId": "p1", "origin": {"x":0,"y":0} },
    { "pieceId": "p2", "origin": {"x":1,"y":1} },
    { "pieceId": "p3", "origin": {"x":1,"y":0} }
  ]
}
```

---

## LevelLoader Hata Tablosu

| `LoaderError` case              | Ne zaman fırlatılır                           |
|---------------------------------|-----------------------------------------------|
| `.notFound(name)`               | Bundle'da `<name>.json` URL'si yok            |
| `.readFailed(name:underlying:)` | URL var ama `Data(contentsOf:)` başarısız     |
| `.decodingFailed(name:underlying:)` | JSON decode hatası (şema uyuşmazlığı vs.) |

---

## v0.2+ Teaser

1. **Core UI** — `GridView` + `BlockView` + drag-drop + snap mekanizması (SwiftUI, iOS 17 gestures).
2. **ProceduralGenerator iskeleti** — Recursive rectangular subdivision, ilk testleri.
3. **Persistence** — UserDefaults ile tamamlanan level kaydı.
