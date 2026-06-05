// MARK: — LeaderboardID
// App Store Connect leaderboard IDs — must match what you configure in ASC.

enum LeaderboardID {
    static let totalLevels  = "snuglo.total.levels"
    static let fastestSolve = "snuglo.fastest.solve"
    static let bestStreak   = "snuglo.best.streak"
    /// Highest Endless level reached — Endless's "glory" board (it pays no currency).
    static let endlessBest  = "snuglo.endless.best"
    static let all: [String] = [totalLevels, fastestSolve, bestStreak, endlessBest]
}
