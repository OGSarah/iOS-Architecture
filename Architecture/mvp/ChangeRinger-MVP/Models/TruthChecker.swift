//
//  TruthChecker.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

import Foundation

/// The checker that judges whether a sequence of rows is a valid touch.
///
/// Two of change ringing's rules are properties of a whole sequence rather than of any one
/// row, and this is where they are enforced:
///
/// - A touch must be true: no row may repeat, anywhere, across the entire sequence. Truth
///   is set membership over the whole expansion, not a check that can be done locally at an
///   edit, which is exactly why it lives in the Model and is tested hard.
/// - A touch must come round: it starts at rounds and has to arrive back at rounds. A
///   sequence that never returns is invalid, however short it is.
///
/// `TruthChecker` is pure: it takes rows and returns a `TruthReport`. It has no knowledge
/// of UIKit.
nonisolated enum TruthChecker {

    /// The verdict on a sequence of rows.
    struct TruthReport: Sendable, Hashable {

        /// Whether the touch is true: no row repeats before it comes round.
        let isTrue: Bool

        /// The index of the first row that repeats an earlier row, if any.
        ///
        /// This is the exact row the editor marks as false. It is `nil` when the touch is
        /// true. The closing return to rounds is never reported here.
        let firstFalseRowIndex: Int?

        /// Whether the touch comes round: rounds is reached again after the start.
        let comesRound: Bool

        /// The index at which the touch comes round, if it does.
        let comeRoundIndex: Int?

        /// Whether the touch is both true and comes round, the bar a composition must clear.
        var isValid: Bool { isTrue && comesRound }
    }

    /// Checks a sequence of rows for truth and for coming round.
    ///
    /// The sequence is expected to start at rounds. The first later row that is rounds marks
    /// coming round and closes the touch; rows from the start up to that point form the body
    /// that must contain no repeats. A repeat inside the body is reported by its index. If
    /// the touch never comes round, the whole sequence is treated as the body.
    ///
    /// - Parameter rows: The rows to check, starting at rounds.
    /// - Returns: A ``TruthReport`` describing truth, the first false row, and coming round.
    static func check(_ rows: [Row]) -> TruthReport {
        guard let first = rows.first else {
            return TruthReport(isTrue: true, firstFalseRowIndex: nil, comesRound: false, comeRoundIndex: nil)
        }

        // Coming round is the first return to rounds after the opening row. That row closes
        // the touch and is excluded from the body that truth is measured over.
        var comeRoundIndex: Int?
        for index in rows.indices where index > 0 && rows[index].isRounds {
            comeRoundIndex = index
            break
        }

        let bodyEnd = comeRoundIndex ?? rows.count
        let body = rows[0..<bodyEnd]

        var seen: Set<Row> = []
        seen.reserveCapacity(body.count)
        var firstFalseRowIndex: Int?
        for index in body.indices {
            if !seen.insert(body[index]).inserted {
                firstFalseRowIndex = index
                break
            }
        }

        // A degenerate opening row that is not rounds cannot come round to itself.
        let comesRound = comeRoundIndex != nil && first.isRounds

        return TruthReport(
            isTrue: firstFalseRowIndex == nil,
            firstFalseRowIndex: firstFalseRowIndex,
            comesRound: comesRound,
            comeRoundIndex: comesRound ? comeRoundIndex : nil
        )
    }
}
