//
//  AutomationListBuilder.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// Assembles the AutomationList module inside a navigation controller for modal presentation.
enum AutomationListBuilder {

    static func build(homeStore: HomeStore, appRouter: AppRouter?) -> UIViewController {
        let interactor = AutomationListInteractor(reader: homeStore)
        let router = AutomationListRouter(writer: homeStore)
        let presenter = AutomationListPresenter(interactor: interactor, router: router)
        interactor.output = presenter

        let viewController = AutomationListViewController(output: presenter)
        presenter.view = viewController
        router.viewController = viewController
        return UINavigationController(rootViewController: viewController)
    }
}
