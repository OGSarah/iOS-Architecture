//
//  AppRouter.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// Owns the single window and decides what is on screen across the split view's three columns.
///
/// `AppRouter` is created once by `SceneDelegate` and is the single source of truth for the
/// current `Route`. Module routers express navigation intent to it through a narrow protocol and
/// never touch `UINavigationController` or size classes themselves. The full column resolution,
/// deep link reconstruction, and Matter setup ticket handling arrive in a later milestone. For now
/// this is a minimal, compiling placeholder so the scene can attach a root view controller.
@MainActor
final class AppRouter {

    /// The window this router draws into. Held strongly because the router owns the scene's root.
    private let window: UIWindow

    /// Creates a router bound to the scene's window.
    /// - Parameter window: The window supplied by `SceneDelegate` when the scene connects.
    init(window: UIWindow) {
        self.window = window
    }

    /// Installs the initial user interface and makes the window visible.
    func start() {
        // Placeholder root until the split view and modules are wired up in later milestones.
        let placeholder = UIViewController()
        placeholder.view.backgroundColor = .systemBackground
        window.rootViewController = placeholder
    }

}
