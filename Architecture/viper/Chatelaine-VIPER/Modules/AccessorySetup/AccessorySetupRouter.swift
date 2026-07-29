//
//  AccessorySetupRouter.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// Dismisses the setup modal when the flow ends, whether it succeeded or was cancelled.
final class AccessorySetupRouter: AccessorySetupRouterInput {

    weak var viewController: UIViewController?

    func close() {
        viewController?.dismiss(animated: true)
    }
}
