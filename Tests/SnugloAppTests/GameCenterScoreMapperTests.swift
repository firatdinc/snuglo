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

    // MARK: — fastestSolveMs

    @Test func fastestSolveMs_singleValid_returnsMs() {
        #expect(GameCenterScoreMapper.fastestSolveMs(fromBestTimes: [1.5]) == 1500)
    }

    @Test func fastestSolveMs_multipleValid_returnsMinMs() {
        #expect(GameCenterScoreMapper.fastestSolveMs(fromBestTimes: [3.0, 1.2, 2.0]) == 1200)
    }

    @Test func fastestSolveMs_empty_returnsNil() {
        #expect(GameCenterScoreMapper.fastestSolveMs(fromBestTimes: []) == nil)
    }

    @Test func fastestSolveMs_allNonPositive_returnsNil() {
        #expect(GameCenterScoreMapper.fastestSolveMs(fromBestTimes: [0, -1.0]) == nil)
    }

    @Test func fastestSolveMs_mixedValidInvalid_skipsNonPositive() {
        #expect(GameCenterScoreMapper.fastestSolveMs(fromBestTimes: [0, -2.0, 2.5]) == 2500)
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
