//
//  ServiceControlRouter.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import Foundation
import UIKit

/// Knows which modules can be reached from ServiceControl and expresses that as route intent.
///
/// It does not know how the next module will be presented, because that is width dependent and
/// belongs to `AppRouter`. It holds its view controller weakly, per the module ownership graph.
final class ServiceControlRouter: ServiceControlRouterInput {

    /// The app router, held weakly. Module routers only express intent to it.
    weak var appRouter: AppRouter?
    /// The view controller this router presents from, held weakly.
    weak var viewController: UIViewController?

    func routeToAutomation(for characteristicID: String) {
        // Seed a fresh draft. The builder module reads the id back out of the route.
        appRouter?.present(.automationBuilder(UUID().uuidString))
    }
}
