//
//  BoardViewModelTests.swift
//  StoneMill-MVVMC
//
//  Created by Sarah Clark on 7/16/26.
//

import Foundation
import Testing
@testable import StoneMill_MVVMC

/// The board ViewModel's interaction loop, published display values, and the
/// exactly once finish report, driven through the same methods the tabletop
/// interaction handler calls.
@MainActor
struct BoardViewModelTests {

    private func makeViewModel(
        fixture scenario: UITestScenario? = nil,
        configuration: MatchConfiguration = GameState.fixtureConfiguration
    ) -> BoardViewModel {
        let state = scenario.flatMap(GameState.fixture(for:)) ?? .initial()
        return BoardViewModel(configuration: configuration, initialState: state)
    }

    // MARK: Placing

    @Test func placingOffersEveryEmptyPoint() {
        let viewModel = makeViewModel()

        #expect(viewModel.selectablePoints == Set(Board.allPoints))
        #expect(viewModel.statusText.contains("Rowan"))
        #expect(viewModel.statusText.contains("9 in hand"))
    }

    @Test func tappingAnEmptyPointPlacesAStone() {
        let viewModel = makeViewModel()

        viewModel.pointTapped(0)

        #expect(viewModel.gameState.points[0] == .light)
        #expect(viewModel.gameState.currentPlayer == .dark)
        #expect(viewModel.statusText.contains("Sage"))
    }

    // MARK: Selecting and moving

    @Test func liftingAndDroppingAPieceMovesIt() throws {
        let viewModel = makeViewModel(fixture: .oneMoveToWin)

        #expect(viewModel.canLift(pieceAt: 3))
        viewModel.pointTapped(3)
        #expect(viewModel.interaction == .pieceSelected(3))
        #expect(viewModel.selectablePoints == viewModel.destinations(forPieceAt: 3))

        viewModel.pointTapped(2)
        #expect(viewModel.gameState.points[2] == .light)
        #expect(viewModel.gameState.points[3] == nil)
    }

    @Test func tappingTheSelectedPieceDeselectsIt() {
        let viewModel = makeViewModel(fixture: .oneMoveToWin)

        viewModel.pointTapped(3)
        viewModel.pointTapped(3)

        #expect(viewModel.interaction == .awaitingSelection)
    }

    @Test func illegalTapsLeaveTheStateUntouched() {
        let viewModel = makeViewModel(fixture: .oneMoveToWin)
        let before = viewModel.gameState

        viewModel.pointTapped(8)

        #expect(viewModel.gameState == before)
        #expect(viewModel.interaction == .awaitingSelection)
    }

    // MARK: Mills and captures

    @Test func completingAMillAsksForACapture() throws {
        let viewModel = makeViewModel(fixture: .oneMoveToWin)

        viewModel.pointTapped(3)
        viewModel.pointTapped(2)

        #expect(viewModel.interaction == .awaitingCapture)
        #expect(viewModel.capturablePieces == Set(RulesEngine.capturablePoints(in: viewModel.gameState)))
        #expect(viewModel.highlightedMill == [0, 1, 2])
        #expect(viewModel.statusText.contains("removes"))
    }

    @Test func rejectedCommitsReportFalse() {
        let viewModel = makeViewModel(fixture: .oneMoveToWin)

        #expect(!viewModel.commitPlace(at: 5), "Hands are empty, placing is over")
        #expect(!viewModel.commitCapture(at: 8), "No mill is pending")
        #expect(!viewModel.commitMove(from: 8, to: 7), "Point 8 belongs to dark")
    }

    // MARK: Finishing

    @Test func finishingReportsTheOutcomeExactlyOnce() throws {
        let viewModel = makeViewModel(fixture: .oneMoveToWin)
        var outcomes: [MatchOutcome] = []
        viewModel.didFinishMatch = { outcomes.append($0) }

        viewModel.pointTapped(3)
        viewModel.pointTapped(2)
        viewModel.pointTapped(8)

        #expect(viewModel.interaction == .matchOver)
        let outcome = try #require(outcomes.first)
        #expect(outcomes.count == 1)
        #expect(outcome.winner == .light)
        #expect(outcome.winnerName == "Rowan")
        #expect(outcome.loserName == "Sage")
        #expect(outcome.reason == .opponentReducedToTwo)

        viewModel.pointTapped(16)
        #expect(outcomes.count == 1, "A finished board reports nothing further")
    }

    @Test func aSeededFinishedBoardDoesNotReportAgain() {
        let viewModel = makeViewModel(fixture: .matchOver)
        var finishCount = 0
        viewModel.didFinishMatch = { _ in finishCount += 1 }

        viewModel.pointTapped(0)

        #expect(viewModel.interaction == .matchOver)
        #expect(finishCount == 0)
        #expect(viewModel.statusText.contains("wins"))
    }

    @Test func resetStartsTheMatchOver() {
        let viewModel = makeViewModel(fixture: .matchOver)

        viewModel.resetMatch()

        #expect(viewModel.gameState.result == nil)
        #expect(viewModel.gameState.pieceCount(for: .light) == 0)
        #expect(viewModel.interaction == .awaitingSelection)
    }

    // MARK: Display values

    @Test func statusTextNamesTheFlyingPlayer() {
        let viewModel = makeViewModel(fixture: .flying)

        #expect(viewModel.statusText.contains("flying"))
    }

    @Test func stateChangesAreForwardedToTheRenderer() {
        let viewModel = makeViewModel()
        var forwarded: [GameState] = []
        viewModel.onStateChange = { forwarded.append($0) }

        viewModel.pointTapped(0)
        viewModel.pointTapped(1)

        #expect(forwarded.count == 2)
        #expect(forwarded.last?.points[1] == .dark)
    }

    // MARK: Computer opponent

    @Test func computerAnswersAfterAHumanMove() async {
        let configuration = MatchConfiguration(
            opponentKind: .computer,
            lightPlayerName: "Rowan",
            darkPlayerName: MatchConfiguration.computerName
        )
        let viewModel = makeViewModel(configuration: configuration)
        viewModel.computerMoveDelay = .zero

        viewModel.pointTapped(0)
        await viewModel.computerMoveTask?.value

        #expect(viewModel.gameState.currentPlayer == .light, "The engine finished its whole turn")
        #expect(viewModel.gameState.piecesInHand(for: .dark) == 8)
        #expect(viewModel.gameState.pieceCount(for: .dark) == 1)
    }

    @Test func humanTapsAreIgnoredDuringTheComputersTurn() {
        let configuration = MatchConfiguration(
            opponentKind: .computer,
            lightPlayerName: "Rowan",
            darkPlayerName: MatchConfiguration.computerName
        )
        let viewModel = makeViewModel(configuration: configuration)
        viewModel.computerMoveDelay = .seconds(60)

        viewModel.pointTapped(0)
        #expect(!viewModel.isHumanTurn)

        viewModel.pointTapped(1)
        #expect(viewModel.gameState.points[1] == nil, "Light cannot move for dark")
        #expect(viewModel.selectablePoints.isEmpty)

        viewModel.resetMatch()
    }
}
