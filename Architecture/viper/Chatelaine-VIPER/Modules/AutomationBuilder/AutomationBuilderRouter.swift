//
//  AutomationBuilderRouter.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// Pops the builder off the modal stack once it is done, whether saved or cancelled.
final class AutomationBuilderRouter: AutomationBuilderRouterInput {

    weak var viewController: UIViewController?

    func closeAfterSave() {
        viewController?.navigationController?.popViewController(animated: true)
    }

    func cancel() {
        viewController?.navigationController?.popViewController(animated: true)
    }
}
