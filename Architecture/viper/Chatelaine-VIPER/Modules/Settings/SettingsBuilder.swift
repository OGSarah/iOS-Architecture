//
//  SettingsBuilder.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// Assembles the Settings module inside a navigation controller for modal presentation.
enum SettingsBuilder {

    static func build(appRouter: AppRouter?) -> UIViewController {
        let interactor = SettingsInteractor()
        let router = SettingsRouter()
        router.appRouter = appRouter
        let presenter = SettingsPresenter(interactor: interactor, router: router)
        interactor.output = presenter

        let viewController = SettingsViewController(output: presenter)
        presenter.view = viewController
        router.viewController = viewController
        return UINavigationController(rootViewController: viewController)
    }
}
