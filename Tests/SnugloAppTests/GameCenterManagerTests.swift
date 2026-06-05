import Testing
import Foundation
import Observation
@testable import SnugloApp

// MARK: — MockGameCenterService

@Observable
@MainActor
final class MockGameCenterService: GameCenterServicing {

    private(set) var authState: GameCenterAuthState = .idle
    var nextAuthState: GameCenterAuthState = .signedIn(displayName: "TestPlayer")
    var lastSubmittedScore: Int?
    var lastSubmittedID: String?
    var loadedEntries: [GameCenterEntry] = []
    var shouldThrowOnLoad = false
    var authenticateCalled = false

    func authenticate() async {
        authenticateCalled = true
        authState = nextAuthState
    }

    func submit(score: Int, leaderboardID: String) async throws {
        lastSubmittedScore = score
        lastSubmittedID = leaderboardID
    }

    func loadEntries(for leaderboardID: String) async throws -> [GameCenterEntry] {
        if shouldThrowOnLoad { throw URLError(.notConnectedToInternet) }
        return loadedEntries
    }

    var lastReportedAchievementID: String?
    func report(achievementID: String, percentComplete: Double) async {
        lastReportedAchievementID = achievementID
    }
}

// MARK: — GameCenterManagerTests

@MainActor
struct GameCenterManagerTests {

    @Test func authenticate_setsSignedInState() async {
        let mock = MockGameCenterService()
        await mock.authenticate()
        #expect(mock.authState == .signedIn(displayName: "TestPlayer"))
    }

    @Test func authenticate_setsCalled() async {
        let mock = MockGameCenterService()
        await mock.authenticate()
        #expect(mock.authenticateCalled == true)
    }

    @Test func submit_recordsScoreAndID() async throws {
        let mock = MockGameCenterService()
        try await mock.submit(score: 42, leaderboardID: LeaderboardID.totalLevels)
        #expect(mock.lastSubmittedScore == 42)
        #expect(mock.lastSubmittedID == LeaderboardID.totalLevels)
    }

    @Test func loadEntries_returnsConfiguredEntries() async throws {
        let mock = MockGameCenterService()
        mock.loadedEntries = [
            GameCenterEntry(
                id: "a", rank: 1, displayName: "Alice",
                score: 100, isLocalPlayer: false, isSimulated: false
            )
        ]
        let result = try await mock.loadEntries(for: LeaderboardID.totalLevels)
        #expect(result.count == 1)
        #expect(result[0].id == "a")
    }

    @Test func loadEntries_whenThrows_propagatesError() async {
        let mock = MockGameCenterService()
        mock.shouldThrowOnLoad = true
        await #expect(throws: (any Error).self) {
            _ = try await mock.loadEntries(for: LeaderboardID.totalLevels)
        }
    }

    @Test func leaderboardIDs_allContainsAll() {
        #expect(LeaderboardID.all.count == 4)
        #expect(LeaderboardID.all.contains(LeaderboardID.totalLevels))
        #expect(LeaderboardID.all.contains(LeaderboardID.fastestSolve))
        #expect(LeaderboardID.all.contains(LeaderboardID.bestStreak))
        #expect(LeaderboardID.all.contains(LeaderboardID.endlessBest))
    }
}
