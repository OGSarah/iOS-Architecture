//
//  HomeListRouter.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// Expresses the intent to open a home's rooms, leaving the how to `AppRouter`.
final class HomeListRouter: HomeListRouterInput {

    weak var appRouter: AppRouter?
    weak var viewController: UIViewController?

    func routeToHome(homeID: String) {
        appRouter?.present(.home(homeID))
    }
}
