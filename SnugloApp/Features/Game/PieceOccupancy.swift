import SnugloEngine

// MARK: — PieceOccupancy
// Pure logic mirroring cell-accurate piece selection: which placed piece occupies
// a given board cell. This is the source-of-truth the hit-testing reflects — a
// unit test over it guards the "grabbed the wrong piece" regression.

enum PieceOccupancy {

    /// The piece whose FILLED cells cover `coord`, given each piece's origin.
    /// Returns nil if the cell is empty. (No two placed pieces share a cell.)
    static func occupant(at coord: Coord, origins: [PieceID: Coord], pieces: [Piece]) -> PieceID? {
        for (pid, origin) in origins {
            guard let piece = pieces.first(where: { $0.id == pid }) else { continue }
            if piece.cells.contains(where: { $0.x + origin.x == coord.x && $0.y + origin.y == coord.y }) {
                return pid
            }
        }
        return nil
    }

    /// Convenience over the live `[PieceID: Placement]` model.
    static func occupant(at coord: Coord, placements: [PieceID: Placement], pieces: [Piece]) -> PieceID? {
        occupant(at: coord, origins: placements.mapValues { $0.origin }, pieces: pieces)
    }
}
