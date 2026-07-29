//
//  OnboardingContract.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// All five protocol boundaries for the Onboarding module, gathered in one file.

@MainActor
protocol OnboardingViewInput: AnyObject {
    func display(_ viewModel: OnboardingViewModel)
    /// Moves to a page, animating only when motion is enabled.
    func goToPage(_ index: Int, animated: Bool)
}

@MainActor
protocol OnboardingViewOutput: AnyObject {
    func viewDidLoad()
    func didTapContinue(currentPage: Int)
    func didTapSkip()
}

@MainActor
protocol OnboardingInteractorInput: AnyObject {
    func markCompleted()
}

@MainActor
protocol OnboardingInteractorOutput: AnyObject {
    func didComplete()
}

@MainActor
protocol OnboardingRouterInput: AnyObject {
    func finish()
}
