//
//  OnboardingPresenter.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// Provides the onboarding pages and decides when to advance or finish.
final class OnboardingPresenter {

    weak var view: OnboardingViewInput?
    private let interactor: OnboardingInteractorInput
    private let router: OnboardingRouterInput

    private let pageCount: Int

    init(interactor: OnboardingInteractorInput, router: OnboardingRouterInput) {
        self.interactor = interactor
        self.router = router
        self.pageCount = Self.pages.count
    }

    private static let pages: [OnboardingViewModel.Page] = [
        .init(
            id: 0,
            title: "Meet Chatelaine",
            body: "A chatelaine is the keeper of a household, and the clasp of keys they wore at the waist. This app is that clasp, one holder for a great many accessories.",
            systemImage: "key.fill"
        ),
        .init(
            id: 1,
            title: "Three Columns",
            body: "Your homes and zones sit in the sidebar, a room's accessories in the middle, and the selected accessory's controls in the detail column.",
            systemImage: "sidebar.left"
        ),
        .init(
            id: 2,
            title: "Controls That Fit",
            body: "Every switch, slider, stepper, and picker is generated from what each accessory can actually do, so the controls always match the hardware.",
            systemImage: "slider.horizontal.3"
        ),
        .init(
            id: 3,
            title: "You Are In Control",
            body: "Chatelaine asks for access to your home when you continue. Your accessories never leave your control.",
            systemImage: "checkmark.seal.fill"
        )
    ]
}

// MARK: - OnboardingViewOutput

extension OnboardingPresenter: OnboardingViewOutput {

    func viewDidLoad() {
        view?.display(OnboardingViewModel(
            pages: Self.pages,
            continueTitle: "Continue",
            lastPageTitle: "Get Started",
            skipTitle: "Skip"
        ))
    }

    func didTapContinue(currentPage: Int) {
        let next = currentPage + 1
        if next >= pageCount {
            interactor.markCompleted()
        } else {
            view?.goToPage(next, animated: MotionManager.animationsEnabled)
        }
    }

    func didTapSkip() {
        interactor.markCompleted()
    }
}

// MARK: - OnboardingInteractorOutput

extension OnboardingPresenter: OnboardingInteractorOutput {

    func didComplete() {
        router.finish()
    }
}
