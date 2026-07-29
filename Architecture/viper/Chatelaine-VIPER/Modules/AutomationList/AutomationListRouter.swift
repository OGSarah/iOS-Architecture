//
//  AutomationListRouter.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import Foundation
import UIKit

/// Pushes the builder to create a new automation, and dismisses the modal when done.
final class AutomationListRouter: AutomationListRouterInput {

    weak var viewController: UIViewController?

    private let writer: TriggerWriting

    init(writer: TriggerWriting) {
        self.writer = writer
    }

    func routeToCreate() {
        let builder = AutomationBuilderBuilder.build(draftID: UUID().uuidString, writer: writer)
        viewController?.navigationController?.pushViewController(builder, animated: true)
    }

    func close() {
        viewController?.dismiss(animated: true)
    }
}
