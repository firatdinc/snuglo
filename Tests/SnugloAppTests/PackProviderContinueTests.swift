import XCTest
@testable import SnugloApp
@testable import SnugloEngine

// MARK: — PackProviderContinueTests
// v1.1.1 hotfix coverage:
//   • nextLevelId(after:) — used by LevelCompleteSheet "Next Level" CTA
//   • continuePack() / continueLevel() — used by MainMenu Continue card
//
// These helpers replaced the hardcoded MockData.continuePack / continueLevel
// which always returned "Cozy Beginnings Level 13" regardless of real
// progress. Tests below confirm the new helpers respect actual unlock state.

@MainActor
final class PackProviderContinueTests: XCTestCase {

    // MARK: - nextLevelId(after:)

    func test_nextLevelId_returnsNextIndexInSamePack() {
        XCTAssertEqual(PackProvider.nextLevelId(after: "cozy-beginnings-1"), "cozy-beginnings-2")
        XCTAssertEqual(PackProvider.nextLevelId(after: "cozy-beginnings-12"), "cozy-beginnings-13")
        XCTAssertEqual(PackProvider.nextLevelId(after: "spice-route-30"), "spice-route-31")
    }

    func test_nextLevelId_handlesPackIdContainingDashes() {
        // packId itself contains "-" → split must use LAST dash.
        XCTAssertEqual(PackProvider.nextLevelId(after: "mambo-nights-5"), "mambo-nights-6")
        XCTAssertEqual(PackProvider.nextLevelId(after: "woodland-retreat-1"), "woodland-retreat-2")
    }

    func test_nextLevelId_returnsNilAtPackEnd() {
        // Every pack in MockData has 60 levels.
        XCTAssertNil(PackProvider.nextLevelId(after: "cozy-beginnings-60"))
        XCTAssertNil(PackProvider.nextLevelId(after: "spice-route-60"))
    }

    func test_nextLevelId_returnsNilForUnknownPack() {
        XCTAssertNil(PackProvider.nextLevelId(after: "no-such-pack-1"))
    }

    func test_nextLevelId_returnsNilForMalformedId() {
        XCTAssertNil(PackProvider.nextLevelId(after: "no-dash-index"))
        XCTAssertNil(PackProvider.nextLevelId(after: "cozy-beginnings-not-a-number"))
        XCTAssertNil(PackProvider.nextLevelId(after: ""))
    }

    // MARK: - continuePack() / continueLevel()

    func test_continuePack_returnsFirstUnlockedPackForFreshPlayer() {
        // For a brand-new player (no completed levels), continuePack should
        // surface the first unlocked pack so Level 1 is always reachable
        // from the MainMenu Continue card.
        guard let pack = PackProvider.continuePack() else {
            XCTFail("continuePack returned nil for a fresh player")
            return
        }
        XCTAssertFalse(pack.isLocked, "Continue pack must be unlocked")
    }

    func test_continueLevel_returnsLevel1ForFreshPlayer() {
        // With zero progress, continueLevel should be Level 1 of the first
        // unlocked pack, NOT the hardcoded "Cozy Beginnings Level 13"
        // that the old MockData.continueLevel returned.
        guard let level = PackProvider.continueLevel() else {
            XCTFail("continueLevel returned nil for a fresh player")
            return
        }
        XCTAssertEqual(level.index, 1, "Fresh player should see Level 1, not the mock Level 13")
        XCTAssertFalse(level.isLocked)
        XCTAssertFalse(level.isCompleted)
        XCTAssertEqual(level.stars, 0)
    }

    func test_continueLevel_idMatchesPackPlusIndex() {
        guard let pack = PackProvider.continuePack(),
              let level = PackProvider.continueLevel()
        else {
            XCTFail("continuePack/continueLevel returned nil")
            return
        }
        XCTAssertEqual(level.id, "\(pack.id)-\(level.index)")
    }
}
