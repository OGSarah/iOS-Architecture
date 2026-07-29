//
//  OnboardingRouter.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// Hands control back to the app once onboarding finishes, through an injected closure.
final class OnboardingRouter: OnboardingRouterInput {

    private let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func finish() {
        onFinish()
    }
}
