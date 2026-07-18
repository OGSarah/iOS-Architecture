//
//  RingingEngine.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

import Foundation

/// The engine that expands a `Touch` into the rows it produces.
///
/// This is the heart of the Model and the reason the domain is worth its own layer. It is
/// pure and static: it takes a touch and returns the rows, or a reason the touch is not
/// ringable. It folds the method's place notation over the previous row again and again,
/// substituting a call's notation at any lead end where a call is placed, and stops when
/// the ringing comes round.
///
/// Because a call rewrites every row after it, there is no partial recompute: the engine
/// always expands from rounds. It has no mutation, no async, no `import UIKit`, and no
/// knowledge that a screen exists.
nonisolated enum RingingEngine {

    /// A reason a touch cannot be expanded into rows.
    enum RejectionReason: Error, Equatable {

        /// A call was placed at a row that is not a lead end, where no call is legal.
        case callNotAtLeadEnd(rowIndex: Int)

        /// A change could not be applied to a row, which means the method notation is
        /// malformed for the stage. Built-in methods never hit this.
        case malformedNotation
    }

    /// Expands a touch into the sequence of rows it rings.
    ///
    /// The returned rows begin with rounds as row `0`. Each later row is the one reached by
    /// applying the next change. If the ringing returns to rounds at a lead end, expansion
    /// stops there and rounds appears as the final row, marking that the touch has come
    /// round. If it never comes round within the touch's lead bound, every row rung so far
    /// is returned so the `TruthChecker` can report the failure to come round.
    ///
    /// - Parameter touch: The composition to expand.
    /// - Returns: `.success` with the rows, or `.failure` with the reason it was rejected.
    static func expand(_ touch: Touch) -> Result<[Row], RejectionReason> {
        let method = touch.method
        let leadLength = method.leadLength

        // A call is legal only at a lead end. Reject before ringing a single row so an
        // illegal edit leaves the caller's previous rows untouched.
        for rowIndex in touch.calls.keys where !touch.isLeadEnd(rowIndex: rowIndex) {
            return .failure(.callNotAtLeadEnd(rowIndex: rowIndex))
        }

        var rows: [Row] = [method.stage.rounds]
        var current = method.stage.rounds

        for lead in 1...max(touch.maxLeads, 1) {
            for changeIndex in 0..<leadLength {
                let isLeadEndChange = changeIndex == leadLength - 1
                let rowIndex = (lead - 1) * leadLength + changeIndex + 1
                let call = isLeadEndChange ? (touch.calls[rowIndex] ?? .plain) : .plain
                let change = isLeadEndChange
                    ? method.leadEndChange(for: call)
                    : method.plainLead[changeIndex]

                guard let next = PlaceNotation.apply(change, to: current) else {
                    return .failure(.malformedNotation)
                }
                rows.append(next)
                current = next
            }

            // A touch comes round at a lead end. Stopping here keeps the closing rounds
            // as the final row, which the truth checker treats as the return, not a repeat.
            if current.isRounds {
                return .success(rows)
            }
        }

        return .success(rows)
    }
}
