import CoreGraphics
import Foundation
import Testing
@testable import new_tapdash

/// Unit tests for Tap Dash's game rules.
/// Swift Testing creates a fresh instance of this struct for every test, so each test gets its own `defaults`.
@MainActor
@Suite("Game rules")
struct GameModelTests {
    let screen = CGSize(width: 400, height: 800)

    /// A throwaway UserDefaults store, so tests never touch the real saved best score.
    let defaults: UserDefaults

    init() throws {
        defaults = try #require(UserDefaults(suiteName: "TapDashTests-\(UUID().uuidString)"))
    }

    /// Creates a game whose random numbers are predictable: always the lowest allowed value.
    func makeGame(random: @escaping (ClosedRange<CGFloat>) -> CGFloat = { $0.lowerBound }) -> GameModel {
        GameModel(defaults: defaults, random: random)
    }

    /// Plays a whole round: `taps` hits, then lets the timer run out.
    func playRound(_ game: GameModel, taps: Int) {
        game.start(in: screen)
        for _ in 0..<taps {
            game.hitTarget(in: screen)
        }
        for _ in 0..<GameModel.roundLength {
            game.tick()
        }
    }

    // MARK: - Starting

    @Test("A new game is waiting to start")
    func newGameIsIdle() {
        let game = makeGame()

        #expect(game.isPlaying == false)
        #expect(game.score == 0)
        #expect(game.bestScore == 0)
        #expect(game.timeRemaining == GameModel.roundLength)
    }

    @Test("Starting resets the score and timer")
    func startResetsRound() {
        let game = makeGame()
        playRound(game, taps: 4)

        game.start(in: screen)

        #expect(game.isPlaying)
        #expect(game.score == 0)
        #expect(game.timeRemaining == GameModel.roundLength)
    }

    // MARK: - Tapping

    @Test("Each tap scores one point", arguments: [0, 1, 5, 20])
    func tapsAddPoints(taps: Int) {
        let game = makeGame()
        game.start(in: screen)

        for _ in 0..<taps {
            game.hitTarget(in: screen)
        }

        #expect(game.score == taps)
    }

    @Test("Taps are ignored when no round is running")
    func tapIgnoredWhenIdle() {
        let game = makeGame()

        game.hitTarget(in: screen)

        #expect(game.score == 0)
    }

    @Test("Tapping moves the target")
    func tapMovesTarget() {
        // Each move asks for two random numbers (x, then y). The first move gets the lowest
        // allowed values and every later move gets the highest, so the position must change.
        var calls = 0
        let game = makeGame { range in
            calls += 1
            return calls <= 2 ? range.lowerBound : range.upperBound
        }
        game.start(in: screen)
        let before = game.targetPosition

        game.hitTarget(in: screen)

        #expect(game.targetPosition != before)
    }

    @Test(
        "The whole target stays inside the play area",
        arguments: [CGSize(width: 400, height: 800), CGSize(width: 800, height: 400), CGSize(width: 70, height: 70)],
        [true, false]
    )
    func targetStaysOnScreen(size: CGSize, useUpperBound: Bool) {
        let game = makeGame { useUpperBound ? $0.upperBound : $0.lowerBound }
        let radius = GameModel.targetSize / 2

        game.start(in: size)

        #expect(game.targetPosition.x >= radius)
        #expect(game.targetPosition.x <= size.width - radius)
        #expect(game.targetPosition.y >= radius)
        #expect(game.targetPosition.y <= size.height - radius)
    }

    // MARK: - Timer

    @Test("Each tick removes one second")
    func tickCountsDown() {
        let game = makeGame()
        game.start(in: screen)

        game.tick()

        #expect(game.timeRemaining == GameModel.roundLength - 1)
        #expect(game.isPlaying)
    }

    @Test("The round ends exactly when the timer reaches zero")
    func roundEndsAtZero() {
        let game = makeGame()
        game.start(in: screen)

        for _ in 0..<(GameModel.roundLength - 1) {
            game.tick()
        }
        #expect(game.isPlaying, "One second should still be left")

        game.tick()
        #expect(game.isPlaying == false)
        #expect(game.timeRemaining == 0)
    }

    // MARK: - Best score

    @Test("A new best score is saved and survives a relaunch")
    func bestScoreIsSaved() {
        let game = makeGame()
        playRound(game, taps: 7)

        #expect(game.bestScore == 7)

        // A second model with the same store behaves like the app after a relaunch.
        let relaunched = makeGame()
        #expect(relaunched.bestScore == 7)
    }

    @Test("A lower score does not replace the best")
    func lowerScoreKeepsBest() {
        let game = makeGame()
        playRound(game, taps: 9)
        playRound(game, taps: 3)

        #expect(game.bestScore == 9)
    }

    @Test("Resetting clears the saved best score")
    func resetClearsBest() {
        let game = makeGame()
        playRound(game, taps: 5)

        game.resetBestScore()

        #expect(game.bestScore == 0)
        #expect(makeGame().bestScore == 0)
    }
}
