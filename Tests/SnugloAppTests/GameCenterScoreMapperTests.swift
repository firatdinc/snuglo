import Testing
@testable import SnugloApp

struct GameCenterScoreMapperTests {

    // MARK: — totalLevels

    @Test func totalLevels_positive_returnsSame() {
        #expect(GameCenterScoreMapper.totalLevels(completedCount: 42) == 42)
    }

    @Test func totalLevels_zero_returnsZero() {
        #expect(GameCenterScoreMapper.totalLevels(completedCount: 0) == 0)
    }

    @Test func totalLevels_negative_clampsToZero() {
        #expect(GameCenterScoreMapper.totalLevels(completedCount: -5) == 0)
    }

    // MARK: — fastestSolveCentiseconds

    @Test func fastestSolveCs_singleValid_returnsCs() {
        #expect(GameCenterScoreMapper.fastestSolveCentiseconds(fromBestTimes: [1.5]) == 150)
    }

    @Test func fastestSolveCs_multipleValid_returnsMinCs() {
        #expect(GameCenterScoreMapper.fastestSolveCentiseconds(fromBestTimes: [3.0, 1.2, 2.0]) == 120)
    }

    @Test func fastestSolveCs_empty_returnsNil() {
        #expect(GameCenterScoreMapper.fastestSolveCentiseconds(fromBestTimes: []) == nil)
    }

    @Test func fastestSolveCs_allNonPositive_returnsNil() {
        #expect(GameCenterScoreMapper.fastestSolveCentiseconds(fromBestTimes: [0, -1.0]) == nil)
    }

    @Test func fastestSolveCs_mixedValidInvalid_skipsNonPositive() {
        #expect(GameCenterScoreMapper.fastestSolveCentiseconds(fromBestTimes: [0, -2.0, 2.5]) == 250)
    }

    // MARK: — bestStreak

    @Test func bestStreak_positive_returnsSame() {
        #expect(GameCenterScoreMapper.bestStreak(10) == 10)
    }

    @Test func bestStreak_zero_returnsZero() {
        #expect(GameCenterScoreMapper.bestStreak(0) == 0)
    }

    @Test func bestStreak_negative_clampsToZero() {
        #expect(GameCenterScoreMapper.bestStreak(-3) == 0)
    }
}
