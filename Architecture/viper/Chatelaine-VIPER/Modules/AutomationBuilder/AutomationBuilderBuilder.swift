//
//  AutomationBuilderBuilder.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// Assembles the AutomationBuilder module and returns the form view controller for pushing.
enum AutomationBuilderBuilder {

    static func build(draftID: String, writer: TriggerWriting) -> UIViewController {
        let interactor = AutomationBuilderInteractor(writer: writer)
        let router = AutomationBuilderRouter()
        let presenter = AutomationBuilderPresenter(draftID: draftID, interactor: interactor, router: router)
        interactor.output = presenter

        let viewController = AutomationBuilderViewController(output: presenter)
        presenter.view = viewController
        router.viewController = viewController
        return viewController
    }
}
