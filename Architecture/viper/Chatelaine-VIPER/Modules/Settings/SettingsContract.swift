//
//  SettingsContract.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// All five protocol boundaries for the Settings module, gathered in one file.

@MainActor
protocol SettingsViewInput: AnyObject {
    func display(_ viewModel: SettingsViewModel)
}

@MainActor
protocol SettingsViewOutput: AnyObject {
    func viewDidLoad()
    func didToggleAnimations(_ isOn: Bool)
    func didTapReplayOnboarding()
    func didTapDone()
}

@MainActor
protocol SettingsInteractorInput: AnyObject {
    func loadSettings()
    func setAnimations(_ isOn: Bool)
    func replayOnboarding()
}

@MainActor
protocol SettingsInteractorOutput: AnyObject {
    func didLoad(animationsEnabled: Bool)
}

@MainActor
protocol SettingsRouterInput: AnyObject {
    func close()
    func replayOnboarding()
}
