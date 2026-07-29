//
//  AccessorySetupPresenter.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// Builds the setup view model from availability and reacts to the commissioning outcome.
final class AccessorySetupPresenter {

    weak var view: AccessorySetupViewInput?
    private let interactor: AccessorySetupInteractorInput
    private let router: AccessorySetupRouterInput

    init(interactor: AccessorySetupInteractorInput, router: AccessorySetupRouterInput) {
        self.interactor = interactor
        self.router = router
    }
}

// MARK: - AccessorySetupViewOutput

extension AccessorySetupPresenter: AccessorySetupViewOutput {

    func viewDidLoad() {
        interactor.checkAvailability()
    }

    func didTapAddDevice() {
        interactor.commission()
    }

    func didTapCancel() {
        router.close()
    }
}

// MARK: - AccessorySetupInteractorOutput

extension AccessorySetupPresenter: AccessorySetupInteractorOutput {

    func didUpdateAvailability(_ isAvailable: Bool) {
        let message = isAvailable
            ? "Add a Matter accessory to your home. You will be guided through pairing."
            : "Matter setup is not available here. Run on a device with the Matter entitlement to add accessories."
        view?.display(AccessorySetupViewModel(
            title: "Set Up Accessory",
            message: message,
            addButtonTitle: "Add Accessory",
            isAddEnabled: isAvailable
        ))
    }

    func didCommission() {
        router.close()
    }

    func didFail(reason: String) {
        view?.showError(reason)
    }
}
