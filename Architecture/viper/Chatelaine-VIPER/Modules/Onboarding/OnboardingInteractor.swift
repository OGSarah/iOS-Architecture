//
//  OnboardingInteractor.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// Records that onboarding has been completed so it does not show again.
final class OnboardingInteractor: OnboardingInteractorInput {

    weak var output: OnboardingInteractorOutput?

    func markCompleted() {
        Preferences.hasCompletedOnboarding = true
        output?.didComplete()
    }
}
