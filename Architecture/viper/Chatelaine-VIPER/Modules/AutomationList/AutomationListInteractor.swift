//
//  AutomationListInteractor.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// Loads the saved automations through the read seam.
final class AutomationListInteractor: AutomationListInteractorInput {

    weak var output: AutomationListInteractorOutput?

    private let reader: TriggerReading

    init(reader: TriggerReading) {
        self.reader = reader
    }

    func load() {
        Task { [weak self] in
            guard let self else { return }
            output?.didLoad(await reader.automations())
        }
    }
}
