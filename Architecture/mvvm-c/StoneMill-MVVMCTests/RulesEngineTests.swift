//
//  RulesEngineTests.swift
//  StoneMill-MVVMC
//
//  Created by Sarah Clark on 7/16/26.
//

import Foundation
import Testing
@testable import StoneMill_MVVMC

/// Tests for the pure rules engine, the reason this game was worth modeling.
///
/// Positions are written in the ``BoardDiagram`` notation so a test reads like
/// a diagram of the board it describes.
struct RulesEngineTests {

    // MARK: Mills

    /// Completing any of the 16 mills by placement earns a capture.
    @Test(arguments: Board.mills)
    func placingIntoAnyMillEarnsACapture(mill: [Int]) throws {
        var start = GameState.initial()
        start.points[mill[0]] = .light
        start.points[mill[1]] = .light
        start.lightInHand = 7
        start.darkInHand = 7
        let darkHomes = Board.allPoints.filter { !mill.contains($0) }.prefix(2)
        for point in darkHomes { start.points[point] = .dark }

        let next = applied(.place(at: mill[2]), to: start)

        #expect(next.pendingCapture)
        #expect(next.currentPlayer == .light, "A mill does not pass the turn until the capture resolves")
        #expect(RulesEngine.millsCompleted(at: mill[2], in: next).contains(mill))
    }

    /// A mill only captures on the turn it forms; a standing mill does nothing.
    @Test func standingMillDoesNotCapture() throws {
        let start = state("""
            X X X
            . O .
            . . .
            . .  .  . . .
            . . .
            . O .
            O . .
            """, toMove: .light)

        let next = applied(.slide(from: 2, to: 3), to: start)

        #expect(!next.pendingCapture, "Sliding out of a mill earns nothing on its own")
        #expect(next.currentPlayer == .dark)
    }

    /// A mill that is broken and re-formed on the next turn captures again.
    @Test func reFormedMillCapturesAgain() throws {
        let start = state("""
            X X X
            . . .
            . O .
            . .  .  . . X
            . O .
            . O O
            . . .
            """, toMove: .light)

        var game = applied(.slide(from: 1, to: 9), to: start)
        #expect(!game.pendingCapture)
        #expect(game.currentPlayer == .dark)

        game = applied(.slide(from: 13, to: 5), to: game)
        #expect(game.currentPlayer == .light)

        game = applied(.slide(from: 9, to: 1), to: game)
        #expect(game.pendingCapture, "Re-forming the same mill counts and captures again")

        game = applied(.capture(at: 17), to: game)
        #expect(game.points[17] == nil)
        #expect(game.currentPlayer == .dark)
    }

    /// A move that completes two mills at once still earns exactly one capture.
    @Test func doubleMillEarnsOneCapture() throws {
        var start = GameState.initial()
        start.points[0] = .light
        start.points[2] = .light
        start.points[9] = .light
        start.points[17] = .light
        start.points[12] = .dark
        start.points[13] = .dark
        start.lightInHand = 5
        start.darkInHand = 7

        let next = applied(.place(at: 1), to: start)

        #expect(RulesEngine.millsCompleted(at: 1, in: next).count == 2)
        #expect(next.pendingCapture)

        let resolved = applied(.capture(at: 12), to: next)
        #expect(!resolved.pendingCapture)
        #expect(resolved.currentPlayer == .dark, "One capture resolves the whole move")
    }

    // MARK: Capture protection

    /// A piece standing in a mill cannot be captured while looser pieces exist.
    @Test func millProtectsItsPieces() throws {
        var start = state("""
            X X .
            O O O
            . . .
            . .  .  O O X
            . . .
            . . .
            . . .
            """, toMove: .light)
        start.lightInHand = 6
        start.darkInHand = 4

        let milled = applied(.place(at: 2), to: start)
        #expect(milled.pendingCapture)
        #expect(Set(RulesEngine.capturablePoints(in: milled)) == [19, 11])

        #expect(RulesEngine.apply(.capture(at: 9), to: milled) == .failure(.cannotCaptureFromMill))
    }

    /// When every enemy piece stands in a mill, the protection lapses.
    @Test func allPiecesInMillsAreCapturable() throws {
        var start = state("""
            X X .
            O O O
            . . .
            . .  .  . . .
            . . .
            . . .
            . . .
            """, toMove: .light)
        start.lightInHand = 6
        start.darkInHand = 6

        let milled = applied(.place(at: 2), to: start)

        #expect(Set(RulesEngine.capturablePoints(in: milled)) == [8, 9, 10])
        let resolved = applied(.capture(at: 9), to: milled)
        #expect(resolved.points[9] == nil)
    }

