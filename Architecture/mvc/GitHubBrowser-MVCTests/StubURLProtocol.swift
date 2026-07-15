//
//  StubURLProtocol.swift
//  GitHubBrowser-MVC
//
//  Created by Sarah Clark on 7/15/26.
//

import Foundation

/// A stand in for the network used only in tests. It intercepts
/// requests made through a URLSession configured with it and returns
/// whatever response the test has set up.
final class StubURLProtocol: URLProtocol {

    // The handler is set by the test and read by URLProtocol instances on
    // background loading threads, so access is guarded by a lock.
    private static let lock = NSLock()
    nonisolated(unsafe) private static var _requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))? {
        get { lock.withLock { _requestHandler } }
        set { lock.withLock { _requestHandler = newValue } }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = StubURLProtocol.requestHandler else {
            fatalError("StubURLProtocol.requestHandler was not set before the request was made")
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

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}
