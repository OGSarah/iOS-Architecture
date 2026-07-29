//
//  AccessoryDetailBuilder.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// Assembles the AccessoryDetail module and returns the bare view controller.
///
/// The controller is returned without a navigation controller so it can be pushed directly onto the
/// compact stack at compact width. `AppRouter` wraps it in a navigation controller when it fills the
/// secondary column at regular width, which is what lets a service push onto it there.
enum AccessoryDetailBuilder {

    static func build(accessoryID: String, homeStore: HomeServicing, appRouter: AppRouter?) -> UIViewController {
        let interactor = AccessoryDetailInteractor(accessoryID: accessoryID, homeStore: homeStore)
        let router = AccessoryDetailRouter(writer: homeStore, notifications: homeStore)
        router.appRouter = appRouter
        let presenter = AccessoryDetailPresenter(interactor: interactor, router: router)
        interactor.output = presenter

        let viewController = AccessoryDetailViewController(output: presenter)
        presenter.view = viewController
        router.viewController = viewController
        return viewController
    }
}
