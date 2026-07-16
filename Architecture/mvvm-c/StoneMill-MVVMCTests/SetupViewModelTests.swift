import Foundation
import Testing
@testable import StoneMill_MVVMC

/// Validation and event reporting of the setup screen.
@MainActor
struct SetupViewModelTests {

    @Test func emptyNamesCannotStart() {
        let viewModel = SetupViewModel()

        #expect(!viewModel.canStart)
        #expect(viewModel.validationMessage != nil)
    }

    @Test func hotSeatNeedsBothNames() {
        let viewModel = SetupViewModel()
        viewModel.lightPlayerName = "Rowan"

        #expect(!viewModel.canStart)

        viewModel.darkPlayerName = "Sage"
        #expect(viewModel.canStart)
        #expect(viewModel.validationMessage == nil)
    }

    @Test func duplicateNamesAreRejected() {
        let viewModel = SetupViewModel()
        viewModel.lightPlayerName = "Rowan"
        viewModel.darkPlayerName = "rowan"

        #expect(!viewModel.canStart)
        #expect(viewModel.validationMessage == "The players need different names.")
    }

    @Test func whitespaceOnlyNamesAreRejected() {
        let viewModel = SetupViewModel()
        viewModel.lightPlayerName = "   "
        viewModel.darkPlayerName = "Sage"

        #expect(!viewModel.canStart)
    }

    @Test func computerModeNeedsOnlyTheLightName() {
        let viewModel = SetupViewModel()
        viewModel.opponentKind = .computer
        viewModel.lightPlayerName = "Rowan"

        #expect(viewModel.canStart)
        #expect(viewModel.darkPlayerName == MatchConfiguration.computerName)
    }

    @Test func leavingComputerModeClearsTheEngineName() {
        let viewModel = SetupViewModel()
        viewModel.opponentKind = .computer
        viewModel.opponentKind = .hotSeat

        #expect(viewModel.darkPlayerName.isEmpty)
    }

    @Test func startDeliversTheExactConfiguration() {
        let viewModel = SetupViewModel()
        viewModel.lightPlayerName = "  Rowan "
        viewModel.darkPlayerName = "Sage"
        var received: MatchConfiguration?
        viewModel.didStartMatch = { received = $0 }

        viewModel.startTapped()

        #expect(received == MatchConfiguration(opponentKind: .hotSeat, lightPlayerName: "Rowan", darkPlayerName: "Sage"))
    }

    @Test func invalidStartDoesNotReport() {
        let viewModel = SetupViewModel()
        var startCount = 0
        viewModel.didStartMatch = { _ in startCount += 1 }

        viewModel.startTapped()

        #expect(startCount == 0)
        #expect(viewModel.validationMessage != nil)
    }

    @Test func historyIntentIsForwarded() {
        let viewModel = SetupViewModel()
        var historyCount = 0
        viewModel.didSelectHistory = { historyCount += 1 }

        viewModel.historyTapped()

        #expect(historyCount == 1)
    }
}
