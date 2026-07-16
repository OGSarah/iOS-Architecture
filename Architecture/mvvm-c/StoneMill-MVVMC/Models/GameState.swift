import Foundation

/// One of the two sides in a match.
nonisolated enum PlayerColor: String, Equatable, Codable, Sendable, CaseIterable {

    /// The sandstone colored side, which always moves first.
    case light

    /// The dark umber side.
    case dark

    /// The other side.
    var opponent: PlayerColor {
        self == .light ? .dark : .light
    }

    /// A short display name for the side.
    var displayName: String {
        self == .light ? "Light" : "Dark"
    }
}

/// A single action a player can take.
nonisolated enum Move: Equatable, Hashable, Codable, Sendable {

    /// Place a piece from hand onto an empty point during the placing phase.
    case place(at: Int)

    /// Slide a piece to an adjacent empty point during the moving phase.
    case slide(from: Int, to: Int)

    /// Move a piece to any empty point, legal only while flying.
    case fly(from: Int, to: Int)

    /// Remove an enemy piece after forming a mill.
    case capture(at: Int)
}

/// Why a match ended.
nonisolated enum WinReason: String, Equatable, Codable, Sendable {

    /// The loser was reduced to two pieces and can no longer form a mill.
    case opponentReducedToTwo

    /// The loser had no legal move on their turn. Being blocked is a loss, not a stalemate.
    case opponentBlocked

    /// A sentence fragment describing the reason, suitable for status text.
    var summary: String {
        switch self {
        case .opponentReducedToTwo: "reduced to two stones"
        case .opponentBlocked: "left without a legal move"
        }
    }
}

/// The final outcome of a match.
nonisolated struct GameResult: Equatable, Codable, Sendable {

    /// The winning side.
    let winner: PlayerColor

    /// How the win was achieved.
    let reason: WinReason
}

/// The complete, value typed state of one match.
///
/// `GameState` is pure data: whose turn it is, which phase each player is in,
/// how many pieces remain in each hand, and what sits on each of the 24
/// points. Every mutation goes through ``RulesEngine``, which consumes one
/// state and produces the next.
nonisolated struct GameState: Equatable, Codable, Identifiable, Sendable {

    /// A stable identity for the match, referenced by `Route.board`.
    let id: UUID

    /// The occupant of each of the 24 points, indexed by ``Board`` point index.
    var points: [PlayerColor?]

    /// Pieces the light player has not yet placed.
    var lightInHand: Int

    /// Pieces the dark player has not yet placed.
    var darkInHand: Int

    /// The side whose turn it is.
    var currentPlayer: PlayerColor

    /// True when the current player just formed a mill and must capture before the turn passes.
    var pendingCapture: Bool

    /// The number of placements and movements made so far. Captures are part of the move that earned them.
    var moveCount: Int

    /// The outcome, once the match has ended.
    var result: GameResult?

    /// A fresh match with all 18 pieces in hand and light to move.
    static func initial(id: UUID = UUID()) -> GameState {
        GameState(
            id: id,
            points: Array(repeating: nil, count: Board.pointCount),
            lightInHand: Board.piecesPerPlayer,
            darkInHand: Board.piecesPerPlayer,
            currentPlayer: .light,
            pendingCapture: false,
            moveCount: 0,
            result: nil
        )
    }

    /// The number of pieces a player has yet to place.
    func piecesInHand(for player: PlayerColor) -> Int {
        player == .light ? lightInHand : darkInHand
    }

    /// Updates the number of pieces a player has yet to place.
    mutating func setPiecesInHand(_ count: Int, for player: PlayerColor) {
        if player == .light { lightInHand = count } else { darkInHand = count }
    }

    /// The number of pieces a player has on the board.
    func pieceCount(for player: PlayerColor) -> Int {
        points.count { $0 == player }
    }

    /// The point indices occupied by a player.
    func points(of player: PlayerColor) -> [Int] {
        Board.allPoints.filter { points[$0] == player }
    }

    /// The point indices with no piece on them.
    var emptyPoints: [Int] {
        Board.allPoints.filter { points[$0] == nil }
    }

    /// The phase a specific player is in.
    ///
    /// Flying is per player, not per game: a player is flying once their hand
    /// is empty and exactly three of their pieces remain on the board.
    func phase(for player: PlayerColor) -> GamePhase {
        if result != nil { return .gameOver }
        if piecesInHand(for: player) > 0 { return .placing }
        return pieceCount(for: player) == 3 ? .flying : .moving
    }

    /// The overall phase of the game, driven by the current player.
    var phase: GamePhase {
        if result != nil { return .gameOver }
        if lightInHand > 0 || darkInHand > 0 { return .placing }
        return phase(for: currentPlayer)
    }
}

