import Foundation
import Observation

/// Presentation state for the board volume, and the only type in the app that
/// knows both the rules and the tabletop.
///
/// The ViewModel holds the current ``GameState``, runs every proposed move
/// through ``RulesEngine``, and publishes display ready values: a status line,
/// the points a player may act on, and the pieces a mill allows them to take.
/// It reports a finished match upward through ``didFinishMatch`` exactly once
/// and has no reference to any other screen and no way to open one.
@Observable
@MainActor
final class BoardViewModel {

    /// Where the select, move, capture loop currently stands.
    enum InteractionState: Equatable {

        /// Waiting for the player to pick a piece, or a point while placing.
        case awaitingSelection

        /// A piece at the associated point is lifted and waiting for a destination.
        case pieceSelected(Int)

        /// A mill just formed; the player must pick an enemy piece to remove.
        case awaitingCapture

        /// The match has ended and the results card is showing.
        case matchOver
    }

    /// The authoritative state of the match.
    private(set) var gameState: GameState

    /// The current step of the interaction loop.
    private(set) var interaction: InteractionState

    /// The mill line that most recently completed, for highlighting.
    private(set) var highlightedMill: [Int]?

    /// The configuration the match was started with.
    let configuration: MatchConfiguration

    /// Reports the outcome upward exactly once when the match ends. Assigned by the coordinator.
    var didFinishMatch: ((MatchOutcome) -> Void)?

    /// Reports that the player asked to visit the excavation after a match.
    /// Assigned by the coordinator; the board has no idea what it opens.
    var didRequestExcavation: (() -> Void)?

    /// Notifies the tabletop renderer after every accepted state change.
    ///
    /// This closure is the seam that keeps TabletopKit out of the ViewModel:
    /// the tabletop game subscribes here and syncs its entities to the state.
    var onStateChange: ((GameState) -> Void)?

    /// The in flight computer turn, exposed so tests can await it.
    private(set) var computerMoveTask: Task<Void, Never>?

    /// The pause before each computer action, shortened to zero in tests.
    var computerMoveDelay: Duration = .milliseconds(700)

    private let startDate: Date
    private var finishReported = false
    private var randomGenerator = SystemRandomNumberGenerator()

    /// Creates a board for a configuration, optionally seeded with a fixture state.
    init(configuration: MatchConfiguration, initialState: GameState = .initial()) {
        self.configuration = configuration
        self.gameState = initialState
        self.startDate = .now
        if initialState.result != nil {
            self.interaction = .matchOver
            self.finishReported = true
        } else if initialState.pendingCapture {
            self.interaction = .awaitingCapture
        } else {
            self.interaction = .awaitingSelection
        }
    }

    // MARK: Display values

    /// A single line describing whose turn it is and what they are doing.
    var statusText: String {
        if let result = gameState.result {
            let loser = configuration.name(for: result.winner.opponent)
            return "\(configuration.name(for: result.winner)) wins. \(loser) was \(result.reason.summary)."
        }
        let name = configuration.name(for: gameState.currentPlayer)
        if gameState.pendingCapture {
            return "\(name) formed a mill and removes a stone"
        }
        switch gameState.phase(for: gameState.currentPlayer) {
        case .placing:
            let left = gameState.piecesInHand(for: gameState.currentPlayer)
            return "\(name) places a stone (\(left) in hand)"
        case .moving:
            return "\(name) slides a stone"
        case .flying:
            return "\(name) is flying"
        case .gameOver:
            return "The match is over"
        }
    }

    /// The points the player may currently act on: empty points while placing,
    /// movable pieces while selecting, and destinations once a piece is lifted.
    var selectablePoints: Set<Int> {
        guard isHumanTurn else { return [] }
        switch interaction {
        case .matchOver, .awaitingCapture:
            return []
        case .pieceSelected(let point):
            return destinations(forPieceAt: point)
        case .awaitingSelection:
            if gameState.phase(for: gameState.currentPlayer) == .placing {
                return Set(gameState.emptyPoints)
            }
            let sources = RulesEngine.legalMoves(in: gameState).compactMap { move -> Int? in
                switch move {
                case .slide(let from, _), .fly(let from, _): from
                case .place, .capture: nil
                }
            }
            return Set(sources)
        }
    }

    /// The enemy pieces the player may remove while a mill waits.
    var capturablePieces: Set<Int> {
        guard interaction == .awaitingCapture, isHumanTurn else { return [] }
        return Set(RulesEngine.capturablePoints(in: gameState))
    }

    /// The point currently lifted, if any.
    var selectedPoint: Int? {
        if case .pieceSelected(let point) = interaction { return point }
        return nil
    }

    /// Whether the side to move is controlled by a person at the table.
    var isHumanTurn: Bool {
        guard gameState.result == nil else { return false }
        return configuration.opponentKind == .hotSeat || gameState.currentPlayer == .light
    }

    // MARK: Intents

    /// Whether the piece at a point may be lifted right now.
    func canLift(pieceAt point: Int) -> Bool {
        guard isHumanTurn, interaction != .awaitingCapture, gameState.result == nil else { return false }
        guard Board.allPoints.contains(point), gameState.points[point] == gameState.currentPlayer else { return false }
        return !destinations(forPieceAt: point).isEmpty
    }

