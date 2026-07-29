//
//  AccessorySetupInteractor.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// Drives commissioning through the injected seam and reports availability and outcome.
final class AccessorySetupInteractor: AccessorySetupInteractorInput {

    weak var output: AccessorySetupInteractorOutput?

    private let commissioner: AccessoryCommissioning

    init(commissioner: AccessoryCommissioning) {
        self.commissioner = commissioner
    }

    func checkAvailability() {
        output?.didUpdateAvailability(commissioner.isAvailable)
    }

    func commission() {
        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await commissioner.commission(setupPayload: "")
                output?.didCommission()
            } catch {
                let reason = (error as? CommissionError)?.reason ?? "The accessory could not be added"
                output?.didFail(reason: reason)
            }
        }
    }
}
