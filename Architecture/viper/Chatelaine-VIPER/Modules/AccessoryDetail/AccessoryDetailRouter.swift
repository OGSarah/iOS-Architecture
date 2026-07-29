//
//  AccessoryDetailRouter.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// Opens a service's generated controls by building the ServiceControl module and pushing it.
///
/// Services are the fourth level of the hierarchy. On regular width that is a push within the
/// detail column's own navigation stack, so this router pushes rather than asking `AppRouter`.
final class AccessoryDetailRouter: AccessoryDetailRouterInput {

    weak var viewController: UIViewController?
    weak var appRouter: AppRouter?

    private let writer: CharacteristicWriting
    private let notifications: NotificationPolicy

    init(writer: CharacteristicWriting, notifications: NotificationPolicy) {
        self.writer = writer
        self.notifications = notifications
    }

    func routeToService(_ service: ServiceSnapshot) {
        let controls = ServiceControlBuilder.build(
            service: service,
            writer: writer,
            notifications: notifications,
            appRouter: appRouter
        )
        viewController?.navigationController?.pushViewController(controls, animated: true)
    }
}
