//
//  AccessoryDetailBuilder.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// Assembles the AccessoryDetail module and wraps it in a navigation controller so services push.
enum AccessoryDetailBuilder {

    /// Builds an AccessoryDetail screen for one accessory.
    /// - Parameters:
    ///   - accessoryID: The accessory to show.
    ///   - homeStore: The store used for reads, writes, and notifications.
    ///   - appRouter: The app router for cross column navigation intent.
    /// - Returns: A navigation controller rooting the detail screen.
    static func build(accessoryID: String, homeStore: HomeStore, appRouter: AppRouter?) -> UIViewController {
        let interactor = AccessoryDetailInteractor(accessoryID: accessoryID, homeStore: homeStore)
        let router = AccessoryDetailRouter(writer: homeStore, notifications: homeStore)
        router.appRouter = appRouter
        let presenter = AccessoryDetailPresenter(interactor: interactor, router: router)
        interactor.output = presenter

        let viewController = AccessoryDetailViewController(output: presenter)
        presenter.view = viewController
        router.viewController = viewController
        return UINavigationController(rootViewController: viewController)
    }
}
