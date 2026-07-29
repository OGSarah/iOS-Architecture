//
//  SettingsInteractor.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// Reads and writes the app's preferences through `MotionManager` and `Preferences`.
final class SettingsInteractor: SettingsInteractorInput {

    weak var output: SettingsInteractorOutput?

    func loadSettings() {
        output?.didLoad(animationsEnabled: Preferences.animationsEnabled)
    }

    func setAnimations(_ isOn: Bool) {
        MotionManager.setInAppEnabled(isOn)
    }

    func replayOnboarding() {
        Preferences.hasCompletedOnboarding = false
    }
}
