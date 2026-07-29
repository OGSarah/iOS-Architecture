//
//  SettingsPresenter.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import Foundation

/// Builds the settings view model and routes the replay and done actions.
final class SettingsPresenter {

    weak var view: SettingsViewInput?
    private let interactor: SettingsInteractorInput
    private let router: SettingsRouterInput

    init(interactor: SettingsInteractorInput, router: SettingsRouterInput) {
        self.interactor = interactor
        self.router = router
    }
}

// MARK: - SettingsViewOutput

extension SettingsPresenter: SettingsViewOutput {

    func viewDidLoad() {
        interactor.loadSettings()
    }

    func didToggleAnimations(_ isOn: Bool) {
        interactor.setAnimations(isOn)
    }

    func didTapReplayOnboarding() {
        interactor.replayOnboarding()
        router.replayOnboarding()
    }

    func didTapDone() {
        router.close()
    }
}

// MARK: - SettingsInteractorOutput

extension SettingsPresenter: SettingsInteractorOutput {

    func didLoad(animationsEnabled: Bool) {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        view?.display(SettingsViewModel(
            title: "Settings",
            animationsRowTitle: "Animations",
            animationsEnabled: animationsEnabled,
            animationsFootnote: "Fun animations. This turns off automatically when the system Reduce Motion setting is on.",
            replayTitle: "Replay Onboarding",
            appearanceNote: "Chatelaine follows your system light and dark appearance.",
            versionText: "Version \(version)"
        ))
    }
}
