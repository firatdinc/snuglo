import Testing
import Foundation
import Observation
@testable import SnugloApp

// MARK: — MockGCForVM

@Observable
@MainActor
final class MockGCForVM: GameCenterServicing {

    var authState: GameCenterAuthState = .idle
    var nextAuthState: GameCenterAuthState = .signedIn(displayName: "You")
    var nextEntries: [GameCenterEntry] = []
    var shouldThrow = false

    func authenticate() async {
        authState = nextAuthState
    }

    func submit(score: Int, leaderboardID: String) async throws {}

    func loadEntries(for leaderboardID: String) async throws -> [GameCenterEntry] {
        if shouldThrow { throw URLError(.notConnectedToInternet) }
        return nextEntries
    }
}

// MARK: — LeaderboardViewModelTests

@MainActor
struct LeaderboardViewModelTests {

    private func makeProgress() -> ProgressStore {
        ProgressStore(
            defaults: UserDefaults(suiteName: "LBVMTests.\(UUID().uuidString)")!,
            key: "lbvm.test"
        )
    }

    // MARK: — load() state transitions

    @Test func load_signedIn_withEntries_setsLoaded() async {
        let gc = MockGCForVM()
        gc.nextEntries = [
            GameCenterEntry(id: "a", rank: 1, displayName: "A", score: 10, isLocalPlayer: true, isSimulated: false)
        ]
        let vm = LeaderboardViewModel(gameCenter: gc, progress: makeProgress())
        await vm.load()
        if case .loaded(let entries) = vm.loadState {
            #expect(entries.count == 1)
        } else {
            Issue.record("Expected .loaded, got \(vm.loadState)")
        }
    }

    @Test func load_signedIn_emptyEntries_setsEmpty() async {
        let gc = MockGCForVM()
        gc.nextEntries = []
        let vm = LeaderboardViewModel(gameCenter: gc, progress: makeProgress())
        await vm.load()
        #expect(vm.loadState == .empty)
    }

    @Test func load_notSignedIn_setsNotSignedIn() async {
        let gc = MockGCForVM()
        gc.nextAuthState = .notSignedIn
        let vm = LeaderboardViewModel(gameCenter: gc, progress: makeProgress())
        await vm.load()
        #expect(vm.loadState == .notSignedIn)
    }

    @Test func load_loadThrows_setsError() async {
        let gc = MockGCForVM()
        gc.shouldThrow = true
        let vm = LeaderboardViewModel(gameCenter: gc, progress: makeProgress())
        await vm.load()
        if case .error = vm.loadState { } else {
            Issue.record("Expected .error, got \(vm.loadState)")
        }
    }

    @Test func load_gcError_setsErrorWithMessage() async {
        let gc = MockGCForVM()
        gc.nextAuthState = .error("fail")
        let vm = LeaderboardViewModel(gameCenter: gc, progress: makeProgress())
        await vm.load()
        if case .error(let msg) = vm.loadState {
            #expect(msg == "fail")
        } else {
            Issue.record("Expected .error, got \(vm.loadState)")
        }
    }

    @Test func load_idleAuth_callsAuthenticate() async {
        let gc = MockGCForVM()
        gc.authState = .idle
        gc.nextAuthState = .signedIn(displayName: "X")
        gc.nextEntries = []
        let vm = LeaderboardViewModel(gameCenter: gc, progress: makeProgress())
        await vm.load()
        #expect(gc.authState == .signedIn(displayName: "X"))
    }

    // MARK: — fallbackEntries

    @Test func fallbackEntries_has5Entries() {
        let vm = LeaderboardViewModel(gameCenter: MockGCForVM(), progress: makeProgress())
        #expect(vm.fallbackEntries.count == 5)
    }

    @Test func fallbackEntries_ranksAreConsecutiveFrom1() {
        let vm = LeaderboardViewModel(gameCenter: MockGCForVM(), progress: makeProgress())
        let ranks = vm.fallbackEntries.map(\.rank)
        #expect(ranks == Array(1...5))
    }

    @Test func fallbackEntries_exactlyOneLocalPlayer() {
        let vm = LeaderboardViewModel(gameCenter: MockGCForVM(), progress: makeProgress())
        let count = vm.fallbackEntries.filter(\.isLocalPlayer).count
        #expect(count == 1)
    }

    @Test func fallbackEntries_fastestSolve_nonZeroScoresSortedAscending() {
        let vm = LeaderboardViewModel(gameCenter: MockGCForVM(), progress: makeProgress())
        vm.selectedBoard = LeaderboardID.fastestSolve
        let nonZeroScores = vm.fallbackEntries
            .filter { !$0.isLocalPlayer && $0.score > 0 }
            .map(\.score)
        let isSorted = zip(nonZeroScores, nonZeroScores.dropFirst()).allSatisfy { $0 < $1 }
        #expect(isSorted)
    }

    @Test func fallbackEntries_boardSwitch_changesScores() {
        let vm = LeaderboardViewModel(gameCenter: MockGCForVM(), progress: makeProgress())
        vm.selectedBoard = LeaderboardID.totalLevels
        let totalScores = vm.fallbackEntries.map(\.score)
        vm.selectedBoard = LeaderboardID.fastestSolve
        let fastestScores = vm.fallbackEntries.map(\.score)
        #expect(totalScores != fastestScores)
    }
}
