//
//  Row.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

import Foundation

/// One row of ringing: a single permutation of the bells.
///
/// A row lists the bells in the order they sound, from the first position to the last.
/// Bells are numbered by pitch, with `1` the highest (the treble) and the largest
/// number the lowest (the tenor). Rounds, the row every touch begins and ends on, is
/// simply the bells in order, written `123456` on six bells.
///
/// `Row` is a pure Model value type. It owns the two domain rules that a single row can
/// answer on its own: whether it is a valid permutation, and whether a step to another
/// row is physically legal. It has no knowledge of UIKit.
nonisolated struct Row: Sendable, Hashable {

    /// The bells in sounding order. `bells[0]` is the bell in the first position.
    let bells: [Int]

    /// Creates a row from bells listed in sounding order.
    ///
    /// - Parameter bells: The bell numbers, from the first position to the last.
    init(bells: [Int]) {
        self.bells = bells
    }

    /// The number of bells in the row.
    var count: Int { bells.count }

    /// Whether the row is a valid permutation of the bells `1...count`.
    ///
    /// A valid row contains each bell from `1` through `count` exactly once. Truth,
    /// legality, and everything else in the domain assume rows are valid permutations.
    var isValidPermutation: Bool {
        Set(bells) == Set(1...count) && bells.count == count
    }

    /// Whether the row is rounds: every bell in ascending order.
    var isRounds: Bool {
        bells == Array(1...count)
    }

    /// Whether stepping from this row to `other` is a physically legal change.
    ///
    /// A tower bell is too heavy to jump: between one row and the next a bell may move
    /// at most one position. This is the single physical fact that makes change ringing
    /// a permutation puzzle. A change is legal only when every bell's position shifts by
    /// no more than one, which is the rule the `RingingEngine` relies on when it folds
    /// place notation into rows.
    ///
    /// - Parameter other: The row reached by a single change.
    /// - Returns: `true` if no bell moves more than one place.
    func changesLegally(to other: Row) -> Bool {
        guard count == other.count else { return false }
        for bell in bells {
            guard
                let from = bells.firstIndex(of: bell),
                let to = other.bells.firstIndex(of: bell)
            else { return false }
            if abs(from - to) > 1 { return false }
        }
        return true
    }

    /// The row written in its natural notation, such as `"123456"`.
    ///
    /// Bells above nine use the ringing convention of `0` for ten, `E` for eleven, and
    /// `T` for twelve, so a row stays a single character per bell.
    var notation: String {
        bells.map(Row.symbol(for:)).joined()
    }

    /// The single-character ringing symbol for a bell number.
    ///
    /// - Parameter bell: The bell number, `1` or greater.
    /// - Returns: The digit for bells one to nine, then `0`, `E`, `T` for ten to twelve.
    static func symbol(for bell: Int) -> String {
        switch bell {
            case 1...9: return String(bell)
            case 10: return "0"
            case 11: return "E"
            case 12: return "T"
            default: return "?"
        }
    }
}

nonisolated extension Row: CustomStringConvertible {

    /// The row in its natural notation, so a row prints as `123456`.
    var description: String { notation }
}
