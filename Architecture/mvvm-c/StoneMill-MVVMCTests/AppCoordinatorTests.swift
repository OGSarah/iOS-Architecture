//
//  AppCoordinatorTests.swift
//  StoneMill-MVVMC
//
//  Created by Sarah Clark on 7/16/26.
//

import Foundation
import SwiftData
import Testing
@testable import StoneMill_MVVMC

/// Navigation itself, under unit test.
///
/// The coordinator is built with a ``SpySceneOpener`` and an in memory
/// SwiftData container, then driven through the same event closures the real
/// ViewModels call. These are the tests MVVM alone cannot offer.
@MainActor
struct AppCoordinatorTests {

    private let spy = SpySceneOpener()
    private let coordinator: AppCoordinator

    init() throws {
        let container = try ModelContainer(
            for: MatchRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        coordinator = AppCoordinator(modelContainer: container, sceneOpener: spy)
    }

    private func startFixtureMatch(_ scenario: UITestScenario = .oneMoveToWin) {
        coordinator.startMatch(GameState.fixtureConfiguration, fixture: GameState.fixture(for: scenario))
    }

    // MARK: Starting a match

    @Test func startingAMatchOpensTheVolume() {
        startFixtureMatch()

        #expect(spy.events == [.openWindow("board")])
        if case .board = coordinator.route {} else {
            Issue.record("Expected a board route, got \(coordinator.route)")
        }
        #expect(coordinator.activeBoardViewModel != nil)
    }

    /// The setup ViewModel's start event flows through the coordinator into a
    /// running match without the view knowing any of it.
    @Test func setupEventsAreWired() {
        let setup = coordinator.makeSetupViewModel()
        setup.lightPlayerName = "Rowan"
        setup.darkPlayerName = "Sage"

        setup.startTapped()

        #expect(spy.events == [.openWindow("board")])
        #expect(coordinator.activeBoardViewModel?.configuration.lightPlayerName == "Rowan")

        setup.historyTapped()
        #expect(coordinator.setupPath == [.history])

        setup.historyTapped()
        #expect(coordinator.setupPath == [.history], "History is not pushed twice")
    }

    // MARK: Finishing a match

    @Test func finishingPersistsExactlyOneRecord() throws {
        startFixtureMatch()
        let board = try #require(coordinator.activeBoardViewModel)

        board.pointTapped(3)
        board.pointTapped(2)
        board.pointTapped(8)

        let records = try coordinator.modelContainer.mainContext.fetch(FetchDescriptor<MatchRecord>())
        #expect(records.count == 1)
        #expect(records.first?.winnerName == "Rowan")
        #expect(records.first?.winReason == WinReason.opponentReducedToTwo.rawValue)
        #expect(spy.events == [.openWindow("board")], "Finishing does not itself change scenes")
    }

    // MARK: The excavation space

    @Test func excavationDismissesTheVolumeBeforeOpeningTheSpace() async {
        startFixtureMatch(.matchOver)
        spy.reset()

        await coordinator.showExcavation(siteID: "kurna")

        #expect(spy.events == [
            .dismissWindow("board"),
            .openImmersiveSpace("excavation"),
            .dismissWindow("setup"),
        ])
        #expect(coordinator.route == .excavation("kurna"))
        #expect(coordinator.activeExcavationViewModel?.currentSite.id == "kurna")
    }

    /// A denied immersive space leaves the route unchanged and gives the
    /// volume back, rather than stranding the user.
    @Test(arguments: [ImmersiveOpenResult.userCancelled, .error])
    func deniedExcavationLeavesTheRouteUnchanged(result: ImmersiveOpenResult) async {
        startFixtureMatch(.matchOver)
        let routeBefore = coordinator.route
        spy.immersiveResult = result
        spy.reset()

        await coordinator.showExcavation(siteID: "kurna")

        #expect(coordinator.route == routeBefore)
        #expect(coordinator.activeExcavationViewModel == nil)
        #expect(spy.events == [
            .dismissWindow("board"),
            .openImmersiveSpace("excavation"),
            .openWindow("board"),
        ])
    }

    @Test func dismissingTheExcavationReturnsToSetup() async {
        startFixtureMatch(.matchOver)
        await coordinator.showExcavation(siteID: "cloister")
        spy.reset()

        await coordinator.dismissExcavation()

        #expect(spy.events == [.dismissImmersiveSpace, .openWindow("setup")])
        #expect(coordinator.route == .setup)
        #expect(coordinator.activeExcavationViewModel == nil)
    }

    /// The excavation ViewModel's dismiss closure lands back on the
    /// coordinator without the space knowing what comes next.
    @Test func excavationDismissEventIsWired() async throws {
        startFixtureMatch(.matchOver)
        await coordinator.showExcavation(siteID: "kurna")
        let excavation = try #require(coordinator.activeExcavationViewModel)
        spy.reset()

        excavation.returnTapped()
        try await Task.sleep(for: .milliseconds(50))

        #expect(coordinator.route == .setup)
        #expect(spy.events.contains(.dismissImmersiveSpace))
    }

    // MARK: External closes

    /// The user closing the volume with the window control resets the route.
    @Test func userClosingTheVolumeIsReconciled() {
        startFixtureMatch()

        coordinator.handleSceneDisappeared(.board)

        #expect(coordinator.route == .setup)
        #expect(coordinator.activeBoardViewModel == nil)
    }

    /// The board dismissal the coordinator performs itself is not mistaken
    /// for the user closing the volume.
    @Test func coordinatorInitiatedDismissalsAreNotReconciled() async {
        startFixtureMatch(.matchOver)
        await coordinator.showExcavation(siteID: "kurna")

        coordinator.handleSceneDisappeared(.board)

        #expect(coordinator.route == .excavation("kurna"), "The expected dismissal consumed the event")

        coordinator.handleSceneDisappeared(.excavation)
        #expect(coordinator.route == .setup, "A crown dismissal of the space is a real close")
    }

    @Test func unrelatedDisappearancesAreIgnored() {
        startFixtureMatch()

        coordinator.handleSceneDisappeared(.excavation)
        coordinator.handleSceneDisappeared(.setup)

        if case .board = coordinator.route {} else {
            Issue.record("The board route should have survived, got \(coordinator.route)")
        }
    }
}
