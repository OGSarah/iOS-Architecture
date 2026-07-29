//
//  TriggerCondition.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import Foundation

/// Sunrise or sunset, the two significant times a trigger can key off.
enum SignificantTimeKind: Sendable, Equatable, Hashable {
    case sunrise
    case sunset
}

/// The first person arriving, or the last person leaving.
enum PresenceKind: Sendable, Equatable, Hashable {
    case firstPersonArrives
    case lastPersonLeaves
}

/// The event half of a trigger, the thing that makes it fire.
///
/// HomeKit models each of these as a distinct trigger or event type. Keeping them as one enum lets
/// the builder present a single list of choices while the mapper still routes each to the right
/// HomeKit type.
enum TriggerEvent: Sendable, Equatable, Hashable {
    /// A fixed date, optionally repeating on an interval measured in seconds.
    case timer(fireDate: Date, repeatInterval: TimeInterval?)
    /// A characteristic reaching a specific value.
    case characteristic(characteristicID: String, value: CharacteristicValue)
    /// A value entering or leaving a numeric range.
    case thresholdRange(characteristicID: String, lower: Double, upper: Double)
    /// Sunrise or sunset, plus or minus an offset in seconds.
    case significantTime(kind: SignificantTimeKind, offset: TimeInterval)
    /// The first person arriving, or the last person leaving.
    case presence(PresenceKind)
    /// A state having persisted for a set duration in seconds.
    case duration(characteristicID: String, value: CharacteristicValue, seconds: TimeInterval)
}

/// The optional predicate half of a trigger, evaluated after the event fires.
///
/// Users describe both the event and the predicate as "when". The builder sorts one from the other
/// before it can construct anything valid, so an event of "the door opens" and a predicate of
/// "only after sunset" stay apart here.
enum TriggerPredicate: Sendable, Equatable, Hashable {
    case none
    /// Only fire between two times of day, expressed as seconds from midnight.
    case timeOfDay(startSeconds: Int, endSeconds: Int)
    /// Only fire while a characteristic holds a value.
    case characteristic(characteristicID: String, value: CharacteristicValue)
}

/// The event and predicate halves kept together as one condition.
struct TriggerCondition: Sendable, Equatable, Hashable {
    let event: TriggerEvent
    let predicate: TriggerPredicate
}
