//
//  AutomationListPresenter.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// Builds the automation list view model and routes to create or dismiss.
final class AutomationListPresenter {

    weak var view: AutomationListViewInput?
    private let interactor: AutomationListInteractorInput
    private let router: AutomationListRouterInput

    init(interactor: AutomationListInteractorInput, router: AutomationListRouterInput) {
        self.interactor = interactor
        self.router = router
    }
}

// MARK: - AutomationListViewOutput

extension AutomationListPresenter: AutomationListViewOutput {

    func viewDidLoad() {
        interactor.load()
    }

    func didTapCreate() {
        router.routeToCreate()
    }

    func didTapDone() {
        router.close()
    }
}

// MARK: - AutomationListInteractorOutput

extension AutomationListPresenter: AutomationListInteractorOutput {

    func didLoad(_ automations: [AutomationSummary]) {
        let rows = automations.map { automation in
            let state = automation.isEnabled ? "On" : "Off"
            return AutomationListViewModel.Row(
                id: automation.id,
                name: automation.name,
                detail: "\(automation.detail) \u{2022} \(state)",
                accessibilityLabel: "\(automation.name), \(automation.detail), \(state)"
            )
        }
        view?.display(AutomationListViewModel(
            title: "Automations",
            emptyMessage: rows.isEmpty ? "No automations yet. Tap add to create one." : nil,
            rows: rows
        ))
    }
}
