//
//  SettingsRouter.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// Dismisses settings, and asks the app router to replay onboarding when requested.
final class SettingsRouter: SettingsRouterInput {

    weak var appRouter: AppRouter?
    weak var viewController: UIViewController?

    func close() {
        viewController?.dismiss(animated: true)
    }

    func replayOnboarding() {
        // Dismiss settings, then let the app router present onboarding again from a clean state.
        viewController?.dismiss(animated: true) { [weak appRouter] in
            appRouter?.replayOnboarding()
        }
    }
}
