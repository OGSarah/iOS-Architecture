//
//  StubURLProtocol.swift
//  AuroraWatch-MVVM Watch AppTests
//
//  Created by Sarah Clark on 7/16/26.
//

import Foundation
import Synchronization

/// A `URLProtocol` that answers every request from a test-provided closure,
/// so ``LiveForecastService`` can be exercised without touching the network.
///
/// The handler is process-global, which is why ``ForecastServiceTests`` runs
/// serialized: two parallel tests would otherwise race on it.
final class StubURLProtocol: URLProtocol {

    /// Produces the response for a request, or throws to simulate a
    /// transport failure.
    typealias Handler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    /// The current handler, guarded because URL loading happens off the
    /// test's thread.
    private static let currentHandler = Mutex<Handler?>(nil)

    /// Installs the handler the next requests will be served by.
    static func setHandler(_ handler: @escaping Handler) {
        currentHandler.withLock { $0 = handler }
    }

    /// Builds an ephemeral session that routes through this protocol.
    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    /// Convenience for stubbing a plain HTTP response for any request.
    static func respond(status: Int, data: Data) {
        setHandler { request in
            guard let url = request.url,
                  let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil) else {
                throw URLError(.badURL)
            }
            return (response, data)
        }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.currentHandler.withLock({ $0 }) else {
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
