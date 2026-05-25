import Foundation

// MARK: - LevelGenerator

/// Deterministik polyomino bölme tabanlı level üreteci.
///
/// Algoritma (BFS Voronoi partitioning):
///   1. `SeedHash.fnv1a(packId) ^ levelIndex` seed'i → `SeededRandom`
///   2. Difficulty curve → piece count (gridSize × levelIndex'e göre)
///   3. N seed noktasını grid'e rastgele yerleştir
///   4. Seeded BFS ile grid'i N bağlı bölgeye böl (her bölge = bir piece)
///   5. Her bölgenin minimum (x,y)'ini origin kabul et, cells normalize et
///   6. `Level(pieces:solution:)` döndür — SolutionChecker.check → .valid garantili
///
/// **Determinizm garantisi:** Aynı (packId, levelIndex, gridSize, seedBase) → özdeş `Level`.
public struct LevelGenerator {

    /// Varsayılan seed base. "SNUGLO11" ASCII hex.
    public static let defaultSeedBase: UInt64 = 0x534E55474C4F3131

    public init() {}

    // MARK: - Public API

    /// Tek bir level üretir.
    ///
    /// - Parameters:
    ///   - packId:     Pack tanımlayıcısı, örn. `"cozy-beginnings"`. Seed'e karışır.
    ///   - levelIndex: 1-tabanlı sıra numarası (1…60).
    ///   - gridSize:   Grid kenar uzunluğu — 5, 6, 7 veya 8.
    ///   - seedBase:   Override için; varsayılan `LevelGenerator.defaultSeedBase`.
    public func generate(
        packId: String,
        levelIndex: Int,
        gridSize: Int,
        seedBase: UInt64 = LevelGenerator.defaultSeedBase
    ) -> Level {

        // ── Deterministik seed ──────────────────────────────────────────────
        let fnvPack  = SeedHash.fnv1a(packId)
        let idxMix   = UInt64(bitPattern: Int64(levelIndex)) &* 1_099_511_628_211
        let seed     = seedBase ^ fnvPack ^ idxMix
        var rng      = SeededRandom(seed: seed)

        // ── Difficulty curve → piece count ──────────────────────────────────
        let pieceCount = difficultyPieceCount(gridSize: gridSize, levelIndex: levelIndex)

        // ── Grid bölme ──────────────────────────────────────────────────────
        let regions = partitionGrid(size: gridSize, count: pieceCount, rng: &rng)

        // ── Piece + Placement ───────────────────────────────────────────────
        var pieces: [Piece]       = []
        var solution: [Placement] = []
        pieces.reserveCapacity(regions.count)
        solution.reserveCapacity(regions.count)

        for (i, region) in regions.enumerated() {
            guard !region.isEmpty else { continue }

            let minX   = region.map(\.x).min()!
            let minY   = region.map(\.y).min()!
            let origin = Coord(x: minX, y: minY)

            // Normalize: origin-relative, satır önce sıralı
            let cells = region
                .map { Coord(x: $0.x - minX, y: $0.y - minY) }
                .sorted { $0.y != $1.y ? $0.y < $1.y : $0.x < $1.x }

            let pieceId = "\(packId)-\(levelIndex)-p\(i)"
            pieces.append(Piece(id: pieceId, cells: cells))
            solution.append(Placement(pieceId: pieceId, origin: origin))
        }

        return Level(
            id: "\(packId)-\(levelIndex)",
            width: gridSize,
            height: gridSize,
            pieces: pieces,
            solution: solution
        )
    }

    /// `count` adet level üretir (levelIndex 1…count).
    public func generateAll(packId: String, gridSize: Int, count: Int) -> [Level] {
        guard count > 0 else { return [] }
        return (1...count).map { generate(packId: packId, levelIndex: $0, gridSize: gridSize) }
    }

    // MARK: - Difficulty Curve

    /// Grid boyutu ve level index'e göre hedef piece sayısı.
    /// Zorluk arttıkça daha fazla parça → daha küçük piece alanları.
    public func difficultyPieceCount(gridSize: Int, levelIndex: Int) -> Int {
        switch gridSize {
        case 5:  // 25 hücre
            return levelIndex <= 20 ? 4 : 5

        case 6:  // 36 hücre
            if levelIndex <= 20 { return 5 }
            if levelIndex <= 40 { return 6 }
            return 7

        case 7:  // 49 hücre
            if levelIndex <= 20 { return 6 }
            if levelIndex <= 40 { return 7 }
            return 8

        case 8:  // 64 hücre
            if levelIndex <= 20 { return 8 }
            if levelIndex <= 40 { return 10 }
            return 12

        default:
            // Diğer boyutlar için genel formül
            return max(3, gridSize * gridSize / 6)
        }
    }

