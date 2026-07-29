//
//  AutomationBuilderInteractor.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// Validates a draft, then persists it, keeping both concerns out of the View.
///
/// Validation is the pure `AutomationValidator`. An invalid draft is reported back with a reason and
/// never reaches the writer, which is the split the README describes.
final class AutomationBuilderInteractor: AutomationBuilderInteractorInput {

    weak var output: AutomationBuilderInteractorOutput?

    private let writer: TriggerWriting

    init(writer: TriggerWriting) {
        self.writer = writer
    }

    func save(_ draft: AutomationDraft) {
        switch AutomationValidator.validate(draft) {
        case let .invalid(reason):
            output?.didFail(reason: reason)
        case let .valid(validDraft):
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await writer.save(validDraft)
                    output?.didSave()
                } catch {
                    let reason = (error as? TriggerWriteError)?.reason ?? "The automation could not be saved"
                    output?.didFail(reason: reason)
                }
            }
        }
    }
}
