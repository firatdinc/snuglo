import Foundation

/// Bir puzzle parçası. `cells`, parçanın kendi lokal koordinat sistemindeki
/// hücre offset'lerini tutar (origin = Coord(0,0)).
/// Örnek: 2×2 kare → cells = [(0,0),(1,0),(0,1),(1,1)]
public struct Piece: Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let cells: [Coord]

    public init(id: String, cells: [Coord]) {
        self.id = id
        self.cells = cells
    }

    // MARK: — Faz B: UI convenience

    /// Number of cells this piece occupies. Used for the numeric label on BlockView.
    /// Domain model is unchanged — this is a computed property, not stored data.
    public var cellCount: Int { cells.count }
}
