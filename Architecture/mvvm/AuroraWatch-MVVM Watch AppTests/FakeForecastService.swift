//
//  FakeForecastService.swift
//  AuroraWatch-MVVM Watch AppTests
//
//  Created by Sarah Clark on 7/16/26.
//

import Foundation
@testable import AuroraWatch_MVVM_Watch_App

/// An in-memory ``ForecastService`` that drives the view model tests.
///
/// Beyond returning a canned result, it counts calls and can hold a fetch
/// open on demand, which is how the tests observe mid-flight state such as
/// "refresh does not flash a spinner" and "a second load does not
/// double fetch".
actor FakeForecastService: ForecastService {

    /// How many times ``windows()`` has been entered.
    private(set) var callCount = 0

    /// The result the next fetch resolves to.
    private var result: Result<[ForecastWindow], ForecastError>

    /// When set, the next fetch suspends after incrementing ``callCount``
    /// until ``open()`` is called.
    private var shouldGateNextFetch = false

    /// The suspension point of a gated fetch.
    private var gate: CheckedContinuation<Void, Never>?

    /// Creates a fake resolving to the given result.
    init(result: Result<[ForecastWindow], ForecastError>) {
        self.result = result
    }

    /// Replaces the result future fetches resolve to.
    func set(result: Result<[ForecastWindow], ForecastError>) {
        self.result = result
    }

    /// Makes the next fetch suspend until ``open()``.
    func gateNextFetch() {
        shouldGateNextFetch = true
    }

    /// Releases a fetch suspended by ``gateNextFetch()``.
    func open() {
        gate?.resume()
        gate = nil
    }

    func windows() async throws -> [ForecastWindow] {
        callCount += 1
        if shouldGateNextFetch {
            shouldGateNextFetch = false
            await withCheckedContinuation { continuation in
                gate = continuation
            }
        }
        return try result.get()
    }
}
