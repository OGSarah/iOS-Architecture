//
//  ForecastServiceTests.swift
//  AuroraWatch-MVVM Watch AppTests
//
//  Created by Sarah Clark on 7/16/26.
//

import Foundation
import Testing
@testable import AuroraWatch_MVVM_Watch_App

/// Exercises ``LiveForecastService`` through a stubbed `URLProtocol`.
///
/// Serialized because the stub's handler is process-global; no test here
/// ever touches the live network. The transport failure case cannot go
/// through the stub, because on current SDKs a `URLProtocol` that fails a
/// load makes the session retry it with the default handler against the
/// real network. It uses a dead local proxy instead, which fails during
/// connection setup before any external traffic.
@Suite(.serialized)
struct ForecastServiceTests {

    /// A service whose session routes through ``StubURLProtocol``.
    private func makeService() -> LiveForecastService {
        LiveForecastService(session: StubURLProtocol.makeSession())
    }

    @Test func decodesASuccessfulResponse() async throws {
        StubURLProtocol.respond(status: 200, data: TestFixtures.feedJSON)

        let windows = try await makeService().windows()

        #expect(windows.count == 3)
        #expect(windows[0].kp == 4.33)
        #expect(windows[2].stormLevel == .g3)
    }

    @Test func decodesFractionalKp() async throws {
        StubURLProtocol.respond(status: 200, data: TestFixtures.feedJSON)

        let windows = try await makeService().windows()

        #expect(windows[1].kp == 5.67)
    }

    @Test func returnsEmptyForAnEmptyFeed() async throws {
        StubURLProtocol.respond(status: 200, data: TestFixtures.emptyFeedJSON)

        let windows = try await makeService().windows()

        #expect(windows.isEmpty)
    }

    @Test func requestsTheExactSWPCURL() async throws {
        try await confirmation("request hits the SWPC endpoint") { requested in
            StubURLProtocol.setHandler { request in
                #expect(request.url == LiveForecastService.endpoint)
                requested()
                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil
                )!
                return (response, TestFixtures.emptyFeedJSON)
            }

            _ = try await makeService().windows()
        }
    }

    @Test func mapsServerStatusToServerError() async {
        StubURLProtocol.respond(status: 503, data: Data())

        await #expect(throws: ForecastError.server(statusCode: 503)) {
            _ = try await makeService().windows()
        }
    }

    @Test func mapsMalformedJSONToDecodingError() async {
        StubURLProtocol.respond(status: 200, data: TestFixtures.malformedJSON)

        await #expect(throws: ForecastError.decoding) {
            _ = try await makeService().windows()
        }
    }

    @Test func mapsTransportFailureToNetworkError() async {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.connectionProxyDictionary = [
            "HTTPSEnable": 1,
            "HTTPSProxy": "127.0.0.1",
            "HTTPSPort": 1,
        ]
        let service = LiveForecastService(session: URLSession(configuration: configuration))

        await #expect(throws: ForecastError.network) {
            _ = try await service.windows()
        }
    }
}

/// Pins the user-facing copy for every ``ForecastError``, so wording
/// changes are deliberate rather than accidental.
struct ForecastErrorMessageTests {

    @Test func networkCopyIsPinned() {
        #expect(ForecastError.network.message == "Could not reach the forecast service. Check your connection and try again.")
    }

    @Test func serverCopyIsPinnedAndCarriesTheStatus() {
        #expect(ForecastError.server(statusCode: 503).message == "The forecast service is having trouble (error 503). Try again in a moment.")
    }

    @Test func decodingCopyIsPinned() {
        #expect(ForecastError.decoding.message == "The forecast data came back in an unexpected format. Try again later.")
    }
}