    /// In the rare position where a mill forms but the opponent has nothing on
    /// the board, the capture is skipped and the turn passes.
    @Test func millWithNothingToCaptureSkipsTheCapture() throws {
        var start = GameState.initial()
        start.points[0] = .light
        start.points[1] = .light
        start.lightInHand = 7
        start.darkInHand = 9

        let next = applied(.place(at: 2), to: start)

        #expect(!next.pendingCapture)
        #expect(next.currentPlayer == .dark)
    }

    // MARK: Phases

    /// The placing phase lasts until a player's hand is empty.
    @Test func placingEndsWhenTheHandEmpties() throws {
        var start = GameState.initial()
        start.lightInHand = 1
        start.darkInHand = 1
        for point in [0, 5, 10, 15] { start.points[point] = .light }
        for point in [2, 7, 12, 17] { start.points[point] = .dark }
        start.points[4] = .light
        start.points[6] = .light
        start.points[8] = .light
        start.points[14] = .dark
        start.points[16] = .dark
        start.points[18] = .dark

        #expect(start.phase(for: .light) == .placing)

        var game = applied(.place(at: 1), to: start)
        #expect(game.phase(for: .light) == .moving)
        #expect(game.phase(for: .dark) == .placing)

        game = applied(.place(at: 3), to: game)
        #expect(game.phase == .moving)
    }

    /// Flying activates at exactly three pieces, for that player only.
    @Test func flyingIsPerPlayer() throws {
        let fixture = try #require(GameState.fixture(for: .flying))

        #expect(fixture.phase(for: .light) == .flying)
        #expect(fixture.phase(for: .dark) == .moving, "One side flying does not lift the other")

        let flights = RulesEngine.legalMoves(in: fixture).filter {
            if case .fly = $0 { return true } else { return false }
        }
        #expect(flights.count == 3 * fixture.emptyPoints.count, "A flying player may land on any empty point")
    }

    /// A flying player may still make a plain adjacent slide.
    @Test func flyingPlayerMayStillSlide() throws {
        let fixture = try #require(GameState.fixture(for: .flying))

        let next = applied(.slide(from: 9, to: 1), to: fixture)
        #expect(next.points[1] == .light)
    }

    /// A player who is not flying may not fly.
    @Test func groundedPlayerMayNotFly() throws {
        var fixture = try #require(GameState.fixture(for: .flying))
        fixture.currentPlayer = .dark

        #expect(RulesEngine.apply(.fly(from: 2, to: 1), to: fixture) == .failure(.wrongPhase))
    }

    // MARK: Rejections

    /// Each way the engine can refuse a move, as (state, move, rejection) rows.
    @Test(arguments: [
        (Move.place(at: 24), MoveRejection.invalidPoint),
        (Move.place(at: -1), MoveRejection.invalidPoint),
        (Move.place(at: 0), MoveRejection.pointOccupied),
        (Move.slide(from: 5, to: 6), MoveRejection.wrongPhase),
        (Move.capture(at: 9), MoveRejection.wrongPhase),
    ])
    func placingPhaseRejections(move: Move, rejection: MoveRejection) throws {
        var start = GameState.initial()
        start.points[0] = .light
        start.points[9] = .dark
        start.lightInHand = 8
        start.darkInHand = 8

        #expect(RulesEngine.apply(move, to: start) == .failure(rejection))
    }

    /// Movement phase rejections: wrong owner, empty source, blocked and
    /// disconnected destinations.
    @Test(arguments: [
        (Move.slide(from: 9, to: 17), MoveRejection.notYourPiece),
        (Move.slide(from: 21, to: 17), MoveRejection.noPieceAtPoint),
        (Move.slide(from: 0, to: 1), MoveRejection.pointOccupied),
        (Move.slide(from: 0, to: 2), MoveRejection.notAdjacent),
        (Move.place(at: 17), MoveRejection.wrongPhase),
        (Move.fly(from: 0, to: 17), MoveRejection.wrongPhase),
    ])
    func movingPhaseRejections(move: Move, rejection: MoveRejection) throws {
        let start = state("""
            X X .
            . O .
            . . .
            . .  .  . O X
            . . .
            . O O
            X . X
            """, toMove: .light)

        #expect(RulesEngine.apply(move, to: start) == .failure(rejection))
    }

    /// While a mill waits, everything except a capture is refused.
    @Test func pendingCaptureBlocksOtherMoves() throws {
        var start = state("""
            X X X
            . O .
            . . .
            . .  .  . O X
            . . .
            . . .
            . O .
            """, toMove: .light, pendingCapture: true)
        start.lightInHand = 0
        start.darkInHand = 0

        #expect(RulesEngine.apply(.slide(from: 3, to: 4), to: start) == .failure(.mustCaptureFirst))
        #expect(RulesEngine.apply(.capture(at: 0), to: start) == .failure(.notYourPiece))
        #expect(RulesEngine.apply(.capture(at: 4), to: start) == .failure(.noPieceAtPoint))

        let legal = RulesEngine.legalMoves(in: start)
        #expect(legal.allSatisfy { if case .capture = $0 { true } else { false } })
    }

