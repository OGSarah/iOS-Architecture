//
//  ForecastWindow.swift
//  AuroraWatch-MVVM Watch App
//
//  Created by Sarah Clark on 7/16/26.
//

import Foundation

/// A single three hour planetary K-index forecast window from NOAA's
/// Space Weather Prediction Center.
///
/// `ForecastWindow` is a plain value type. It knows nothing about the UI,
/// which is what lets the app, the widget, and the tests all consume it
/// without pulling in SwiftUI.
nonisolated struct ForecastWindow: Identifiable, Hashable, Sendable {

    /// How SWPC arrived at the Kp value for a window.
    enum Observation: String, Sendable {
        /// The value was measured by ground stations.
        case observed
        /// The value is an estimate blending measurement and model output.
        case estimated
        /// The value is a model prediction for a future window.
        case predicted
    }

    /// The UTC start of the three hour window.
    let date: Date

    /// The planetary K-index for the window, on the 0 to 9 scale.
    /// SWPC publishes fractional values such as 4.33.
    let kp: Double

    /// Whether `kp` was observed, estimated, or predicted.
    let observation: Observation

    /// Windows are unique per start date, so the date doubles as identity.
    var id: Date { date }

    /// The geomagnetic storm level this window's Kp maps to.
    ///
    /// The mapping rule lives on ``StormLevel`` because it is true
    /// regardless of what is on screen.
    var stormLevel: StormLevel { StormLevel(kp: kp) }
}

/// The decoded form of SWPC's `noaa-planetary-k-index-forecast.json` payload.
///
/// The service publishes a JSON array of row objects shaped like
/// `{"time_tag": "2026-07-16T00:00:00", "kp": 4.33, "observed": "observed",
/// "noaa_scale": null}`, with timestamps in UTC. This wrapper hides that
/// shape from the rest of the app: decode a `ForecastFeed`, read `windows`.
nonisolated struct ForecastFeed: Decodable, Sendable {

    /// The forecast windows in the order SWPC published them.
    let windows: [ForecastWindow]

    /// One row of the payload, in SWPC's own vocabulary.
    private struct Row: Decodable {
        let timeTag: String
        let kp: Double
        let observed: String

        enum CodingKeys: String, CodingKey {
            case timeTag = "time_tag"
            case kp
            case observed
        }
    }

    /// The fixed strategy for SWPC timestamps, such as `2026-07-16T00:00:00`,
    /// which are always UTC and always this exact shape.
    private static var timestampStrategy: Date.ParseStrategy {
        Date.ParseStrategy(
            format: "\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits)T\(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits):\(second: .twoDigits)",
            locale: Locale(identifier: "en_US_POSIX"),
            timeZone: .gmt
        )
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rows = try container.decode([Row].self)

        windows = try rows.map { row in
            guard let date = try? Date(row.timeTag, strategy: Self.timestampStrategy) else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unrecognized SWPC timestamp: \(row.timeTag)"
                ))
            }
            guard let observation = ForecastWindow.Observation(rawValue: row.observed) else {
                throw DecodingError.dataCorrupted(.init(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unrecognized observation kind: \(row.observed)"
                ))
            }
            return ForecastWindow(date: date, kp: row.kp, observation: observation)
        }
    }
}
