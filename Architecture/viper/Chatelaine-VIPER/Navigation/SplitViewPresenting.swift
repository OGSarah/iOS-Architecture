//
//  SplitViewPresenting.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// The three columns of the split view, named so `AppRouter` can target one without knowing UIKit.
///
/// Marked `nonisolated` because it is a plain value type carried across the split view seam and
/// compared in tests, so its `Equatable` conformance must be usable from any isolation.
nonisolated enum SplitColumn: Sendable, Equatable {
    case primary
    case supplementary
    case secondary
}

/// A narrow protocol over `UISplitViewController` so `AppRouter` can be driven by a spy in tests.
///
/// `AppRouter` never touches a concrete `UISplitViewController`. It installs view controllers into
/// named columns, pushes a detail when the layout has collapsed to a stack, and presents modal
/// flows, all through this seam.
@MainActor
protocol SplitViewPresenting: AnyObject {
    /// Whether the split view has collapsed into a single navigation stack at compact width.
    var isCollapsed: Bool { get }

    /// Installs a view controller as the root of a column.
    /// - Parameters:
    ///   - viewController: The controller to install.
    ///   - column: The column it belongs in.
    func install(_ viewController: UIViewController, in column: SplitColumn)

    /// Pushes a detail onto the stack, used when the layout has collapsed to compact width.
    /// - Parameter viewController: The controller to push.
    func pushDetail(_ viewController: UIViewController)

    /// Presents a modal flow, such as the automation builder or the setup flow.
    /// - Parameter viewController: The controller to present.
    func presentModally(_ viewController: UIViewController)

    /// Dismisses the current modal flow, if any.
    func dismissModal()

    /// Pops the compact navigation stack back to its root.
    func resetToRoot()
}

/// The concrete `UISplitViewController` that backs the app's three column layout.
///
/// This is the only conformer to `SplitViewPresenting` that touches UIKit's split view. It maps the
/// project's `SplitColumn` onto `UISplitViewController.Column` and keeps a navigation controller for
/// the compact, collapsed presentation.
final class AppSplitViewController: UISplitViewController, SplitViewPresenting {

    /// The stack used when the layout collapses to a single column at compact width.
    private let compactNavigation = UINavigationController()

    init() {
        super.init(style: .tripleColumn)
        preferredDisplayMode = .twoBesideSecondary
        preferredSplitBehavior = .tile
        setViewController(compactNavigation, for: .compact)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used, this controller is built in code")
    }

    func install(_ viewController: UIViewController, in column: SplitColumn) {
        setViewController(viewController, for: uiColumn(for: column))
        if isCollapsed, column == .primary {
            // When collapsed, the primary column is the root of the visible stack.
            compactNavigation.setViewControllers([viewController], animated: false)
        }
    }

    func pushDetail(_ viewController: UIViewController) {
        compactNavigation.pushViewController(viewController, animated: true)
    }

    func presentModally(_ viewController: UIViewController) {
        present(viewController, animated: true)
    }

    func dismissModal() {
        presentedViewController?.dismiss(animated: true)
    }

    func resetToRoot() {
        compactNavigation.popToRootViewController(animated: false)
    }

    /// Maps the project's column to UIKit's split view column.
    private func uiColumn(for column: SplitColumn) -> UISplitViewController.Column {
        switch column {
        case .primary: .primary
        case .supplementary: .supplementary
        case .secondary: .secondary
        }
    }
}