    /// The points the piece at a point may legally move to.
    func destinations(forPieceAt point: Int) -> Set<Int> {
        let targets = RulesEngine.legalMoves(in: gameState).compactMap { move -> Int? in
            switch move {
            case .slide(let from, let to) where from == point: to
            case .fly(let from, let to) where from == point: to
            default: nil
            }
        }
        return Set(targets)
    }

    /// Places a stone from hand. Returns whether the rules accepted it.
    @discardableResult
    func commitPlace(at point: Int) -> Bool {
        commit(.place(at: point))
    }

    /// Moves a stone, choosing a slide or a flight from the player's phase.
    @discardableResult
    func commitMove(from: Int, to: Int) -> Bool {
        let move: Move = Board.isAdjacent(from, to) ? .slide(from: from, to: to) : .fly(from: from, to: to)
        return commit(move)
    }

    /// Removes an enemy stone after a mill. Returns whether the rules accepted it.
    @discardableResult
    func commitCapture(at point: Int) -> Bool {
        commit(.capture(at: point))
    }

    /// Drives the select, move, capture loop from a plain tap on a point.
    ///
    /// This is the tap fallback the tabletop interaction handler and the
    /// debug control strip both use: while placing it places, while moving it
    /// selects a piece and then a destination, and while a mill waits it
    /// captures.
    func pointTapped(_ point: Int) {
        guard isHumanTurn, gameState.result == nil else { return }
        switch interaction {
        case .matchOver:
            return
        case .awaitingCapture:
            commitCapture(at: point)
        case .awaitingSelection:
            if gameState.phase(for: gameState.currentPlayer) == .placing {
                commitPlace(at: point)
            } else if canLift(pieceAt: point) {
                interaction = .pieceSelected(point)
            }
        case .pieceSelected(let selected):
            if point == selected {
                interaction = .awaitingSelection
            } else if destinations(forPieceAt: selected).contains(point) {
                commitMove(from: selected, to: point)
            } else if canLift(pieceAt: point) {
                interaction = .pieceSelected(point)
            }
        }
    }

    /// Forwards the excavation intent upward.
    func excavationTapped() {
        didRequestExcavation?()
    }

    /// Starts the match over with the same configuration.
    func resetMatch() {
        computerMoveTask?.cancel()
        computerMoveTask = nil
        gameState = .initial()
        interaction = .awaitingSelection
        highlightedMill = nil
        finishReported = false
        onStateChange?(gameState)
    }

    // MARK: Applying moves

    /// Runs a move through the rules engine and, when accepted, publishes the
    /// new state, reports a finished match, and schedules the computer's reply.
    @discardableResult
    private func commit(_ move: Move) -> Bool {
        guard case .success(let next) = RulesEngine.apply(move, to: gameState) else {
            return false
        }
        if case .capture = move {
            highlightedMill = nil
        } else if let destination = destination(of: move) {
            highlightedMill = RulesEngine.millsCompleted(at: destination, in: next).first
        }
        gameState = next
        if next.result != nil {
            interaction = .matchOver
        } else if next.pendingCapture {
            interaction = .awaitingCapture
        } else {
            interaction = .awaitingSelection
        }
        onStateChange?(next)
        reportFinishIfNeeded()
        scheduleComputerTurnIfNeeded()
        return true
    }

    private func destination(of move: Move) -> Int? {
        switch move {
        case .place(let at): at
        case .slide(_, let to), .fly(_, let to): to
        case .capture: nil
        }
    }

    /// Fires ``didFinishMatch`` exactly once per finished match.
    private func reportFinishIfNeeded() {
        guard let result = gameState.result, !finishReported else { return }
        finishReported = true
        let outcome = MatchOutcome(
            winnerName: configuration.name(for: result.winner),
            loserName: configuration.name(for: result.winner.opponent),
            winner: result.winner,
            reason: result.reason,
            opponentKind: configuration.opponentKind,
            moveCount: gameState.moveCount,
            duration: Date.now.timeIntervalSince(startDate)
        )
        didFinishMatch?(outcome)
    }

    // MARK: Computer opponent

    /// Whether the engine controls the side to move.
    private var isComputerTurn: Bool {
        configuration.opponentKind == .computer
            && gameState.currentPlayer == .dark
            && gameState.result == nil
    }

    /// Plays the engine's whole turn (a move plus any capture it earned) after
    /// a short pause, so the reply reads as deliberate rather than instant.
    private func scheduleComputerTurnIfNeeded() {
        guard isComputerTurn, computerMoveTask == nil else { return }
        computerMoveTask = Task { [weak self] in
            defer { self?.computerMoveTask = nil }
            while let self, self.isComputerTurn, !Task.isCancelled {
                try? await Task.sleep(for: self.computerMoveDelay)
                guard !Task.isCancelled, self.isComputerTurn else { return }
                guard let move = RulesEngine.suggestedMove(for: self.gameState, using: &self.randomGenerator) else {
                    return
                }
                self.commit(move)
            }
        }
    }
}
