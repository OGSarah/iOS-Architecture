//
//  SpySplitViewPresenter.swift
//  Chatelaine-VIPERTests
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit
@testable import Chatelaine_VIPER

/// Records navigation instead of performing it, so `AppRouter` can be asserted without a UI.
@MainActor
final class SpySplitViewPresenter: SplitViewPresenting {

    /// The kinds of calls the router can make, captured in order.
    enum Event: Equatable {
        case install(SplitColumn)
        case pushDetail
        case presentModally
        case dismissModal
        case resetToRoot
    }

    /// Every call the router made, in the order it made them.
    private(set) var events: [Event] = []

    /// The width the router should believe it is at.
    var isCollapsed: Bool = false

    func install(_ viewController: UIViewController, in column: SplitColumn) {
        events.append(.install(column))
    }

    func pushDetail(_ viewController: UIViewController) {
        events.append(.pushDetail)
    }

    func presentModally(_ viewController: UIViewController) {
        events.append(.presentModally)
    }

    func dismissModal() {
        events.append(.dismissModal)
    }

    func resetToRoot() {
        events.append(.resetToRoot)
    }

    /// Clears the recorded events, used to ignore setup calls before the assertion of interest.
    func clear() {
        events.removeAll()
    }
}

/// A module factory that returns bare controllers, so tests can focus on column resolution.
@MainActor
final class StubModuleFactory: ModuleFactory {
    func makeHomeList() -> UIViewController { UIViewController() }
    func makeRoomList(homeID: HomeSnapshot.ID) -> UIViewController { UIViewController() }
    func makeAccessoryDetail(accessoryID: AccessorySnapshot.ID) -> UIViewController { UIViewController() }
    func makeAutomationBuilder(draftID: AutomationDraft.ID) -> UIViewController { UIViewController() }
    func makeSetup() -> UIViewController { UIViewController() }
    func makeSettings() -> UIViewController { UIViewController() }
    func makeOnboarding(onFinish: @escaping () -> Void) -> UIViewController { UIViewController() }
}
