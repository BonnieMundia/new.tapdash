import SwiftUI

/// The Tap Dash game screen: a score bar on top and the play area below.
struct GameView: View {
    @State private var game = GameModel()

    var body: some View {
        VStack(spacing: 0) {
            scoreBar

            GeometryReader { proxy in
                ZStack {
                    if game.isPlaying {
                        target(in: proxy.size)
                    } else {
                        startPanel(in: proxy.size)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(.quaternary.opacity(0.4))
        }
        // Restarts whenever isPlaying changes, and is cancelled automatically when the round ends.
        .task(id: game.isPlaying) {
            await runTimer()
        }
        .sensoryFeedback(.impact, trigger: game.score)
    }

    // MARK: - Subviews

    private var scoreBar: some View {
        HStack {
            Label("\(game.score)", systemImage: "star.fill")
                .accessibilityLabel("Score")
                .accessibilityValue("\(game.score)")
                .accessibilityIdentifier("score")
            Spacer()
            Label("\(game.timeRemaining)s", systemImage: "timer")
                .foregroundStyle(game.timeRemaining <= 5 && game.isPlaying ? .red : .primary)
                .accessibilityLabel("Time remaining")
                .accessibilityValue("\(game.timeRemaining) seconds")
                .accessibilityIdentifier("time")
        }
        .font(.title2.bold().monospacedDigit())
        .padding()
    }

    private func target(in size: CGSize) -> some View {
        Circle()
            .fill(Color("TargetColor").gradient)
            .frame(width: GameModel.targetSize, height: GameModel.targetSize)
            .position(game.targetPosition)
            .animation(.snappy(duration: 0.15), value: game.targetPosition)
            .onTapGesture {
                game.hitTarget(in: size)
            }
            .accessibilityIdentifier("target")
            .accessibilityAddTraits(.isButton)
    }

    private func startPanel(in size: CGSize) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "bolt.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color("TargetColor"))

            Text("Tap Dash")
                .font(.largeTitle.bold())

            Label("Best: \(game.bestScore)", systemImage: "trophy.fill")
                .font(.headline)
                .foregroundStyle(.secondary)

            Button(game.bestScore == 0 && game.score == 0 ? "Start" : "Play Again") {
                game.start(in: size)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Color("TargetColor"))
            .accessibilityIdentifier("startButton")

            if game.bestScore > 0 {
                Button("Reset Best", role: .destructive) {
                    game.resetBestScore()
                }
                .font(.footnote)
            }
        }
        .padding()
    }

    // MARK: - Timer

    /// Ticks the game once per second while a round is in progress.
    private func runTimer() async {
        while game.isPlaying {
            do {
                try await Task.sleep(for: .seconds(1))
            } catch {
                return // The task was cancelled.
            }
            game.tick()
        }
    }
}

#Preview("Start screen") {
    GameView()
}

#Preview("Dark mode") {
    GameView()
        .preferredColorScheme(.dark)
}

#Preview("Large text") {
    GameView()
        .dynamicTypeSize(.accessibility2)
}
