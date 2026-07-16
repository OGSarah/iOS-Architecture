//
//  ForecastService.swift
//  AuroraWatch-MVVM Watch App
//
//  Created by Sarah Clark on 7/16/26.
//

import Foundation

/// The model layer's single seam: anything that can produce forecast windows.
///
/// View models are handed `any ForecastService`, so a test can inject a fake
/// and the widget can share the live implementation. Nothing behind this
/// protocol knows a view exists.
nonisolated protocol ForecastService: Sendable {

    /// Fetches the upcoming planetary K-index forecast windows.
    ///
    /// - Returns: The windows in the order the source published them.
    /// - Throws: ``ForecastError`` describing what went wrong.
    func windows() async throws -> [ForecastWindow]
}

/// The live implementation backed by NOAA's Space Weather Prediction Center.
nonisolated struct LiveForecastService: ForecastService {

    /// SWPC's three day planetary K-index forecast product.
    static let endpoint = URL(string: "https://services.swpc.noaa.gov/products/noaa-planetary-k-index-forecast.json")!

    /// The session used for the fetch. Injected so tests can install a
    /// stubbed `URLProtocol` and never touch the network.
    private let session: URLSession

    /// Creates a live service.
    ///
    /// - Parameter session: The `URLSession` to fetch with. Defaults to
    ///   `.shared` for production use.
    init(session: URLSession = .shared) {
        self.session = session
    }

    func windows() async throws -> [ForecastWindow] {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: Self.endpoint)
        } catch {
            throw ForecastError.network
        }

        if let http = response as? HTTPURLResponse, !(200 ..< 300).contains(http.statusCode) {
            throw ForecastError.server(statusCode: http.statusCode)
        }

        do {
            return try JSONDecoder().decode(ForecastFeed.self, from: data).windows
        } catch {
            throw ForecastError.decoding
        }
    }
}

/// Everything that can go wrong while fetching a forecast, with user-facing
/// copy pinned by the unit tests so wording changes are deliberate.
nonisolated enum ForecastError: Error, Equatable, Sendable {

    /// The request never completed, for example no connectivity.
    case network

    /// The server answered with a non-success HTTP status.
    case server(statusCode: Int)

    /// The payload arrived but could not be decoded.
    case decoding

    /// The one line message the error view displays.
    var message: String {
        switch self {
        case .network:
            "Could not reach the forecast service. Check your connection and try again."
        case .server(let statusCode):
            "The forecast service is having trouble (error \(statusCode)). Try again in a moment."
        case .decoding:
            "The forecast data came back in an unexpected format. Try again later."
        }
    }
}
