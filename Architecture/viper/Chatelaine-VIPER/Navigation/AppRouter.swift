//
//  AppRouter.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import Foundation
import UIKit

/// Owns what is on screen in which column, and is the single place that resolves a `Route`.
///
/// The same route means different things at different widths. On regular width `.accessory(id)`
/// fills the secondary column and leaves the sidebar and supplementary column intact. On compact
/// width the split view has collapsed into a stack and the same route is a push. One method resolves
/// that once, rather than every module resolving it separately and inconsistently.
///
/// `AppRouter` also reconstructs the columns behind a deep link. An App Intent can launch the app
/// cold into `.accessory(id)`, and the two columns behind it, the correct home and the correct room,
/// have to be built in order before the detail column is valid. It additionally owns the pending
/// Matter setup ticket, resolving it on return and discarding a result that arrives after the user
/// has navigated somewhere else.
@MainActor
final class AppRouter {

    private let splitView: SplitViewPresenting
    private let moduleFactory: ModuleFactory

    /// The latest home snapshot, used to resolve an accessory back to its room and home.
    private var home: HomeSnapshot?

    /// The setup flow currently awaiting a result, or `nil` when none is in flight.
    private var pendingSetupTicket: UUID?

    /// Creates the router with its split view seam and module factory.
    /// - Parameters:
    ///   - splitView: The split view presenting seam.
    ///   - moduleFactory: The factory that builds module view controllers.
    init(splitView: SplitViewPresenting, moduleFactory: ModuleFactory) {
        self.splitView = splitView
        self.moduleFactory = moduleFactory
    }

    /// Installs the initial user interface, showing onboarding first on a fresh install.
    func start() {
        present(.homes)
        if !Preferences.hasCompletedOnboarding {
            presentOnboarding()
        }
    }

    /// Presents the settings modal.
    func presentSettings() {
        splitView.presentModally(moduleFactory.makeSettings())
    }

    /// Presents the onboarding flow again, used after the user asks to replay it in settings.
    func replayOnboarding() {
        presentOnboarding()
    }

    private func presentOnboarding() {
        let onboarding = moduleFactory.makeOnboarding { [weak self] in
            self?.splitView.dismissModal()
        }
        splitView.presentModally(onboarding)
    }

    /// Updates the home snapshot the router uses to resolve routes.
    /// - Parameter home: The latest snapshot, or `nil` when none is available.
    func updateHome(_ home: HomeSnapshot?) {
        self.home = home
    }

    /// Resolves a route onto the split view, choosing columns or a push by the current width.
    /// - Parameter route: The destination to show.
    func present(_ route: Route) {
        switch route {
        case .homes:
            noteUserNavigated()
            splitView.install(moduleFactory.makeHomeList(), in: .primary)

        case let .home(homeID):
            noteUserNavigated()
            presentHome(homeID)

        case let .room(roomID):
            noteUserNavigated()
            presentRoom(roomID)

        case let .accessory(accessoryID):
            noteUserNavigated()
            presentAccessory(accessoryID)

        case let .automationBuilder(draftID):
            splitView.presentModally(moduleFactory.makeAutomationBuilder(draftID: draftID))

        case .setup:
            splitView.presentModally(moduleFactory.makeSetup())
        }
    }

    // MARK: - Matter setup ticket

    /// Records that a setup flow has begun and is awaiting a result.
    /// - Parameter ticket: A unique identifier for this setup attempt.
    func beginSetup(ticket: UUID) {
        pendingSetupTicket = ticket
    }

    /// Resolves a returning setup result, applying it only when it matches the pending attempt.
    ///
    /// Matter commissioning suspends the app, hands off to system UI, and returns later. If the user
    /// has navigated elsewhere in the meantime the ticket no longer matches and the result is
    /// discarded rather than applied to the wrong screen.
    /// - Parameters:
    ///   - ticket: The ticket that started the flow.
    ///   - result: The outcome the system UI returned.
    func resolveSetup(ticket: UUID, result: CommissionResult) {
        guard ticket == pendingSetupTicket else { return }
        pendingSetupTicket = nil
        if case let .added(accessoryID) = result {
            present(.accessory(accessoryID))
        }
    }

    // MARK: - Resolution

    private func presentHome(_ homeID: HomeSnapshot.ID) {
        splitView.install(moduleFactory.makeHomeList(), in: .primary)
        splitView.install(moduleFactory.makeRoomList(homeID: homeID), in: .supplementary)
    }

    private func presentRoom(_ roomID: RoomSnapshot.ID) {
        guard let homeID = home?.id else {
            splitView.install(moduleFactory.makeHomeList(), in: .primary)
            return
        }
        splitView.install(moduleFactory.makeHomeList(), in: .primary)
        splitView.install(moduleFactory.makeRoomList(homeID: homeID), in: .supplementary)
    }

    /// Places an accessory, reconstructing the two columns behind it at regular width.
    private func presentAccessory(_ accessoryID: AccessorySnapshot.ID) {
        let detail = moduleFactory.makeAccessoryDetail(accessoryID: accessoryID)

        if splitView.isCollapsed {
            // The columns are one stack now, so the same route is simply a push.
            splitView.pushDetail(detail)
            return
        }

        // Regular width. Build the sidebar and supplementary column in order, then the detail.
        splitView.install(moduleFactory.makeHomeList(), in: .primary)
        if let homeID = home?.id {
            splitView.install(moduleFactory.makeRoomList(homeID: homeID), in: .supplementary)
        }
        splitView.install(detail, in: .secondary)
    }

    /// Clears any pending setup ticket, marking that the user has moved on.
    private func noteUserNavigated() {
        pendingSetupTicket = nil
    }
}