    // MARK: - Grid Partitioner

    /// `size`×`size` grid'i `count` adet bağlı bölgeye böler.
    ///
    /// Yöntem: Seeded Voronoi BFS
    ///   - N rastgele seed koy
    ///   - Her piece kendi seed'inden BFS ile büyür
    ///   - Tüm hücreler kaplanana dek devam et
    ///
    /// Bağlantı garantisi: Her bölge komşu hücrelerden büyüdüğü için her zaman bağlıdır.
    private func partitionGrid(size: Int, count: Int, rng: inout SeededRandom) -> [[Coord]] {
        let total      = size * size
        let safeCount  = max(1, min(count, total))

        // claims[cellIdx] = piece index (-1: sahipsiz)
        var claims = Array(repeating: -1, count: total)

        // Seed konumları: ilk safeCount shuffle sonucu
        var indices = Array(0..<total)
        indices.shuffle(using: &rng)
        let seeds = Array(indices.prefix(safeCount))

        for (pieceIdx, seedCell) in seeds.enumerated() {
            claims[seedCell] = pieceIdx
        }

        // Her piece'in büyüme adayları
        var candidates: [[Int]] = Array(repeating: [], count: safeCount)
        for (pieceIdx, seedCell) in seeds.enumerated() {
            for n in gridNeighbors(of: seedCell, size: size) where claims[n] == -1 {
                candidates[pieceIdx].append(n)
            }
        }

        var remaining = total - safeCount

        // BFS growth loop
        while remaining > 0 {
            var grew = false

            // Her iterasyonda piece sırası karıştır → daha uniform büyüme
            var pieceOrder = Array(0..<safeCount)
            pieceOrder.shuffle(using: &rng)

            for pieceIdx in pieceOrder {
                // Artık sahiplenilmiş adayları temizle
                candidates[pieceIdx] = candidates[pieceIdx].filter { claims[$0] == -1 }
                guard !candidates[pieceIdx].isEmpty else { continue }

                // Rastgele bir aday seç
                let pick = Int(rng.next() % UInt64(candidates[pieceIdx].count))
                let cell = candidates[pieceIdx][pick]

                // Race-condition guard (başka piece almış olabilir)
                guard claims[cell] == -1 else {
                    candidates[pieceIdx].remove(at: pick)
                    continue
                }

                claims[cell] = pieceIdx
                remaining   -= 1
                grew         = true

                // Yeni komşuları aday listesine ekle
                for n in gridNeighbors(of: cell, size: size) where claims[n] == -1 {
                    candidates[pieceIdx].append(n)
                }
            }

            if !grew {
                // Tıkalı durum: sahipsiz her hücreye komşu piece'i ata
                // Bu her zaman bağlılığı korur (hücre, mevcut bir piece'e yapışır)
                for i in 0..<total where claims[i] == -1 {
                    for n in gridNeighbors(of: i, size: size) where claims[n] >= 0 {
                        claims[i] = claims[n]
                        remaining -= 1
                        break
                    }
                }
            }
        }

        // Bölgeleri oluştur
        var regions: [[Coord]] = Array(repeating: [], count: safeCount)
        for cellIdx in 0..<total {
            let pieceIdx = max(0, claims[cellIdx])
            let x = cellIdx % size
            let y = cellIdx / size
            regions[pieceIdx].append(Coord(x: x, y: y))
        }

        return regions
    }

    /// Bir grid hücresinin 4-bağlantılı komşularını döner (sınır kontrolü dahil).
    private func gridNeighbors(of cellIdx: Int, size: Int) -> [Int] {
        let x = cellIdx % size
        let y = cellIdx / size
        var result = [Int]()
        result.reserveCapacity(4)
        if x > 0 { result.append(y * size + x - 1) }
        if x < size - 1 { result.append(y * size + x + 1) }
        if y > 0 { result.append((y - 1) * size + x) }
        if y < size - 1 { result.append((y + 1) * size + x) }
        return result
    }
}
