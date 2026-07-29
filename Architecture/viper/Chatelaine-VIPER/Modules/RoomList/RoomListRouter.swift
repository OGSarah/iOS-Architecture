//
//  RoomListRouter.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// Expresses the intent to open an accessory or the setup flow, leaving the how to `AppRouter`.
final class RoomListRouter: RoomListRouterInput {

    weak var appRouter: AppRouter?
    weak var viewController: UIViewController?

    func routeToAccessory(accessoryID: String) {
        appRouter?.present(.accessory(accessoryID))
    }

    func routeToSetup() {
        appRouter?.present(.setup)
    }
}
