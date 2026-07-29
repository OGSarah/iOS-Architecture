//
//  OnboardingBuilder.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// Assembles the Onboarding module, presented full screen on first launch.
enum OnboardingBuilder {

    /// Builds the onboarding flow.
    /// - Parameter onFinish: Called when the user finishes or skips onboarding.
    /// - Returns: A full screen onboarding view controller.
    static func build(onFinish: @escaping () -> Void) -> UIViewController {
        let interactor = OnboardingInteractor()
        let router = OnboardingRouter(onFinish: onFinish)
        let presenter = OnboardingPresenter(interactor: interactor, router: router)
        interactor.output = presenter

        let viewController = OnboardingViewController(output: presenter)
        presenter.view = viewController
        viewController.modalPresentationStyle = .fullScreen
        return viewController
    }
}
