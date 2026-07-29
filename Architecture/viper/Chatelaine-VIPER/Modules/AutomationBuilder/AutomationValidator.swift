//
//  AutomationValidator.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import Foundation

/// The result of validating a draft, either a ready draft or a reason it is not ready.
///
/// A validated draft may differ from the input, because some values are clamped into their legal
/// range rather than rejected. A significant time offset beyond the legal window is the example.
enum AutomationValidation: Equatable {
    case valid(AutomationDraft)
    case invalid(reason: String)
}

/// Validates an automation draft. Pure, deterministic, and free of both UIKit and HomeKit.
///
/// This is the logic the README singles out as belonging to an Interactor rather than a view
/// controller. It sorts the event from the predicate, rejects the combinations HomeKit would accept
/// and then silently never fire, and clamps the values that have a legal window.
enum AutomationValidator {

    /// The largest offset, in seconds, a significant time event may carry. Beyond this it is clamped.
    static let maxSignificantTimeOffset: TimeInterval = 4 * 60 * 60

    /// Validates a draft, clamping where a value has a legal window and rejecting where it does not.
    /// - Parameter draft: The draft being assembled.
    /// - Returns: `.valid` with a possibly clamped draft, or `.invalid` with a reason.
    static func validate(_ draft: AutomationDraft) -> AutomationValidation {
        // An event trigger with no action set will never do anything, so it is rejected.
        guard !draft.actions.isEmpty else {
            return .invalid(reason: "Add at least one action for the automation to perform")
        }

        switch draft.condition.event {
        case let .thresholdRange(_, lower, upper):
            // An inverted range can never be entered, so it is rejected rather than clamped.
            guard lower < upper else {
                return .invalid(reason: "The lower bound must be below the upper bound")
            }
            return .valid(draft)

        case let .significantTime(kind, offset):
            // The offset has a legal window, so it is clamped rather than rejected.
            let clamped = max(-maxSignificantTimeOffset, min(maxSignificantTimeOffset, offset))
            guard clamped != offset else { return .valid(draft) }
            var clampedDraft = draft
            clampedDraft.condition = TriggerCondition(
                event: .significantTime(kind: kind, offset: clamped),
                predicate: draft.condition.predicate
            )
            return .valid(clampedDraft)

        case .timer, .characteristic, .presence, .duration:
            return .valid(draft)
        }
    }

    /// A convenience that reports only whether a draft is valid.
    /// - Parameter draft: The draft to check.
    /// - Returns: `true` when the draft validates.
    static func isValid(_ draft: AutomationDraft) -> Bool {
        if case .valid = validate(draft) { return true }
        return false
    }
}
