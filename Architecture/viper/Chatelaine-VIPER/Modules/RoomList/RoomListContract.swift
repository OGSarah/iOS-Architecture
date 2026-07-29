//
//  RoomListContract.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// All five protocol boundaries for the RoomList module, gathered in one file.

@MainActor
protocol RoomListViewInput: AnyObject {
    func display(_ viewModel: RoomListViewModel)
}

@MainActor
protocol RoomListViewOutput: AnyObject {
    func viewDidLoad()
    func viewWillDisappear()
    func didSelectAccessory(accessoryID: String)
    func didTapAddAccessory()
}

@MainActor
protocol RoomListInteractorInput: AnyObject {
    func loadInitial()
    func startObserving()
    func stopObserving()
}

@MainActor
protocol RoomListInteractorOutput: AnyObject {
    func didUpdate(home: HomeSnapshot?)
}

@MainActor
protocol RoomListRouterInput: AnyObject {
    func routeToAccessory(accessoryID: String)
    func routeToSetup()
}