    /// Once a result exists, every move is refused.
    @Test func finishedGameRefusesEveryMove() throws {
        let fixture = try #require(GameState.fixture(for: .matchOver))

        #expect(RulesEngine.apply(.slide(from: 0, to: 7), to: fixture) == .failure(.gameIsOver))
        #expect(RulesEngine.legalMoves(in: fixture).isEmpty)
    }

    // MARK: Win conditions

    /// Capturing an opponent down to two pieces ends the match.
    @Test func reductionToTwoWins() throws {
        let fixture = try #require(GameState.fixture(for: .oneMoveToWin))

        let milled = applied(.slide(from: 3, to: 2), to: fixture)
        #expect(milled.pendingCapture)

        let finished = applied(.capture(at: 8), to: milled)
        #expect(finished.result == GameResult(winner: .light, reason: .opponentReducedToTwo))
        #expect(finished.phase == .gameOver)
    }

    /// A player left without a legal move loses immediately; there is no draw
    /// by that route.
    @Test func blockadeIsALoss() throws {
        let start = state("""
            O X O
            . . .
            . . .
            . X  .  . . X
            . . .
            . . .
            O X O
            """, toMove: .light)

        let finished = applied(.slide(from: 15, to: 7), to: start)

        #expect(finished.result == GameResult(winner: .light, reason: .opponentBlocked))
    }

    /// Captures count toward reduction even while the victim still has pieces
    /// in hand, but do not end the match while hand plus board exceeds two.
    @Test func reductionCountsHandPieces() throws {
        var start = GameState.initial()
        start.points[0] = .light
        start.points[1] = .light
        start.points[9] = .dark
        start.lightInHand = 6
        start.darkInHand = 8

        let milled = applied(.place(at: 2), to: start)
        let next = applied(.capture(at: 9), to: milled)

        #expect(next.result == nil, "Dark still has eight pieces in hand")
        #expect(next.currentPlayer == .dark)
    }

    // MARK: Computer opponent

    /// The suggestion is always drawn from the legal move list.
    @Test(arguments: [UITestScenario.midPlacing, .flying, .oneMoveToWin])
    func suggestionIsAlwaysLegal(scenario: UITestScenario) throws {
        let fixture = try #require(GameState.fixture(for: scenario))
        var generator = SeededGenerator(seed: 7)

        for _ in 0..<25 {
            let move = try #require(RulesEngine.suggestedMove(for: fixture, using: &generator))
            #expect(RulesEngine.legalMoves(in: fixture).contains(move))
        }
    }

    /// The greedy engine prefers completing its own mill over anything else.
    @Test func suggestionPrefersCompletingAMill() throws {
        var start = GameState.initial()
        start.points[0] = .light
        start.points[1] = .light
        start.points[12] = .dark
        start.points[17] = .dark
        start.lightInHand = 7
        start.darkInHand = 7
        var generator = SeededGenerator(seed: 42)

        let move = RulesEngine.suggestedMove(for: start, using: &generator)

        #expect(move == .place(at: 2))
    }

    /// With no mill of its own available, the engine blocks an enemy line that
    /// is one piece from completing.
    @Test func suggestionBlocksAnEnemyMill() throws {
        var start = GameState.initial()
        start.currentPlayer = .dark
        start.points[0] = .light
        start.points[1] = .light
        start.points[12] = .dark
        start.lightInHand = 7
        start.darkInHand = 8
        var generator = SeededGenerator(seed: 3)

        let move = RulesEngine.suggestedMove(for: start, using: &generator)

        #expect(move == .place(at: 2), "Point 2 is the only square that stops the light mill")
    }

    /// A seeded generator makes the suggestion reproducible.
    @Test func suggestionIsDeterministicForASeed() throws {
        let fixture = try #require(GameState.fixture(for: .midPlacing))
        var first = SeededGenerator(seed: 99)
        var second = SeededGenerator(seed: 99)

        #expect(
            RulesEngine.suggestedMove(for: fixture, using: &first)
                == RulesEngine.suggestedMove(for: fixture, using: &second)
        )
    }

    // MARK: Fixture consistency

    /// The UI test fixtures stay internally consistent, so a fixture edit
    /// cannot silently break a UI test flow.
    @Test(arguments: UITestScenario.allCases)
    func fixturesAreInternallyConsistent(scenario: UITestScenario) throws {
        guard let fixture = GameState.fixture(for: scenario) else { return }

        for player in PlayerColor.allCases {
            let total = fixture.pieceCount(for: player) + fixture.piecesInHand(for: player)
            #expect(total <= Board.piecesPerPlayer)
            if fixture.result == nil {
                #expect(total >= 3, "A live fixture must not already be lost")
            }
        }
        if fixture.result == nil {
            #expect(!RulesEngine.legalMoves(in: fixture).isEmpty)
        }
    }
}
