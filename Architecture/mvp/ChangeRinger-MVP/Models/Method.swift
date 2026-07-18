//
//  Method.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

import Foundation

/// A method: the repeating cycle of changes that defines a way of ringing.
///
/// One turn of the cycle is a lead. The changes of a plain lead are fixed, and the last
/// change of the lead, the lead-end change, is the one a call can replace. A method
/// therefore carries three lead-end changes: the plain one rung by default, and the bob
/// and single substitutions a call selects.
///
/// `Method` is a pure Model value type with no knowledge of UIKit. The library of
/// built-in methods lives here as static fixtures so the engine, the presenter, and the
/// tests all draw from one source of truth.
nonisolated struct Method: Sendable, Hashable {

    /// The method's name, such as `"Plain Bob Minor"`.
    let name: String

    /// The stage the method is rung at.
    let stage: Stage

    /// The changes of one plain lead, in order, ending with the plain lead-end change.
    let plainLead: [PlaceNotation.Change]

    /// The change substituted for the lead-end change when a bob is called.
    let bobLeadEnd: PlaceNotation.Change

    /// The change substituted for the lead-end change when a single is called.
    let singleLeadEnd: PlaceNotation.Change

    /// The number of changes in one lead, which is also the number of rows per lead.
    var leadLength: Int { plainLead.count }

    /// The lead-end change to ring for a given call.
    ///
    /// - Parameter call: The call at this lead end.
    /// - Returns: The plain lead-end change, or the bob or single substitution.
    func leadEndChange(for call: Call) -> PlaceNotation.Change {
        switch call {
            case .plain: return plainLead[leadLength - 1]
            case .bob: return bobLeadEnd
            case .single: return singleLeadEnd
        }
    }
}

nonisolated extension Method {

    /// Builds a method from a notation string, trapping on notation that cannot parse.
    ///
    /// This is used only for the built-in library below, where the notation is a known
    /// literal, so a parse failure is a programming error rather than a runtime concern.
    ///
    /// - Parameters:
    ///   - name: The method's name.
    ///   - stage: The stage the method is rung at.
    ///   - notation: The plain lead notation, such as `"X16X16X16X16X16X12"`.
    ///   - bob: The bob lead-end notation, such as `"14"`.
    ///   - single: The single lead-end notation, such as `"1234"`.
    /// - Returns: The assembled method.
    static func make(
        name: String,
        stage: Stage,
        notation: String,
        bob: String,
        single: String
    ) -> Method {
        // The library notation is a compile-time constant, so a failure here means the
        // literal itself is wrong and should be fixed at the call site.
        guard
            let lead = try? PlaceNotation.parse(notation),
            let bobChanges = try? PlaceNotation.parse(bob),
            let singleChanges = try? PlaceNotation.parse(single),
            let bobEnd = bobChanges.first,
            let singleEnd = singleChanges.first
        else {
            preconditionFailure("Built-in method \(name) has invalid notation.")
        }
        return Method(
            name: name,
            stage: stage,
            plainLead: lead,
            bobLeadEnd: bobEnd,
            singleLeadEnd: singleEnd
        )
    }

    /// Plain Bob Doubles, on five bells.
    static let plainBobDoubles = make(
        name: "Plain Bob Doubles",
        stage: .doubles,
        notation: "5.1.5.1.5.1.5.1.5.125",
        bob: "145",
        single: "123"
    )

    /// Plain Bob Minor, on six bells. Its plain course runs to sixty rows.
    static let plainBobMinor = make(
        name: "Plain Bob Minor",
        stage: .minor,
        notation: "X16X16X16X16X16X12",
        bob: "14",
        single: "1234"
    )

    /// Plain Bob Triples, on seven bells.
    static let plainBobTriples = make(
        name: "Plain Bob Triples",
        stage: .triples,
        notation: "7.1.7.1.7.1.7.1.7.1.7.1.7.127",
        bob: "145",
        single: "123"
    )

    /// Plain Bob Major, on eight bells.
    static let plainBobMajor = make(
        name: "Plain Bob Major",
        stage: .major,
        notation: "X18X18X18X18X18X18X18X12",
        bob: "14",
        single: "1234"
    )

    /// The methods offered by the method picker, one per stage.
    static let library: [Method] = [
        plainBobDoubles,
        plainBobMinor,
        plainBobTriples,
        plainBobMajor
    ]
}
