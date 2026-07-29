//
//  AccessorySetupContract.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// All five protocol boundaries for the AccessorySetup module, gathered in one file.

@MainActor
protocol AccessorySetupViewInput: AnyObject {
    func display(_ viewModel: AccessorySetupViewModel)
    func showError(_ reason: String)
}

@MainActor
protocol AccessorySetupViewOutput: AnyObject {
    func viewDidLoad()
    func didTapAddDevice()
    func didTapCancel()
}

@MainActor
protocol AccessorySetupInteractorInput: AnyObject {
    func checkAvailability()
    func commission()
}

@MainActor
protocol AccessorySetupInteractorOutput: AnyObject {
    func didUpdateAvailability(_ isAvailable: Bool)
    func didCommission()
    func didFail(reason: String)
}

@MainActor
protocol AccessorySetupRouterInput: AnyObject {
    func close()
}
