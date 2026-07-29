//
//  SceneDelegate.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// Builds the split view and the `AppRouter`, and feeds home snapshots into the router. Nothing else.
///
/// The scene owns the object graph for one window: the `HomeStore`, the split view, the module
/// factory, and the router. It observes the store so that a change in the home graph reaches the
/// router, which keeps route resolution correct as accessories come and go.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var appRouter: AppRouter?
    private let homeStore = HomeStore()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)

        let splitView = AppSplitViewController()
        let factory = ChatelaineModuleFactory(homeStore: homeStore)
        let router = AppRouter(splitView: splitView, moduleFactory: factory)
        factory.router = router
        homeStore.addObserver(self)

        self.window = window
        self.appRouter = router

        window.rootViewController = splitView
        router.start()
        window.makeKeyAndVisible()

        // Load the current home so the router can resolve deep links against it right away.
        Task { [weak router] in
            let home = await homeStore.loadPrimaryHome()
            router?.updateHome(home)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        homeStore.removeObserver(self)
    }
}

// MARK: - HomeStoreObserver

extension SceneDelegate: HomeStoreObserver {

    func homeStoreDidUpdate(_ home: HomeSnapshot) {
        appRouter?.updateHome(home)
    }

    func homeStoreDidChangeAuthorization(_ status: HomeAuthorizationStatus) {
        // Authorization changes are surfaced by the modules in a later milestone.
    }
}
