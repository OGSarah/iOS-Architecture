//
//  TestHelpers.swift
//  AuroraWatch-MVVM Watch AppTests
//
//  Created by Sarah Clark on 7/16/26.
//

import Foundation
@testable import AuroraWatch_MVVM_Watch_App

/// Shared fixtures and deterministic clocks for the unit tests.
///
/// Every date is built in UTC and every locale is pinned, so no test
/// depends on the machine it runs on.
enum TestFixtures {

    /// The locale all display string assertions are pinned to.
    static let enUS = Locale(identifier: "en_US")

    /// A fixed reference instant: 2026-07-16 12:00:00 UTC.
    static let referenceDate = utcDate(year: 2026, month: 7, day: 16, hour: 12)

    /// Builds a date in UTC from calendar components.
    static func utcDate(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0, second: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second)
        guard let date = calendar.date(from: components) else {
            fatalError("Invalid test date components")
        }
        return date
    }

    /// Builds a window offset from ``referenceDate`` by whole hours.
    static func window(
        kp: Double = 5.33,
        hoursFromReference: Double = 3,
        observation: ForecastWindow.Observation = .predicted
    ) -> ForecastWindow {
        ForecastWindow(
            date: referenceDate.addingTimeInterval(hoursFromReference * 60 * 60),
            kp: kp,
            observation: observation
        )
    }

    /// A healthy SWPC payload, in the live feed's array-of-objects shape:
    /// three windows, including a fractional Kp and each observation kind.
    static let feedJSON = Data("""
    [
      {"time_tag": "2026-07-16T00:00:00", "kp": 4.33, "observed": "observed", "noaa_scale": null},
      {"time_tag": "2026-07-16T03:00:00", "kp": 5.67, "observed": "estimated", "noaa_scale": null},
      {"time_tag": "2026-07-16T06:00:00", "kp": 7.00, "observed": "predicted", "noaa_scale": "G3"}
    ]
    """.utf8)

    /// A successfully fetched but empty forecast.
    static let emptyFeedJSON = Data("[]".utf8)

    /// A payload whose Kp value is not a number.
    static let badKpJSON = Data("""
    [
      {"time_tag": "2026-07-16T00:00:00", "kp": "not-a-number", "observed": "observed", "noaa_scale": null}
    ]
    """.utf8)

    /// A payload whose timestamp is not in SWPC's shape.
    static let badTimestampJSON = Data("""
    [
      {"time_tag": "July 16th", "kp": 4.33, "observed": "observed", "noaa_scale": null}
    ]
    """.utf8)

    /// A payload with an observation kind the model does not know.
    static let badObservationJSON = Data("""
    [
      {"time_tag": "2026-07-16T00:00:00", "kp": 4.33, "observed": "guessed", "noaa_scale": null}
    ]
    """.utf8)

    /// A payload that is not the array-of-objects shape at all.
    static let malformedJSON = Data(#"{"unexpected": "shape"}"#.utf8)
}
