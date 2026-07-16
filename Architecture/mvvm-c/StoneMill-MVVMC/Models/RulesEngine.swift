import Foundation

/// Why the rules engine refused a proposed move.
nonisolated enum MoveRejection: Error, Equatable, Sendable {

    /// The point index is outside the board.
    case invalidPoint

    /// The piece at the source point does not belong to the current player,
    /// or a capture targeted the current player's own piece.
    case notYourPiece

    /// There is no piece at the referenced point.
    case noPieceAtPoint

    /// The destination point already holds a piece.
    case pointOccupied

    /// A slide was proposed between two points that no line connects.
    case notAdjacent

    /// A mill is waiting to be resolved; the only legal move is a capture.
    case mustCaptureFirst

    /// The targeted piece is protected because it stands in a mill and not
    /// every enemy piece is in a mill.
    case cannotCaptureFromMill

    /// The move does not belong to the player's current phase.
    case wrongPhase

    /// The match already has a result.
    case gameIsOver
}

/// Every rule of Nine Men's Morris, as pure static functions.
///
/// The engine takes a ``GameState`` and a proposed ``Move`` and returns either
/// a new state or a rejection reason. There is no mutation, no async, and no
/// UI import anywhere in this file. The rules that carry the strategy all live
/// here: a mill that is broken and immediately re-formed still captures, a
/// piece standing in a mill cannot be captured unless every enemy piece is in
/// a mill, a player reduced to exactly three pieces may fly to any empty
/// point, and a player with no legal move loses outright.
nonisolated enum RulesEngine {

    // MARK: Legal moves

    /// Every move the current player may legally make.
    ///
    /// When a mill is pending, the only legal moves are captures. Otherwise
    /// the moves follow the current player's own phase: placements while their
    /// hand is not empty, slides along lines while they have more than three
    /// pieces, and flights to any empty point once they are down to three.
    static func legalMoves(in state: GameState) -> [Move] {
        guard state.result == nil else { return [] }
        if state.pendingCapture {
            return capturablePoints(in: state).map { .capture(at: $0) }
        }
        let player = state.currentPlayer
        switch state.phase(for: player) {
        case .placing:
            return state.emptyPoints.map { .place(at: $0) }
        case .moving:
            return state.points(of: player).flatMap { from in
                Board.adjacency[from]
                    .filter { state.points[$0] == nil }
                    .map { .slide(from: from, to: $0) }
            }
        case .flying:
            return state.points(of: player).flatMap { from in
                state.emptyPoints.map { .fly(from: from, to: $0) }
            }
        case .gameOver:
            return []
        }
    }

    // MARK: Applying moves

    /// Applies a move, returning the resulting state or the reason it is illegal.
    ///
    /// A move that completes one or more mills sets ``GameState/pendingCapture``
    /// and does not pass the turn; the same player must then apply a
    /// ``Move/capture(at:)``. Mill detection asks only whether the destination
    /// point completes a line now, which is exactly why a mill that is broken
    /// and re-formed pays out again.
    static func apply(_ move: Move, to state: GameState) -> Result<GameState, MoveRejection> {
        guard state.result == nil else { return .failure(.gameIsOver) }
        switch move {
        case .place(let point):
            return applyPlacement(at: point, to: state)
        case .slide(let from, let to):
            return applyMovement(from: from, to: to, flying: false, to: state)
        case .fly(let from, let to):
            return applyMovement(from: from, to: to, flying: true, to: state)
        case .capture(let point):
            return applyCapture(at: point, to: state)
        }
    }

    private static func applyPlacement(at point: Int, to state: GameState) -> Result<GameState, MoveRejection> {
        guard !state.pendingCapture else { return .failure(.mustCaptureFirst) }
        guard Board.allPoints.contains(point) else { return .failure(.invalidPoint) }
        let player = state.currentPlayer
        guard state.phase(for: player) == .placing else { return .failure(.wrongPhase) }
        guard state.points[point] == nil else { return .failure(.pointOccupied) }

        var next = state
        next.points[point] = player
        next.setPiecesInHand(state.piecesInHand(for: player) - 1, for: player)
        next.moveCount += 1
        return .success(resolveMills(at: point, in: next))
    }

    private static func applyMovement(from: Int, to: Int, flying: Bool, to state: GameState) -> Result<GameState, MoveRejection> {
        guard !state.pendingCapture else { return .failure(.mustCaptureFirst) }
        guard Board.allPoints.contains(from), Board.allPoints.contains(to) else { return .failure(.invalidPoint) }
        let player = state.currentPlayer
        let phase = state.phase(for: player)
        if flying {
            guard phase == .flying else { return .failure(.wrongPhase) }
        } else {
            guard phase == .moving || phase == .flying else { return .failure(.wrongPhase) }
        }
        guard let occupant = state.points[from] else { return .failure(.noPieceAtPoint) }
        guard occupant == player else { return .failure(.notYourPiece) }
        guard state.points[to] == nil else { return .failure(.pointOccupied) }
        if !flying {
            guard Board.isAdjacent(from, to) else { return .failure(.notAdjacent) }
        }

        var next = state
        next.points[from] = nil
        next.points[to] = player
        next.moveCount += 1
        return .success(resolveMills(at: to, in: next))
    }

    private static func applyCapture(at point: Int, to state: GameState) -> Result<GameState, MoveRejection> {
        guard state.pendingCapture else { return .failure(.wrongPhase) }
        guard Board.allPoints.contains(point) else { return .failure(.invalidPoint) }
        guard let occupant = state.points[point] else { return .failure(.noPieceAtPoint) }
        let player = state.currentPlayer
        guard occupant == player.opponent else { return .failure(.notYourPiece) }
        guard capturablePoints(in: state).contains(point) else { return .failure(.cannotCaptureFromMill) }

        var next = state
        next.points[point] = nil
        next.pendingCapture = false

        let opponent = player.opponent
        let opponentPieces = next.pieceCount(for: opponent) + next.piecesInHand(for: opponent)
        if opponentPieces <= 2 {
            next.result = GameResult(winner: player, reason: .opponentReducedToTwo)
            return .success(next)
        }
        return .success(passTurn(in: next))
    }

    /// Marks a pending capture if the piece that just landed completed a mill,
    /// otherwise passes the turn.
    ///
    /// In the rare position where a mill forms but the opponent has nothing on
    /// the board to take, the capture is skipped and the turn passes.
    private static func resolveMills(at destination: Int, in state: GameState) -> GameState {
        var next = state
        if !millsCompleted(at: destination, in: next).isEmpty {
            next.pendingCapture = true
            if capturablePoints(in: next).isEmpty {
                next.pendingCapture = false
                return passTurn(in: next)
            }
            return next
        }
        return passTurn(in: next)
    }

    /// Hands the turn to the opponent and applies the blockade rule.
    ///
    /// If the player receiving the turn has no legal move, they lose
    /// immediately. There is no draw by that route.
    private static func passTurn(in state: GameState) -> GameState {
        var next = state
        next.currentPlayer = state.currentPlayer.opponent
        if next.result == nil, legalMoves(in: next).isEmpty {
            next.result = GameResult(winner: state.currentPlayer, reason: .opponentBlocked)
        }
        return next
    }

    // MARK: Mills

    /// The mills through a point that are fully occupied by the piece standing on it.
    static func millsCompleted(at point: Int, in state: GameState) -> [[Int]] {
        guard Board.allPoints.contains(point), let owner = state.points[point] else { return [] }
        return Board.mills(containing: point).filter { line in
            line.allSatisfy { state.points[$0] == owner }
        }
    }

    /// Whether the piece at a point currently stands in a completed mill.
    static func isInMill(_ point: Int, in state: GameState) -> Bool {
        !millsCompleted(at: point, in: state).isEmpty
    }

    /// The enemy pieces the current player may capture right now.
    ///
    /// Pieces standing in a mill are protected, unless every enemy piece is in
    /// a mill, in which case all of them are fair game.
    static func capturablePoints(in state: GameState) -> [Int] {
        let enemyPoints = state.points(of: state.currentPlayer.opponent)
        let unprotected = enemyPoints.filter { !isInMill($0, in: state) }
        return unprotected.isEmpty ? enemyPoints : unprotected
    }

    // MARK: Computer opponent

    /// A greedy move suggestion used by the built in computer opponent.
    ///
    /// The heuristic, in priority order: resolve a pending capture (preferring
    /// pieces that sit one move from an enemy mill), complete an own mill,
    /// block an enemy mill that could complete next turn, and otherwise pick
    /// any legal move. The generator is injected so tests can seed it and
    /// assert deterministically.
    static func suggestedMove(
        for state: GameState,
        using generator: inout some RandomNumberGenerator
    ) -> Move? {
        let moves = legalMoves(in: state)
        guard !moves.isEmpty else { return nil }
        let player = state.currentPlayer

        if state.pendingCapture {
            let threatening = moves.filter { move in
                guard case .capture(let point) = move else { return false }
                return isNearMillMember(point, for: player.opponent, in: state)
            }
            return (threatening.isEmpty ? moves : threatening).randomElement(using: &generator)
        }

        let milling = moves.filter { completesMill($0, for: player, in: state) }
        if let move = milling.randomElement(using: &generator) { return move }

        let blocking = moves.filter { move in
            guard let destination = destination(of: move) else { return false }
            return isNearMillPoint(destination, for: player.opponent, in: state)
        }
        if let move = blocking.randomElement(using: &generator) { return move }

        return moves.randomElement(using: &generator)
    }

    /// The point a move ends on, if it puts a piece somewhere.
    private static func destination(of move: Move) -> Int? {
        switch move {
        case .place(let at): at
        case .slide(_, let to): to
        case .fly(_, let to): to
        case .capture: nil
        }
    }

    /// Whether performing a move would complete a mill for the player.
    private static func completesMill(_ move: Move, for player: PlayerColor, in state: GameState) -> Bool {
        var points = state.points
        switch move {
        case .place(let at):
            points[at] = player
            return millCompleted(at: at, by: player, in: points)
        case .slide(let from, let to), .fly(let from, let to):
            points[from] = nil
            points[to] = player
            return millCompleted(at: to, by: player, in: points)
        case .capture:
            return false
        }
    }

    private static func millCompleted(at point: Int, by player: PlayerColor, in points: [PlayerColor?]) -> Bool {
        Board.mills(containing: point).contains { line in
            line.allSatisfy { points[$0] == player }
        }
    }

    /// Whether an empty point is the missing third of a line where the player
    /// already has two pieces.
    private static func isNearMillPoint(_ point: Int, for player: PlayerColor, in state: GameState) -> Bool {
        Board.mills(containing: point).contains { line in
            line.count(where: { state.points[$0] == player }) == 2
                && line.count(where: { state.points[$0] == nil }) == 1
        }
    }

    /// Whether a piece is part of a line the owner could complete on a later turn.
    private static func isNearMillMember(_ point: Int, for player: PlayerColor, in state: GameState) -> Bool {
        Board.mills(containing: point).contains { line in
            line.count(where: { state.points[$0] == player }) == 2
                && line.count(where: { state.points[$0] == nil }) == 1
        }
    }
}
