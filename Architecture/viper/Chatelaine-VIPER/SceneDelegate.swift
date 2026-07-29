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

    /// The store the app runs against. In DEBUG, a UI test scenario substitutes a scripted household
    /// so end to end flows need no HomeKit permission, no accessory simulator, and no real writes.
    private let homeStore: HomeServicing = {
        #if DEBUG
        if ProcessInfo.processInfo.environment["UITEST_SCENARIO"] != nil {
            return ScriptedHomeStore()
        }
        #endif
        return HomeStore()
    }()

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

        #if DEBUG
        configureForUITestsIfNeeded()
        #endif

        // Seed the compact column so the sidebar is present when the split view collapses on iPhone.
        splitView.setCompactRoot(factory.makeHomeList())

        window.rootViewController = splitView
        router.start()
        window.makeKeyAndVisible()
        router.showOnboardingIfNeeded()

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

#if DEBUG
extension SceneDelegate {

    /// Configures preferences for a UI test scenario so each flow starts from a known state.
    ///
    /// The `onboarding` scenario forces the intro to show. Every other scenario skips it and starts
    /// on the main split view so a flow test does not have to dismiss onboarding first.
    func configureForUITestsIfNeeded() {
        let environment = ProcessInfo.processInfo.environment
        guard let scenario = environment["UITEST_SCENARIO"] else { return }
        Preferences.hasCompletedOnboarding = scenario != "onboarding"
        Preferences.animationsEnabled = environment["UITEST_ANIMATIONS"] != "off"
    }
}
#endif
