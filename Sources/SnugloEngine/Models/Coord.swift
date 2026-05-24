import Foundation

/// Grid üzerinde bir hücrenin 2D koordinatı.
/// x: sütun (0 = sol), y: satır (0 = üst).
public struct Coord: Codable, Equatable, Hashable, Sendable {
    public let x: Int
    public let y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}
