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
///
/// Handlers are stored per subclass so independent test suites can run
/// in parallel without racing on shared state: each suite that needs
/// the network talks to its own `StubURLProtocol` subclass (see
/// `ListStubURLProtocol`).
class StubURLProtocol: URLProtocol {

    // Handlers are set by tests and read by URLProtocol instances on
    // background loading threads, so access is guarded by a lock.
    private static let lock = NSLock()
    nonisolated(unsafe) private static var handlers: [ObjectIdentifier: (URLRequest) throws -> (HTTPURLResponse, Data)] = [:]

    /// The handler answering requests routed through this class. Reading
    /// on a subclass sees only that subclass's handler.
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))? {
        get { lock.withLock { handlers[ObjectIdentifier(self)] } }
        set { lock.withLock { handlers[ObjectIdentifier(self)] = newValue } }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = type(of: self).requestHandler else {
            fatalError("\(type(of: self)).requestHandler was not set before the request was made")
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

    /// Creates an ephemeral session that routes every request through
    /// the subclass this is called on.
    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [self]
        return URLSession(configuration: configuration)
    }
}

/// Dedicated stub for `RepositoryListViewControllerTests` so its
/// handler cannot race `RepositoryModelTests`, which uses the base
/// class and may run in parallel in the same process.
final class ListStubURLProtocol: StubURLProtocol {}
