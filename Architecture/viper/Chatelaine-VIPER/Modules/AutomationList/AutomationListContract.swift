//
//  AutomationListContract.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// All five protocol boundaries for the AutomationList module, gathered in one file.

@MainActor
protocol AutomationListViewInput: AnyObject {
    func display(_ viewModel: AutomationListViewModel)
}

@MainActor
protocol AutomationListViewOutput: AnyObject {
    func viewDidLoad()
    func didTapCreate()
    func didTapDone()
}

@MainActor
protocol AutomationListInteractorInput: AnyObject {
    func load()
}

@MainActor
protocol AutomationListInteractorOutput: AnyObject {
    func didLoad(_ automations: [AutomationSummary])
}

@MainActor
protocol AutomationListRouterInput: AnyObject {
    func routeToCreate()
    func close()
}
