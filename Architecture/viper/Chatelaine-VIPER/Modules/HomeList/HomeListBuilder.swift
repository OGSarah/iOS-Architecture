//
//  HomeListBuilder.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// Assembles the HomeList module and returns the sidebar view controller.
enum HomeListBuilder {

    static func build(homeStore: HomeStore, appRouter: AppRouter?) -> UIViewController {
        let interactor = HomeListInteractor(homeStore: homeStore)
        let router = HomeListRouter()
        router.appRouter = appRouter
        let presenter = HomeListPresenter(interactor: interactor, router: router)
        interactor.output = presenter

        let viewController = HomeListViewController(output: presenter)
        presenter.view = viewController
        router.viewController = viewController
        return viewController
    }
}
