//
//  ForecastWindowTests.swift
//  AuroraWatch-MVVM Watch AppTests
//
//  Created by Sarah Clark on 7/16/26.
//

import Foundation
import Testing
@testable import AuroraWatch_MVVM_Watch_App

/// Covers decoding SWPC's array-of-objects payload into ``ForecastWindow``
/// values, including the shapes that must fail.
struct ForecastWindowTests {

    private func decode(_ data: Data) throws -> [ForecastWindow] {
        try JSONDecoder().decode(ForecastFeed.self, from: data).windows
    }

    @Test func decodesEveryWindowWithUTCDates() throws {
        let windows = try decode(TestFixtures.feedJSON)

        #expect(windows.count == 3)
        #expect(windows[0].date == TestFixtures.utcDate(year: 2026, month: 7, day: 16, hour: 0))
        #expect(windows[1].date == TestFixtures.utcDate(year: 2026, month: 7, day: 16, hour: 3))
        #expect(windows[2].date == TestFixtures.utcDate(year: 2026, month: 7, day: 16, hour: 6))
    }

    @Test func decodesFractionalKpValues() throws {
        let windows = try decode(TestFixtures.feedJSON)

        #expect(windows[0].kp == 4.33)
        #expect(windows[1].kp == 5.67)
        #expect(windows[2].kp == 7.0)
    }

    @Test func decodesEveryObservationKind() throws {
        let windows = try decode(TestFixtures.feedJSON)

        #expect(windows[0].observation == .observed)
        #expect(windows[1].observation == .estimated)
        #expect(windows[2].observation == .predicted)
    }

    @Test func decodesEmptyFeedAsNoWindows() throws {
        let windows = try decode(TestFixtures.emptyFeedJSON)

        #expect(windows.isEmpty)
    }

    @Test func throwsOnNonNumericKp() {
        #expect(throws: DecodingError.self) {
            _ = try decode(TestFixtures.badKpJSON)
        }
    }

    @Test func throwsOnUnrecognizedTimestamp() {
        #expect(throws: DecodingError.self) {
            _ = try decode(TestFixtures.badTimestampJSON)
        }
    }

    @Test func throwsOnUnknownObservationKind() {
        #expect(throws: DecodingError.self) {
            _ = try decode(TestFixtures.badObservationJSON)
        }
    }

    @Test func identityIsTheWindowStart() {
        let window = TestFixtures.window(hoursFromReference: 6)

        #expect(window.id == window.date)
    }

    @Test func stormLevelDerivesFromKp() {
        #expect(TestFixtures.window(kp: 7.33).stormLevel == .g3)
        #expect(TestFixtures.window(kp: 2.0).stormLevel == .quiet)
    }
}
