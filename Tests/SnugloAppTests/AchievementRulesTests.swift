import Testing
@testable import SnugloApp

// MARK: — AchievementRulesTests
// Boundary tests for all 10 achievement rules.

@MainActor
struct AchievementRulesTests {

    private func stats(
        completedLevels: Int = 0,
        currentStreak: Int = 0,
        perfectSolves: Int = 0,
        hintFreeSolves: Int = 0,
        fastestSolveSeconds: Int? = nil
    ) -> AchievementStats {
        AchievementStats(
            completedLevels: completedLevels,
            currentStreak: currentStreak,
            perfectSolves: perfectSolves,
            hintFreeSolves: hintFreeSolves,
            fastestSolveSeconds: fastestSolveSeconds
        )
    }

    // MARK: — firstSteps

    @Test func firstSteps_notApplicable_whenZeroLevels() {
        #expect(!AchievementRules.isApplicable(.firstSteps, stats: stats(completedLevels: 0)))
    }

    @Test func firstSteps_applicable_whenOneLevelDone() {
        #expect(AchievementRules.isApplicable(.firstSteps, stats: stats(completedLevels: 1)))
    }

    // MARK: — levelHunter10

    @Test func levelHunter10_notApplicable_at9() {
        #expect(!AchievementRules.isApplicable(.levelHunter10, stats: stats(completedLevels: 9)))
    }

    @Test func levelHunter10_applicable_at10() {
        #expect(AchievementRules.isApplicable(.levelHunter10, stats: stats(completedLevels: 10)))
    }

    @Test func levelHunter10_applicable_above10() {
        #expect(AchievementRules.isApplicable(.levelHunter10, stats: stats(completedLevels: 20)))
    }

    // MARK: — levelMaster50

    // swiftlint:disable inclusive_language
    @Test func levelMaster50_notApplicable_at49() {
        #expect(!AchievementRules.isApplicable(.levelMaster50, stats: stats(completedLevels: 49)))
    }

    @Test func levelMaster50_applicable_at50() {
        #expect(AchievementRules.isApplicable(.levelMaster50, stats: stats(completedLevels: 50)))
    }
    // swiftlint:enable inclusive_language

    // MARK: — perfectionist1

    @Test func perfectionist1_notApplicable_atZero() {
        #expect(!AchievementRules.isApplicable(.perfectionist1, stats: stats(perfectSolves: 0)))
    }

    @Test func perfectionist1_applicable_atOne() {
        #expect(AchievementRules.isApplicable(.perfectionist1, stats: stats(perfectSolves: 1)))
    }

    // MARK: — perfectionistPro10

    @Test func perfectionistPro10_notApplicable_at9() {
        #expect(!AchievementRules.isApplicable(.perfectionistPro10, stats: stats(perfectSolves: 9)))
    }

    @Test func perfectionistPro10_applicable_at10() {
        #expect(AchievementRules.isApplicable(.perfectionistPro10, stats: stats(perfectSolves: 10)))
    }

    // MARK: — streak3

    @Test func streak3_notApplicable_at2() {
        #expect(!AchievementRules.isApplicable(.streak3, stats: stats(currentStreak: 2)))
    }

    @Test func streak3_applicable_at3() {
        #expect(AchievementRules.isApplicable(.streak3, stats: stats(currentStreak: 3)))
    }

    // MARK: — streak7

    @Test func streak7_notApplicable_at6() {
        #expect(!AchievementRules.isApplicable(.streak7, stats: stats(currentStreak: 6)))
    }

    @Test func streak7_applicable_at7() {
        #expect(AchievementRules.isApplicable(.streak7, stats: stats(currentStreak: 7)))
    }

    // MARK: — streak30

    @Test func streak30_notApplicable_at29() {
        #expect(!AchievementRules.isApplicable(.streak30, stats: stats(currentStreak: 29)))
    }

    @Test func streak30_applicable_at30() {
        #expect(AchievementRules.isApplicable(.streak30, stats: stats(currentStreak: 30)))
    }

    // MARK: — noHints10

    @Test func noHints10_notApplicable_at9() {
        #expect(!AchievementRules.isApplicable(.noHints10, stats: stats(hintFreeSolves: 9)))
    }

    @Test func noHints10_applicable_at10() {
        #expect(AchievementRules.isApplicable(.noHints10, stats: stats(hintFreeSolves: 10)))
    }

    // MARK: — speedSolver

    @Test func speedSolver_notApplicable_whenNoTime() {
        #expect(!AchievementRules.isApplicable(.speedSolver, stats: stats(fastestSolveSeconds: nil)))
    }

    @Test func speedSolver_notApplicable_at30Seconds() {
        #expect(!AchievementRules.isApplicable(.speedSolver, stats: stats(fastestSolveSeconds: 30)))
    }

    @Test func speedSolver_applicable_at29Seconds() {
        #expect(AchievementRules.isApplicable(.speedSolver, stats: stats(fastestSolveSeconds: 29)))
    }

    @Test func speedSolver_applicable_atZeroSeconds() {
        #expect(AchievementRules.isApplicable(.speedSolver, stats: stats(fastestSolveSeconds: 0)))
    }
}
