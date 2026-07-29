//
//  ServiceControlBuilder.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// Assembles the five ServiceControl roles and returns the plain view controller they drive.
///
/// The builder wires the ownership graph exactly: the View holds the Presenter, the Presenter holds
/// the Interactor and Router, the Interactor holds its output weakly, and the Router holds the view
/// controller weakly.
enum ServiceControlBuilder {

    /// Builds a ServiceControl screen for one service.
    /// - Parameters:
    ///   - service: The service snapshot to render.
    ///   - writer: The characteristic write seam.
    ///   - notifications: The notification policy seam, or `nil` when not subscribing.
    ///   - appRouter: The app router used for navigation intent.
    /// - Returns: A configured `UIViewController`.
    static func build(
        service: ServiceSnapshot,
        writer: CharacteristicWriting,
        notifications: NotificationPolicy?,
        appRouter: AppRouter?
    ) -> UIViewController {
        let interactor = ServiceControlInteractor(service: service, writer: writer, notifications: notifications)
        let router = ServiceControlRouter()
        router.appRouter = appRouter
        let presenter = ServiceControlPresenter(service: service, interactor: interactor, router: router)
        interactor.output = presenter

        let viewController = ServiceControlViewController(output: presenter)
        presenter.view = viewController
        router.viewController = viewController
        return viewController
    }
}
