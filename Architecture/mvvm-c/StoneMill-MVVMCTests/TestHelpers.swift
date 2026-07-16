import Foundation
@testable import StoneMill_MVVMC

/// Helpers that let rules tests read like board diagrams.
///
/// A position is written as seven lines mirroring the physical board, with one
/// token per point: `X` for light, `O` for dark, and `.` for an empty point.
/// The rows hold 3, 3, 3, 6, 3, 3, and 3 tokens, walking the board from its
/// north edge to its south edge:
///
/// ```
/// X . O          outer 0  1  2
/// . X .          middle 8  9  10
/// . . .          inner 16 17 18
/// O . .  . . X   west to east: 7 15 23  19 11 3
/// . . .          inner 22 21 20
/// . . .          middle 14 13 12
/// . . X          outer 6  5  4
/// ```
enum BoardDiagram {

    /// The point indices of each diagram row, west to east.
    static let rowPoints: [[Int]] = [
        [0, 1, 2],
        [8, 9, 10],
        [16, 17, 18],
        [7, 15, 23, 19, 11, 3],
        [22, 21, 20],
        [14, 13, 12],
        [6, 5, 4],
    ]

    /// Parses a diagram into the 24 point occupancy array.
    ///
    /// Traps on malformed diagrams so a typo fails the test at its source.
    static func points(_ diagram: String) -> [PlayerColor?] {
        let lines = diagram
            .split(separator: "\n")
            .map { $0.split(separator: " ").map(String.init) }
            .filter { !$0.isEmpty }
        precondition(lines.count == rowPoints.count, "A board diagram needs exactly 7 rows, got \(lines.count)")

        var points = [PlayerColor?](repeating: nil, count: Board.pointCount)
        for (row, tokens) in lines.enumerated() {
            precondition(
                tokens.count == rowPoints[row].count,
                "Diagram row \(row) needs \(rowPoints[row].count) tokens, got \(tokens.count)"
            )
            for (column, token) in tokens.enumerated() {
                switch token {
                case "X": points[rowPoints[row][column]] = .light
                case "O": points[rowPoints[row][column]] = .dark
                case ".": break
                default: preconditionFailure("Unknown diagram token '\(token)'")
                }
            }
        }
        return points
    }
}

/// Builds a game state from a board diagram plus the handful of scalar fields
/// a rules test cares about.
func state(
    _ diagram: String,
    toMove: PlayerColor = .light,
    inHand: (light: Int, dark: Int) = (0, 0),
    pendingCapture: Bool = false
) -> GameState {
    var state = GameState.initial()
    state.points = BoardDiagram.points(diagram)
    state.lightInHand = inHand.light
    state.darkInHand = inHand.dark
    state.currentPlayer = toMove
    state.pendingCapture = pendingCapture
    return state
}

/// Applies a move that the test expects to be legal, trapping on rejection.
func applied(_ move: Move, to state: GameState) -> GameState {
    switch RulesEngine.apply(move, to: state) {
    case .success(let next):
        return next
    case .failure(let rejection):
        preconditionFailure("Expected \(move) to be legal, got \(rejection)")
    }
}

/// A deterministic random number generator (SplitMix64) so tests of the
/// computer opponent can assert exact outcomes.
struct SeededGenerator: RandomNumberGenerator {

    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
