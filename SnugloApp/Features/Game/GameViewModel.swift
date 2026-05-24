// GameViewModel.swift — v0.2 Core UI
// @Observable (iOS 17 Observation framework)
// Sorumlu: level yükleme, parça yerleştirme/kaldırma, çözüm kontrolü

import Foundation
import Observation
import SnugloEngine

@Observable
final class GameViewModel {

    // MARK: - State (otomatik tracked by @Observable)

    var level: Level?
    var placements: [String: Placement] = [:]   // pieceId → Placement
    var invalidPieceIds: Set<String> = []        // anlık kırmızı flash için
    var isSolved: Bool = false
    var loadError: String?

    // MARK: - Sabitler

    /// Engine v0.1 Piece modelinde renk field'ı yok; index-tabanlı renk ataması
    private static let colorKeys = SnugloColors.blockPaletteKeys

    // MARK: - Servisler

    private let loader  = LevelLoader()
    private let checker = SolutionChecker()

    // MARK: - Renk Yardımcısı

    func colorKey(for pieceId: String) -> String {
        guard let level else { return "purple" }
        let idx = level.pieces.firstIndex(where: { $0.id == pieceId }) ?? 0
        return Self.colorKeys[idx % Self.colorKeys.count]
    }

    // MARK: - Yükleme

    func loadLevel(named name: String = "level_5x5") {
        do {
            let loaded = try loader.loadLevel(named: name)
            level = loaded
            placements = [:]
            isSolved = false
            invalidPieceIds = []
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }

    // MARK: - Hesaplanmış Özellikler

    /// Henüz yerleştirilmemiş parçalar (tray için)
    var unplacedPieces: [Piece] {
        guard let level else { return [] }
        return level.pieces.filter { placements[$0.id] == nil }
    }

    /// Yerleştirilmiş parçalar (grid render için)
    var placedPieces: [(piece: Piece, placement: Placement)] {
        guard let level else { return [] }
        return level.pieces.compactMap { piece in
            guard let pl = placements[piece.id] else { return nil }
            return (piece, pl)
        }
    }

    // MARK: - Doğrulama

    /// Verilen parçanın verilen origin'e yerleştirilebilir olup olmadığını kontrol eder.
    /// - Sınır dışı hücre varsa false
    /// - Başka yerleşmiş parçayla çakışma varsa false (kendi önceki konumu hariç)
    func canPlace(pieceId: String, at origin: Coord) -> Bool {
        guard let level,
              let piece = level.pieces.first(where: { $0.id == pieceId })
        else { return false }

        // ── 1. Sınır kontrolü ────────────────────────────────────
        for cell in piece.cells {
            let ax = origin.x + cell.x
            let ay = origin.y + cell.y
            guard ax >= 0, ax < level.width,
                  ay >= 0, ay < level.height
            else { return false }
        }

        // ── 2. Çakışma kontrolü ──────────────────────────────────
        // Mevcut yerleşimleri doldurulmuş hücrelere çevir (bu parçanın eski konumu hariç)
        var occupied = Set<Coord>()
        for (pid, pl) in placements where pid != pieceId {
            guard let p = level.pieces.first(where: { $0.id == pid }) else { continue }
            for c in p.cells {
                occupied.insert(Coord(x: pl.origin.x + c.x, y: pl.origin.y + c.y))
            }
        }

        for cell in piece.cells {
            if occupied.contains(Coord(x: origin.x + cell.x, y: origin.y + cell.y)) {
                return false
            }
        }

        return true
    }

    // MARK: - Eylemler

    /// Parçayı grid'e yerleştirir.
    /// - Returns: `true` — yerleştirme geçerliyse; `false` — geçersizse (kırmızı flash tetiklenir)
    @discardableResult
    func place(pieceId: String, at origin: Coord) -> Bool {
        guard canPlace(pieceId: pieceId, at: origin) else {
            flashInvalid(pieceId)
            return false
        }
        placements[pieceId] = Placement(pieceId: pieceId, origin: origin)
        checkSolution()
        return true
    }

    /// Parçayı grid'den kaldırır; tray'e iade eder.
    func pickUp(pieceId: String) {
        placements.removeValue(forKey: pieceId)
        isSolved = false
    }

    /// Tüm yerleşimleri sıfırlar.
    func reset() {
        placements = [:]
        isSolved = false
        invalidPieceIds = []
    }

    // MARK: - Yardımcı (private)

    /// Geçersiz yerleşim anında kırmızı flash tetikler; 600ms sonra söner.
    private func flashInvalid(_ pieceId: String) {
        invalidPieceIds.insert(pieceId)
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(600))
            self?.invalidPieceIds.remove(pieceId)
        }
    }

    /// Tüm parçalar yerleşmişse SolutionChecker ile doğrular.
    private func checkSolution() {
        guard let level, placements.count == level.pieces.count else { return }
        let result = checker.check(level: level, placements: Array(placements.values))
        guard result == .valid else { return }
        isSolved = true
        print("✅ Solved! Level: \(level.id)")
    }
}
