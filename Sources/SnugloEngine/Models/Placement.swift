import Foundation

/// Bir parçanın grid üzerindeki yerleşimi.
/// `pieceId` → `Piece.id` ile eşleşir.
/// `origin` → parçanın lokal (0,0) offset'inin grid'deki absolute konumu.
public struct Placement: Codable, Equatable, Hashable, Sendable {
    public let pieceId: String
    public let origin: Coord

    public init(pieceId: String, origin: Coord) {
        self.pieceId = pieceId
        self.origin = origin
    }
}
