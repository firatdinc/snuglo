import XCTest
import SwiftUI
@testable import SnugloApp

/// Unit tests verifying that `AppColors.blockColor(for:)` is deterministic across
/// all calls — fixing the BLOCKER where `String.hashValue` (randomised per-process
/// since Swift 4.2) was used instead of a stable hash.
final class ColorsTests: XCTestCase {

    // MARK: - Stability: same ID → same Color (within a run)

    func test_blockColor_sameIDReturnsSameColorEveryCall() {
        // Call 1000 times; must always return the identical Color value.
        let expected = AppColors.blockColor(for: "p1")
        for _ in 0..<1_000 {
            XCTAssertEqual(
                AppColors.blockColor(for: "p1"),
                expected,
                "blockColor(for:) must be pure — same input must always produce the same output"
            )
        }
    }

    // MARK: - Snapshot: known IDs map to expected palette indices
    //
    // Hash derivation (polynomial, multiplier 31, Int overflow-wrapping):
    //   "p1": scalars [112, 49]  → hash = (0·31+112)·31+49 = 3521 → 3521 % 6 = 5 → blockDustyOlive
    //   "p2": scalars [112, 50]  → hash = 3522 → 3522 % 6 = 0 → blockLavender
    //   "p3": scalars [112, 51]  → hash = 3523 → 3523 % 6 = 1 → blockSage
    //
    // If these assertions ever fail it means the hash function or palette order changed;
    // update the snapshot intentionally and document the reason.

    func test_blockColor_snapshotForKnownIDs() {
        XCTAssertEqual(AppColors.blockColor(for: "p1"), AppColors.blockDustyOlive,
                       "p1 must map to blockDustyOlive (palette index 5)")
        XCTAssertEqual(AppColors.blockColor(for: "p2"), AppColors.blockLavender,
                       "p2 must map to blockLavender (palette index 0)")
        XCTAssertEqual(AppColors.blockColor(for: "p3"), AppColors.blockSage,
                       "p3 must map to blockSage (palette index 1)")
    }

    // MARK: - Palette coverage: all 6 slots reachable

    func test_blockColor_allPaletteEntriesAreReachable() {
        // Generate IDs until every palette index is hit (terminates quickly).
        var hit = Set<Color>()
        for i in 0..<100 {
            hit.insert(AppColors.blockColor(for: "piece_\(i)"))
            if hit.count == AppColors.blockPalette.count { break }
        }
        XCTAssertEqual(
            hit.count,
            AppColors.blockPalette.count,
            "All \(AppColors.blockPalette.count) palette colors should be reachable from distinct piece IDs"
        )
    }
}
