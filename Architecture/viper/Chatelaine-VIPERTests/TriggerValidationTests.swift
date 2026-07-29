//
//  TriggerValidationTests.swift
//  Chatelaine-VIPERTests
//
//  Created by Sarah Clark on 7/29/26.
//

import Foundation
import Testing
@testable import Chatelaine_VIPER

@MainActor
struct TriggerValidationTests {

    private func draft(event: TriggerEvent, predicate: TriggerPredicate = .none, actions: [DraftAction]? = nil) -> AutomationDraft {
        let defaultActions = [DraftAction(id: "action.1", characteristicID: "char.power", targetValue: .bool(true))]
        return AutomationDraft(
            id: "draft.1",
            name: "Test",
            condition: TriggerCondition(event: event, predicate: predicate),
            actions: actions ?? defaultActions
        )
    }

    @Test("The event and the predicate are kept as separate halves")
    func eventAndPredicateStaySeparate() {
        let subject = draft(
            event: .characteristic(characteristicID: "char.door", value: .bool(true)),
            predicate: .timeOfDay(startSeconds: 0, endSeconds: 3600)
        )
        // Validation must not fold the predicate into the event or drop it.
        guard case let .valid(result) = AutomationValidator.validate(subject) else {
            Issue.record("Expected a valid draft")
            return
        }
        #expect(result.condition.predicate == .timeOfDay(startSeconds: 0, endSeconds: 3600))
        if case .characteristic = result.condition.event {} else {
            Issue.record("The event half changed unexpectedly")
        }
    }

    @Test("An inverted threshold range is rejected")
    func invertedRangeIsRejected() {
        let subject = draft(event: .thresholdRange(characteristicID: "char.temp", lower: 30, upper: 10))
        #expect(AutomationValidator.validate(subject) == .invalid(reason: "The lower bound must be below the upper bound"))
    }

    @Test("An event trigger with an empty action set is rejected")
    func emptyActionSetIsRejected() {
        let subject = draft(event: .thresholdRange(characteristicID: "char.temp", lower: 10, upper: 30), actions: [])
        #expect(AutomationValidator.validate(subject) == .invalid(reason: "Add at least one action for the automation to perform"))
    }

    @Test("A significant time offset beyond the legal window is clamped, not rejected")
    func significantTimeOffsetIsClamped() {
        let beyond = AutomationValidator.maxSignificantTimeOffset + 3600
        let subject = draft(event: .significantTime(kind: .sunset, offset: beyond))
        guard case let .valid(result) = AutomationValidator.validate(subject) else {
            Issue.record("Expected the draft to be clamped and valid")
            return
        }
        guard case let .significantTime(_, offset) = result.condition.event else {
            Issue.record("Expected a significant time event")
            return
        }
        #expect(offset == AutomationValidator.maxSignificantTimeOffset)
    }

    @Test("A significant time offset inside the window is left untouched")
    func significantTimeOffsetWithinWindowIsUnchanged() {
        let subject = draft(event: .significantTime(kind: .sunrise, offset: 1800))
        guard case let .valid(result) = AutomationValidator.validate(subject),
              case let .significantTime(_, offset) = result.condition.event else {
            Issue.record("Expected a valid significant time event")
            return
        }
        #expect(offset == 1800)
    }

    @Test("A valid threshold range with an action passes")
    func validThresholdRangePasses() {
        let subject = draft(event: .thresholdRange(characteristicID: "char.temp", lower: 10, upper: 30))
        #expect(AutomationValidator.isValid(subject))
    }
}
