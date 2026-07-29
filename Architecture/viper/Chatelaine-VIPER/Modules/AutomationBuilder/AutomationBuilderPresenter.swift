//
//  AutomationBuilderPresenter.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import Foundation

/// Assembles a draft from the form's inputs and reacts to the save result.
///
/// It keeps the event and the action separate, which is exactly the distinction the builder exists
/// to enforce, and it never persists anything itself.
final class AutomationBuilderPresenter {

    weak var view: AutomationBuilderViewInput?
    private let interactor: AutomationBuilderInteractorInput
    private let router: AutomationBuilderRouterInput
    private let draftID: String

    init(draftID: String, interactor: AutomationBuilderInteractorInput, router: AutomationBuilderRouterInput) {
        self.draftID = draftID
        self.interactor = interactor
        self.router = router
    }
}

// MARK: - AutomationBuilderViewOutput

extension AutomationBuilderPresenter: AutomationBuilderViewOutput {

    func viewDidLoad() {
        view?.display(AutomationBuilderViewModel(
            title: "New Automation",
            defaultName: "My Automation",
            defaultLower: 18,
            defaultUpper: 24,
            defaultCharacteristicID: "char.temperature"
        ))
    }

    func didTapSave(_ input: AutomationBuilderInput) {
        interactor.save(makeDraft(from: input))
    }

    func didTapCancel() {
        router.cancel()
    }

    private func makeDraft(from input: AutomationBuilderInput) -> AutomationDraft {
        let event: TriggerEvent
        switch input.triggerType {
        case .timer:
            event = .timer(fireDate: Date().addingTimeInterval(3600), repeatInterval: nil)
        case .thresholdRange:
            event = .thresholdRange(characteristicID: input.characteristicID, lower: input.lower, upper: input.upper)
        }
        let action = DraftAction(
            id: draftID + ".action",
            characteristicID: input.characteristicID,
            targetValue: .bool(input.turnOn)
        )
        return AutomationDraft(
            id: draftID,
            name: input.name,
            condition: TriggerCondition(event: event, predicate: .none),
            actions: [action]
        )
    }
}

// MARK: - AutomationBuilderInteractorOutput

extension AutomationBuilderPresenter: AutomationBuilderInteractorOutput {

    func didSave() {
        router.closeAfterSave()
    }

    func didFail(reason: String) {
        view?.showError(reason)
    }
}
