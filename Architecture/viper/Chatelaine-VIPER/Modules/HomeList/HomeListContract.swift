//
//  HomeListContract.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// All five protocol boundaries for the HomeList module, gathered in one file.

@MainActor
protocol HomeListViewInput: AnyObject {
    func display(_ viewModel: HomeListViewModel)
}

@MainActor
protocol HomeListViewOutput: AnyObject {
    func viewDidLoad()
    func viewWillDisappear()
    func didSelectRow(id: String)
}

@MainActor
protocol HomeListInteractorInput: AnyObject {
    func loadInitial()
    func startObserving()
    func stopObserving()
}

@MainActor
protocol HomeListInteractorOutput: AnyObject {
    /// The latest home, or `nil` when there is none or access has not been granted.
    func didUpdate(home: HomeSnapshot?, authorization: HomeAuthorizationStatus)
}

@MainActor
protocol HomeListRouterInput: AnyObject {
    func routeToHome(homeID: String)
}
