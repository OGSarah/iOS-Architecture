//
//  PlaceNotation.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

import Foundation

/// The parser and applier for place notation, the shorthand that describes a change.
///
/// A change is written by listing the places that stay put while every other bell swaps
/// with its neighbour in an adjacent pair. `X` (or `-`) means every bell swaps. `16` on
/// six bells means the bells in positions one and six hold while two and three swap and
/// four and five swap. A method is a repeating cycle of these changes.
///
/// All notation parsing lives here so the `TouchDocument` stays a file format and the
/// `RingingEngine` stays pure folding logic. `PlaceNotation` is a Model type with no
/// knowledge of UIKit.
nonisolated enum PlaceNotation {

    /// A single change: the set of places that stay put while the rest swap in pairs.
    struct Change: Sendable, Hashable {

        /// The one-indexed places that hold. Empty means a cross, where every bell swaps.
        let places: Set<Int>

        /// Whether this change is a cross, in which no place is made and all bells swap.
        var isCross: Bool { places.isEmpty }
    }

    /// A failure encountered while parsing a notation string.
    enum ParseError: Error, Equatable {

        /// A place was named more than once in the same change, such as `"11"`.
        case repeatedPlace(Int)

        /// A character was not a cross, a delimiter, or a valid place.
        case unrecognizedSymbol(Character)

        /// The notation was empty once delimiters were removed.
        case empty
    }

    /// Parses a notation string into its ordered list of changes.
    ///
    /// Changes may be separated by `.` or by a `X`/`-` cross, which stands alone as its
    /// own change. For example `"X16X16X16X12"` and `"-16-16-16-12"` both parse to the
    /// alternating cross and places-made changes they describe.
    ///
    /// - Parameter string: The notation to parse.
    /// - Returns: The changes in the order they are rung.
    /// - Throws: ``ParseError`` if a place repeats within a change or a character is not
    ///   recognised.
    static func parse(_ string: String) throws -> [Change] {
        var changes: [Change] = []
        var currentPlaces: [Int] = []

        func flushPlaces() throws {
            guard !currentPlaces.isEmpty else { return }
            var seen: Set<Int> = []
            for place in currentPlaces {
                guard seen.insert(place).inserted else {
                    throw ParseError.repeatedPlace(place)
                }
            }
            changes.append(Change(places: Set(currentPlaces)))
            currentPlaces = []
        }

        for character in string {
            switch character {
                case "x", "X", "-":
                    try flushPlaces()
                    changes.append(Change(places: []))
                case ".", " ", ",":
                    try flushPlaces()
                default:
                    guard let place = place(for: character) else {
                        throw ParseError.unrecognizedSymbol(character)
                    }
                    currentPlaces.append(place)
            }
        }
        try flushPlaces()

        guard !changes.isEmpty else { throw ParseError.empty }
        return changes
    }

    /// Renders a list of changes back into a canonical notation string.
    ///
    /// Crosses render as `X`. Places-made changes render as their place symbols with a
    /// `.` separating two adjacent places-made changes so the string reparses cleanly.
    ///
    /// - Parameter changes: The changes to render.
    /// - Returns: The notation string, such as `"X16X16X16X12"`.
    static func string(from changes: [Change]) -> String {
        var result = ""
        var previousWasPlaces = false
        for change in changes {
            if change.isCross {
                result += "X"
                previousWasPlaces = false
            } else {
                if previousWasPlaces { result += "." }
                result += change.places.sorted().map(Row.symbol(for:)).joined()
                previousWasPlaces = true
            }
        }
        return result
    }

    /// Applies a single change to a row, producing the next row.
    ///
    /// Positions that make a place keep their bell. Every other position swaps with the
    /// one after it, walking the row in pairs. This is the fold at the heart of the
    /// engine: repeated over a method's changes it generates the whole touch.
    ///
    /// - Parameters:
    ///   - change: The change to apply.
    ///   - row: The row to transform.
    /// - Returns: The row produced by the change, or `nil` if the change cannot be
    ///   applied to a row of this size because a swap would run off the end or collide
    ///   with a made place.
    static func apply(_ change: PlaceNotation.Change, to row: Row) -> Row? {
        var bells = row.bells
        var position = 0
        while position < bells.count {
            let place = position + 1
            if change.places.contains(place) {
                position += 1
            } else {
                guard position + 1 < bells.count else { return nil }
                let nextPlace = position + 2
                guard !change.places.contains(nextPlace) else { return nil }
                bells.swapAt(position, position + 1)
                position += 2
            }
        }
        return Row(bells: bells)
    }

    /// The one-indexed place a notation character names.
    ///
    /// - Parameter character: A place symbol, `1` to `9` then `0`, `E`, `T`.
    /// - Returns: The place number, or `nil` if the character is not a place.
    private static func place(for character: Character) -> Int? {
        switch character {
            case "0": return 10
            case "E", "e": return 11
            case "T", "t": return 12
            default:
                guard let digit = character.wholeNumberValue, (1...9).contains(digit) else {
                    return nil
                }
                return digit
        }
    }
}
