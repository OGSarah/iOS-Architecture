//
//  TriggerMapper.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import Foundation
import HomeKit

/// Bridges between the project's automation value types and HomeKit's trigger objects.
///
/// The forward direction, a draft becoming a HomeKit trigger, is used by `HomeStore` on save. The
/// reverse direction, a trigger becoming a summary, is used to populate the list. Timer and
/// characteristic events are constructed here. The more exotic event kinds report unsupported
/// rather than constructing something HomeKit would accept and then never fire.
enum TriggerMapper {

    /// Summarizes saved triggers for the list.
    /// - Parameter triggers: The home's triggers.
    /// - Returns: One summary per trigger.
    static func summaries(from triggers: [HMTrigger]) -> [AutomationSummary] {
        triggers.map { trigger in
            let detail: String
            switch trigger {
            case is HMTimerTrigger: detail = "Timer"
            case is HMEventTrigger: detail = "Event"
            default: detail = "Automation"
            }
            return AutomationSummary(
                id: trigger.uniqueIdentifier.uuidString,
                name: trigger.name,
                detail: detail,
                isEnabled: trigger.isEnabled
            )
        }
    }

    /// Builds a HomeKit trigger from a validated condition.
    /// - Parameters:
    ///   - name: The trigger's name.
    ///   - condition: The event and predicate to construct from.
    ///   - lookup: A map from characteristic id to the live characteristic.
    /// - Returns: A timer or event trigger.
    /// - Throws: `TriggerWriteError` when a referenced characteristic is missing or the event kind
    ///   is not supported for construction on this device.
    static func makeTrigger(
        name: String,
        condition: TriggerCondition,
        lookup: [String: HMCharacteristic]
    ) throws -> HMTrigger {
        switch condition.event {
        case let .timer(fireDate, _):
            // Constructed as a one shot. Recurrence combinations are restricted by HomeKit, so the
            // repeat interval is not mapped here to avoid building an invalid recurrence.
            return HMTimerTrigger(name: name, fireDate: fireDate, timeZone: nil, recurrence: nil, recurrenceCalendar: nil)

        case let .characteristic(characteristicID, value):
            guard let characteristic = lookup[characteristicID] else { throw TriggerWriteError.rejected }
            let event = HMCharacteristicEvent(characteristic: characteristic, triggerValue: nsValue(value))
            return HMEventTrigger(name: name, events: [event], predicate: predicate(for: condition.predicate, lookup: lookup))

        case .thresholdRange, .significantTime, .presence, .duration:
            throw TriggerWriteError(reason: "This trigger type cannot be saved on this device yet")
        }
    }

    /// Builds the optional predicate for a condition.
    private static func predicate(for predicate: TriggerPredicate, lookup: [String: HMCharacteristic]) -> NSPredicate? {
        switch predicate {
        case .none:
            return nil
        case let .characteristic(characteristicID, value):
            guard let characteristic = lookup[characteristicID], let target = nsValue(value) else { return nil }
            return HMEventTrigger.predicateForEvaluatingTrigger(characteristic, relatedBy: .equalTo, toValue: target)
        case .timeOfDay:
            // Time of day predicates are built from date components and are omitted here for safety.
            return nil
        }
    }

    /// Turns a value into the `NSCopying` object HomeKit's trigger and action APIs expect.
    static func nsValue(_ value: CharacteristicValue) -> (NSCopying & NSObjectProtocol)? {
        switch value {
        case let .bool(bool): NSNumber(value: bool)
        case let .int(int): NSNumber(value: int)
        case let .double(double): NSNumber(value: double)
        case let .string(string): string as NSString
        case let .data(data): data as NSData
        case .unknown: nil
        }
    }
}
