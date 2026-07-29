//
//  AccessorySetupBuilder.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// Assembles the AccessorySetup module inside a navigation controller for modal presentation.
enum AccessorySetupBuilder {

    static func build(commissioner: AccessoryCommissioning, appRouter: AppRouter?) -> UIViewController {
        let interactor = AccessorySetupInteractor(commissioner: commissioner)
        let router = AccessorySetupRouter()
        let presenter = AccessorySetupPresenter(interactor: interactor, router: router)
        interactor.output = presenter

        let viewController = AccessorySetupViewController(output: presenter)
        presenter.view = viewController
        router.viewController = viewController
        return UINavigationController(rootViewController: viewController)
    }
}
