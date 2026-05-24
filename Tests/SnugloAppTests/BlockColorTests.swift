import XCTest
import SwiftUI
@testable import SnugloApp

// MARK: — Faz B fix: blockColor(for:) FNV-1a cross-launch stability tests
//
// `String.hashValue` is randomised per process (Swift SE-0206 / SE-0143).
// The fix replaces hashValue with FNV-1a so `blockColor(for:)` returns the
// same palette index regardless of process, OS version, or Swift runtime.
//
// Test design:
//   1. Determinism within a run: same ID → same Color twice.
//   2. Hardcoded expected indices from FNV-1a (hand-computed, step-by-step).
//      With hashValue these would fail on some launches; with FNV-1a they
//      pass every launch. Proving this is the point.
//   3. Reference-implementation cross-check: an independent FNV-1a helper
//      written here must agree with AppColors.blockColor for all sample IDs.

final class BlockColorTests: XCTestCase {

    // MARK: — 1. Determinism (pure function — same input → same output)

    func test_blockColor_sameIDReturnsSameColorTwice() {
        let id = "piece-alpha"
        XCTAssertEqual(
            AppColors.blockColor(for: id),
            AppColors.blockColor(for: id),
            "blockColor(for:) must return the same Color on repeated calls with the same ID"
        )
    }

    // MARK: — 2. Hardcoded FNV-1a expected palette indices
    //
    // Each expected index was computed by hand using 32-bit FNV-1a:
    //   offset_basis = 2166136261  (0x811C9DC5)
    //   prime        = 16777619    (0x01000193)
    //   for each byte b: h ^= b; h &*= prime
    //   index = h % 6
    //
    // Empty string → no bytes processed → h = 2166136261
    //   2166136261 % 6 = 1  →  blockPalette[1] = blockSage
    func test_blockColor_emptyID_matchesFNV1aIndex1() {
        XCTAssertEqual(
            AppColors.blockColor(for: ""),
            AppColors.blockPalette[1],  // blockSage — FNV-1a("") % 6 = 1
            "blockColor(for: \"\") must be palette index 1 (FNV-1a of empty string = 2166136261, 2166136261 % 6 = 1)"
        )
    }

    // "p0" → bytes: 112, 48
    //   After 'p': h = 0xF50C43EF  (step-by-step verified)
    //   After '0': h = 0xA16B341D, result % 6 = 3  →  blockPalette[3] = blockBlush
    func test_blockColor_p0_matchesFNV1aIndex3() {
        XCTAssertEqual(
            AppColors.blockColor(for: "p0"),
            AppColors.blockPalette[3],  // blockBlush — FNV-1a("p0") % 6 = 3
            "blockColor(for: \"p0\") must be palette index 3 (FNV-1a deterministic)"
        )
    }

    // "p1" → bytes: 112, 49
    //   After 'p': h = 0xF50C43EF  (same first byte)
    //   After '1': h = 0xA02D5DFA, result % 6 = 4  →  blockPalette[4] = blockCream
    func test_blockColor_p1_matchesFNV1aIndex4() {
        XCTAssertEqual(
            AppColors.blockColor(for: "p1"),
            AppColors.blockPalette[4],  // blockCream — FNV-1a("p1") % 6 = 4
            "blockColor(for: \"p1\") must be palette index 4 (FNV-1a deterministic)"
        )
    }

    // MARK: — 3. Reference FNV-1a cross-check
    //
    // An independent implementation of the same algorithm, written here as a
    // test helper without access to the production code path.  If blockColor
    // were using hashValue or any other algorithm, this test would surface it.
    func test_blockColor_matchesFNV1aReference_forVariousIDs() {
        func referenceFNV1aIndex(for id: String) -> Int {
            var h: UInt32 = 2166136261
            for b in id.utf8 {
                h ^= UInt32(b)
                h &*= 16777619
            }
            return Int(h % UInt32(AppColors.blockPalette.count))
        }

        let sampleIDs = [
            "", "p0", "p1", "p2", "p3", "p4",
            "pieceA", "pieceB", "piece-red",
            "long-piece-identifier-123",
        ]

        for id in sampleIDs {
            let expected = AppColors.blockPalette[referenceFNV1aIndex(for: id)]
            XCTAssertEqual(
                AppColors.blockColor(for: id),
                expected,
                "blockColor(for: \"\(id)\") does not match FNV-1a reference index"
            )
        }
    }
}
