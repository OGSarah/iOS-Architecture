//
//  PlaceNotationTests.swift
//  ChangeRinger-MVPTests
//
//  Created by Sarah Clark on 7/17/26.
//

import Testing
@testable import ChangeRinger_MVP

/// Tests for parsing, applying, and rendering place notation.
struct PlaceNotationTests {

    @Test("Parsing Plain Bob Minor notation yields the right changes")
    func parsesPlainBobMinor() throws {
        let changes = try PlaceNotation.parse("X16X16X16X16X16X12")
        #expect(changes.count == 12)
        #expect(changes.first?.isCross == true)
        #expect(changes.last?.places == [1, 2])
    }

    @Test("A cross swaps every bell")
    func crossSwapsEveryBell() throws {
        let changes = try PlaceNotation.parse("X")
        let rounds = Stage.minor.rounds
        let next = PlaceNotation.apply(changes[0], to: rounds)
        #expect(next?.notation == "214365")
    }

    @Test("Notation naming a place twice is rejected")
    func rejectsRepeatedPlace() {
        #expect(throws: PlaceNotation.ParseError.repeatedPlace(1)) {
            try PlaceNotation.parse("11")
        }
    }

    @Test("An unrecognised symbol is rejected")
    func rejectsUnknownSymbol() {
        #expect(throws: (any Error).self) {
            try PlaceNotation.parse("Z")
        }
    }

    @Test("Notation round-trips through a string")
    func roundTrips() throws {
        let original = "X16X16X16X16X16X12"
        let changes = try PlaceNotation.parse(original)
        let rendered = PlaceNotation.string(from: changes)
        let reparsed = try PlaceNotation.parse(rendered)
        #expect(reparsed == changes)
    }
}
