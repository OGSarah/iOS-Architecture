//
//  AutomationBuilderContract.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// The trigger shapes the builder can assemble in this pass.
enum BuilderTriggerType: Equatable {
    case timer
    case thresholdRange
}

/// The raw values the View collected, handed to the Presenter to assemble a draft.
struct AutomationBuilderInput: Equatable {
    let name: String
    let triggerType: BuilderTriggerType
    /// The characteristic the event watches and the action writes to.
    let characteristicID: String
    let lower: Double
    let upper: Double
    /// Whether the action turns the target on or off.
    let turnOn: Bool
}

// MARK: - Boundaries

@MainActor
protocol AutomationBuilderViewInput: AnyObject {
    func display(_ viewModel: AutomationBuilderViewModel)
    /// Shows an inline validation or save error and announces it for VoiceOver.
    func showError(_ reason: String)
}

@MainActor
protocol AutomationBuilderViewOutput: AnyObject {
    func viewDidLoad()
    func didTapSave(_ input: AutomationBuilderInput)
    func didTapCancel()
}

@MainActor
protocol AutomationBuilderInteractorInput: AnyObject {
    func save(_ draft: AutomationDraft)
}

@MainActor
protocol AutomationBuilderInteractorOutput: AnyObject {
    func didSave()
    func didFail(reason: String)
}

@MainActor
protocol AutomationBuilderRouterInput: AnyObject {
    func closeAfterSave()
    func cancel()
}
