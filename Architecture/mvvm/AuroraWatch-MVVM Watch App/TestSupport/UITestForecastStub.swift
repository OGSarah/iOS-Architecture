//
//  UITestForecastStub.swift
//  AuroraWatch-MVVM Watch App
//
//  Created by Sarah Clark on 7/16/26.
//

#if DEBUG

import Foundation

/// The scenarios a UI test can ask the app to serve instead of calling NOAA.
///
/// Each UI test launch passes one of these raw values in the
/// `UITEST_STUB_SCENARIO` environment variable. Production builds compile
/// none of this out of `#if DEBUG`.
nonisolated enum UITestStubScenario: String, Sendable {

    /// The environment variable the launch scenario travels in.
    static let environmentKey = "UITEST_STUB_SCENARIO"

    /// A healthy three day forecast with a mix of storm levels.
    case happy

    /// A forecast whose strongest window is a G3 storm.
    case g3

    /// A successfully fetched but empty forecast.
    case empty

    /// Every fetch fails with a server error.
    case error

    /// The first fetch fails, every following fetch serves the happy
    /// forecast. Drives the retry recovery flow.
    case recovers

    /// Reads the scenario for this launch, if the environment carries one.
    static func fromEnvironment(_ environment: [String: String] = ProcessInfo.processInfo.environment) -> UITestStubScenario? {
        environment[environmentKey].flatMap(UITestStubScenario.init(rawValue:))
    }
}

/// A ``ForecastService`` that serves canned fixtures for UI test runs.
///
/// An actor because the `recovers` scenario mutates state across fetches
/// and the service must stay `Sendable`.
actor UITestForecastStub: ForecastService {

    /// The scenario this launch is serving.
    private let scenario: UITestStubScenario

    /// How many fetches have completed, used by `recovers`.
    private var fetchCount = 0

    /// Creates a stub serving the given scenario.
    init(scenario: UITestStubScenario) {
        self.scenario = scenario
    }

    func windows() async throws -> [ForecastWindow] {
        fetchCount += 1
        switch scenario {
        case .happy:
            return Self.happyWindows
        case .g3:
            return Self.g3Windows
        case .empty:
            return []
        case .error:
            throw ForecastError.server(statusCode: 503)
        case .recovers:
            if fetchCount == 1 {
                throw ForecastError.server(statusCode: 503)
            }
            return Self.happyWindows
        }
    }

    /// Fixture windows at successive three hour marks from launch,
    /// covering quiet through G2 so rows show varied badges.
    private static var happyWindows: [ForecastWindow] {
        makeWindows(kps: [(2.33, .observed), (4.67, .estimated), (5.33, .predicted), (6.67, .predicted)])
    }

    /// Fixture windows whose second entry is a G3 storm.
    private static var g3Windows: [ForecastWindow] {
        makeWindows(kps: [(3.0, .observed), (7.33, .predicted), (5.0, .predicted)])
    }

    /// Builds windows starting one hour ago and stepping three hours apart,
    /// so relative times are stable for the duration of a test run.
    private static func makeWindows(kps: [(Double, ForecastWindow.Observation)]) -> [ForecastWindow] {
        let start = Date().addingTimeInterval(-60 * 60)
        return kps.enumerated().map { index, entry in
            ForecastWindow(
                date: start.addingTimeInterval(TimeInterval(index) * 3 * 60 * 60),
                kp: entry.0,
                observation: entry.1
            )
        }
    }
}

#endif
