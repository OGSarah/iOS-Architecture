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
    func install(_ viewController: UIViewController, in column: SplitColumn)

    /// Pushes a detail onto the currently visible stack, used at compact width.
    func pushDetail(_ viewController: UIViewController)

    /// Presents a modal flow, such as the automation builder or the setup flow.
    func presentModally(_ viewController: UIViewController)

    /// Dismisses the current modal flow, if any.
    func dismissModal()

    /// Pops the compact navigation stack back to its root.
    func resetToRoot()
}

/// The concrete `UISplitViewController` that backs the app's three column layout.
///
/// On regular width the three columns are shown and `install(_:in:)` targets them directly. On
/// compact width the split view collapses to a single navigation stack, which is the dedicated
/// compact column seeded at launch, and navigation becomes a push onto that stack.
final class AppSplitViewController: UISplitViewController, SplitViewPresenting {

    /// The navigation stack shown when the layout collapses at compact width.
    private var compactNavigation: UINavigationController?

    init() {
        super.init(style: .tripleColumn)
        preferredDisplayMode = .twoBesideSecondary
        preferredSplitBehavior = .tile
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used, this controller is built in code")
    }

    /// Seeds the compact column with the root shown when the split view collapses.
    /// - Parameter viewController: The root of the compact navigation stack.
    func setCompactRoot(_ viewController: UIViewController) {
        let navigation = UINavigationController(rootViewController: viewController)
        compactNavigation = navigation
        setViewController(navigation, for: .compact)
    }

    func install(_ viewController: UIViewController, in column: SplitColumn) {
        setViewController(viewController, for: uiColumn(for: column))
    }

    func pushDetail(_ viewController: UIViewController) {
        activeNavigationController()?.pushViewController(viewController, animated: true)
    }

    func presentModally(_ viewController: UIViewController) {
        present(viewController, animated: true)
    }

    func dismissModal() {
        presentedViewController?.dismiss(animated: true)
    }

    func resetToRoot() {
        compactNavigation?.popToRootViewController(animated: false)
    }

    /// The navigation stack a push should target for the current width.
    private func activeNavigationController() -> UINavigationController? {
        if isCollapsed { return compactNavigation }
        return viewController(for: .secondary) as? UINavigationController
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
