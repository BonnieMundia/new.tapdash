import CoreGraphics
import Foundation
import Observation
import OSLog
import Playgrounds

/// All of Tap Dash's rules live here, separate from the UI,
/// so they can be tried in a playground and covered by unit tests.
@Observable
final class GameModel {
    /// How long one round lasts, in seconds.
    static let roundLength = 30

    /// Diameter of the tappable circle, in points.
    static let targetSize: CGFloat = 70

    /// The UserDefaults key the best score is saved under.
    static let bestScoreKey = "bestScore"

    /// Messages appear in Xcode's debug console, where they can be filtered by category.
    private static let logger = Logger(subsystem: "TapDash", category: "Game")

    private(set) var score = 0
    private(set) var bestScore: Int
    private(set) var timeRemaining = GameModel.roundLength
    private(set) var isPlaying = false
    private(set) var targetPosition: CGPoint = .zero

    /// Where the best score is saved between launches. Injected so tests can use a throwaway store.
    private let defaults: UserDefaults

    /// Source of random numbers. Injected so tests can make the target's position predictable.
    private let random: (ClosedRange<CGFloat>) -> CGFloat

    init(
        defaults: UserDefaults = .standard,
        random: @escaping (ClosedRange<CGFloat>) -> CGFloat = { CGFloat.random(in: $0) }
    ) {
        self.defaults = defaults
        self.random = random
        // integer(forKey:) returns 0 if nothing has been saved yet.
        self.bestScore = defaults.integer(forKey: GameModel.bestScoreKey)
    }

    /// Resets the round and places the first target inside `size`.
    func start(in size: CGSize) {
        score = 0
        timeRemaining = GameModel.roundLength
        isPlaying = true
        moveTarget(in: size)
        GameModel.logger.info("Round started in a \(size.width) × \(size.height) play area")
    }

    /// Called when the player hits the circle: award a point and jump somewhere new.
    func hitTarget(in size: CGSize) {
        guard isPlaying else { return }
        score += 1
        moveTarget(in: size)
    }

    /// Called once per second by the view's timer.
    func tick() {
        guard isPlaying else { return }
        timeRemaining -= 1
        if timeRemaining <= 0 {
            end()
        }
    }

    /// Picks a random point that keeps the whole circle on screen.
    func moveTarget(in size: CGSize) {
        let radius = GameModel.targetSize / 2
        let maxX = max(radius, size.width - radius)
        let maxY = max(radius, size.height - radius)
        targetPosition = CGPoint(x: random(radius...maxX), y: random(radius...maxY))
    }

    private func end() {
        isPlaying = false
        timeRemaining = 0
        GameModel.logger.info("Round over. Score: \(self.score), previous best: \(self.bestScore)")
        if score > bestScore {
            bestScore = score
            defaults.set(bestScore, forKey: GameModel.bestScoreKey)
            GameModel.logger.notice("New best score saved: \(self.bestScore)")
        }
    }

    /// Clears the saved best score.
    func resetBestScore() {
        bestScore = 0
        defaults.removeObject(forKey: GameModel.bestScoreKey)
    }
}

// Lesson 2: open the Canvas (⌥⌘↩) to see each line's value without running the app.
#Playground {
    // A throwaway store, so the playground never touches the app's real saved score.
    let game = GameModel(defaults: UserDefaults(suiteName: "Playground") ?? .standard)
    game.resetBestScore() // Start each playground run from 0.
    let screen = CGSize(width: 400, height: 800)

    game.start(in: screen)
    let firstTarget = game.targetPosition
    print("First target at", firstTarget)

    game.hitTarget(in: screen)
    game.hitTarget(in: screen)
    game.hitTarget(in: screen)
    print("Score after 3 taps:", game.score)
    print("Target moved:", game.targetPosition != firstTarget)

    for _ in 0..<GameModel.roundLength {
        game.tick()
    }
    print("Still playing:", game.isPlaying, "Best:", game.bestScore)

    game.hitTarget(in: screen) // Ignored: the round is over.
    print("Score after game over:", game.score)
}
