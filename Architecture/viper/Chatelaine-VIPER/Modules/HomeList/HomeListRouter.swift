//
//  HomeListRouter.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import Foundation
import UIKit

/// Expresses the intent to open a home's rooms, the automations modal, or settings.
final class HomeListRouter: HomeListRouterInput {

    weak var appRouter: AppRouter?
    weak var viewController: UIViewController?

    func routeToHome(homeID: String) {
        appRouter?.present(.home(homeID))
    }

    func routeToAutomations() {
        appRouter?.present(.automationBuilder(UUID().uuidString))
    }

    func routeToSettings() {
        appRouter?.presentSettings()
    }
}
