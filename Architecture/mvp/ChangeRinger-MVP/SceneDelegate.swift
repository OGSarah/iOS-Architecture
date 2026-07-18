//
//  SceneDelegate.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

import UIKit

/// Builds the app's window and installs the document editor as the root.
///
/// `TouchEditorViewController` is a `UIDocumentViewController`, so making it the root lets the
/// system present the document launch scene, with its browser, until a composition is opened.
/// The window's tint is set to the theme's gold so system controls carry the app's identity.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let editor = TouchEditorViewController()
        let navigationController = UINavigationController(rootViewController: editor)

        let window = UIWindow(windowScene: windowScene)
        window.tintColor = Theme.gold
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
    }

    func sceneDidDisconnect(_ scene: UIScene) {}

    func sceneDidBecomeActive(_ scene: UIScene) {}

    func sceneWillResignActive(_ scene: UIScene) {}

    func sceneWillEnterForeground(_ scene: UIScene) {}

    func sceneDidEnterBackground(_ scene: UIScene) {}
}