/// The kind of opponent chosen on the setup screen.
nonisolated enum OpponentKind: String, Equatable, Codable, Sendable, CaseIterable {

    /// Two people sharing the same table, taking turns.
    case hotSeat

    /// A single player against the built in greedy engine.
    case computer

    /// A short display name for the opponent kind.
    var displayName: String {
        self == .hotSeat ? "Two players" : "Versus Millstone"
    }
}

/// Everything the setup screen decides before a match starts.
nonisolated struct MatchConfiguration: Equatable, Codable, Sendable {

    /// The name the computer opponent plays under.
    static let computerName = "Millstone"

    /// The kind of opponent.
    var opponentKind: OpponentKind

    /// The display name of the light player.
    var lightPlayerName: String

    /// The display name of the dark player. Fixed to ``computerName`` when playing the engine.
    var darkPlayerName: String

    /// The display name for a side.
    func name(for player: PlayerColor) -> String {
        player == .light ? lightPlayerName : darkPlayerName
    }
}

/// The value payload a finished match reports upward.
///
/// The board never touches SwiftData. The coordinator converts an outcome
/// into a persisted `MatchRecord`.
nonisolated struct MatchOutcome: Equatable, Sendable {

    /// The display name of the winner.
    let winnerName: String

    /// The display name of the loser.
    let loserName: String

    /// The side that won.
    let winner: PlayerColor

    /// How the match was won.
    let reason: WinReason

    /// The kind of opponent that was faced.
    let opponentKind: OpponentKind

    /// The number of placements and movements in the match.
    let moveCount: Int

    /// The wall clock length of the match in seconds.
    let duration: TimeInterval
}

#if DEBUG

/// Scenarios the app can be launched into for UI tests and screenshots.
///
/// Passing one of these raw values in the `UITEST_SCENARIO` launch environment
/// makes the coordinator seed a fixture state on first appearance, so no test
/// has to play nine placements to reach the flying phase.
nonisolated enum UITestScenario: String, CaseIterable, Sendable {

    /// The plain setup window with nothing seeded.
    case freshSetup

    /// A board volume in the middle of the placing phase.
    case midPlacing

    /// A board where light is flying and dark is still sliding.
    case flying

    /// A board where light can complete a mill and win with a single capture.
    case oneMoveToWin

    /// A finished match showing the results card.
    case matchOver

    /// The excavation space open on the Kurna temple site.
    case excavationKurna

    /// The excavation space open on the cloister bench site.
    case excavationCloister

    /// The scenario requested by the current process environment, if any.
    static var current: UITestScenario? {
        ProcessInfo.processInfo.environment["UITEST_SCENARIO"].flatMap(UITestScenario.init(rawValue:))
    }
}

nonisolated extension GameState {

    /// A deterministic board fixture for a UI test scenario.
    ///
    /// Returns nil for scenarios that do not need a seeded board. The unit
    /// tests pin these fixtures so a change here cannot silently break a
    /// UI test flow.
    static func fixture(for scenario: UITestScenario) -> GameState? {
        var state = GameState.initial()
        switch scenario {
        case .freshSetup:
            return nil

        case .midPlacing:
            for point in [0, 1, 12, 22] { state.points[point] = .light }
            for point in [2, 5, 9, 19] { state.points[point] = .dark }
            state.lightInHand = 5
            state.darkInHand = 5
            state.currentPlayer = .light
            state.moveCount = 8
            return state

        case .flying:
            for point in [0, 4, 9] { state.points[point] = .light }
            for point in [2, 5, 8, 12, 16, 20] { state.points[point] = .dark }
            state.lightInHand = 0
            state.darkInHand = 0
            state.currentPlayer = .light
            state.moveCount = 34
            return state

        case .oneMoveToWin:
            for point in [0, 1, 3] { state.points[point] = .light }
            for point in [8, 16, 20] { state.points[point] = .dark }
            state.lightInHand = 0
            state.darkInHand = 0
            state.currentPlayer = .light
            state.moveCount = 40
            return state

        case .matchOver, .excavationKurna, .excavationCloister:
            for point in [0, 1, 2] { state.points[point] = .light }
            for point in [16, 20] { state.points[point] = .dark }
            state.lightInHand = 0
            state.darkInHand = 0
            state.currentPlayer = .light
            state.moveCount = 42
            state.result = GameResult(winner: .light, reason: .opponentReducedToTwo)
            return state
        }
    }

    /// The hot seat configuration every fixture scenario plays under.
    static let fixtureConfiguration = MatchConfiguration(
        opponentKind: .hotSeat,
        lightPlayerName: "Rowan",
        darkPlayerName: "Sage"
    )
}

#endif
