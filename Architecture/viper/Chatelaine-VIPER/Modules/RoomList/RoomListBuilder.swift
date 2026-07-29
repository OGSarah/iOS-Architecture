//
//  RoomListBuilder.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// Assembles the RoomList module for the supplementary column.
enum RoomListBuilder {

    static func build(homeID: String, homeStore: HomeServicing, appRouter: AppRouter?) -> UIViewController {
        let interactor = RoomListInteractor(homeID: homeID, homeStore: homeStore)
        let router = RoomListRouter()
        router.appRouter = appRouter
        let presenter = RoomListPresenter(interactor: interactor, router: router)
        interactor.output = presenter

        let viewController = RoomListViewController(output: presenter)
        presenter.view = viewController
        router.viewController = viewController
        return viewController
    }
}
