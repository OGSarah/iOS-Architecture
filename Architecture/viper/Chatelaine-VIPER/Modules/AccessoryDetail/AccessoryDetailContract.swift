//
//  AccessoryDetailContract.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// All five protocol boundaries for the AccessoryDetail module, gathered in one file.

// MARK: - View

@MainActor
protocol AccessoryDetailViewInput: AnyObject {
    func display(_ viewModel: AccessoryDetailViewModel)
}

@MainActor
protocol AccessoryDetailViewOutput: AnyObject {
    func viewDidLoad()
    func viewWillDisappear()
    func didSelectService(serviceID: String)
}

// MARK: - Interactor

@MainActor
protocol AccessoryDetailInteractorInput: AnyObject {
    func loadInitial()
    func startObserving()
    func stopObserving()
}

@MainActor
protocol AccessoryDetailInteractorOutput: AnyObject {
    func didUpdate(accessory: AccessorySnapshot)
}

// MARK: - Router

@MainActor
protocol AccessoryDetailRouterInput: AnyObject {
    /// Presents the generated controls for one service of this accessory.
    func routeToService(_ service: ServiceSnapshot)
}
