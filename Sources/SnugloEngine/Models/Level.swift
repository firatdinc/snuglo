import Foundation

/// Bir puzzle seviyesinin tüm verisi.
/// `width` × `height` = toplam hücre sayısı.
/// `pieces` içindeki tüm `cells` sayısı toplamı == width × height (geçerli level için).
/// `solution` referans çözümdür (hint + checker için).
public struct Level: Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let width: Int
    public let height: Int
    public let pieces: [Piece]
    public let solution: [Placement]

    public init(
        id: String,
        width: Int,
        height: Int,
        pieces: [Piece],
        solution: [Placement]
    ) {
        self.id = id
        self.width = width
        self.height = height
        self.pieces = pieces
        self.solution = solution
    }
}
