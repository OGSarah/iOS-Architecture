//
//  UITestNetworkStub.swift
//  GitHubBrowser-MVC
//
//  Created by Sarah Clark on 7/15/26.
//

#if DEBUG
import Foundation

/// The network scenario a UI test asks the app to simulate, passed via
/// the `UITEST_STUB_SCENARIO` launch environment variable. When the
/// variable is present, `SceneDelegate` wires the list controller to a
/// stubbed session so UI tests are fast, deterministic, and never
/// depend on the live GitHub API. Compiled out of Release builds.
nonisolated enum UITestScenario: String {

    /// GitHub returns two fixture repositories.
    case success

    /// GitHub returns an empty repository list.
    case empty

    /// GitHub responds with a 500 server error.
    case error

    /// The scenario requested by the running UI test, if any.
    static var current: UITestScenario? {
        ProcessInfo.processInfo.environment["UITEST_STUB_SCENARIO"]
            .flatMap(UITestScenario.init(rawValue:))
    }

    /// Creates a session whose requests are all answered locally by
    /// `UITestStubURLProtocol` instead of the network.
    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [UITestStubURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

/// Serves canned GitHub API responses during UI test runs.
///
/// `URLProtocol` callbacks arrive on background loader threads, so this
/// class must stay `nonisolated` despite the target's main-actor default.
nonisolated final class UITestStubURLProtocol: URLProtocol {

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let statusCode: Int
        let body: Data
        switch UITestScenario.current ?? .success {
        case .success:
            (statusCode, body) = (200, Self.successFixture)
        case .empty:
            (statusCode, body) = (200, Data("[]".utf8))
        case .error:
            (statusCode, body) = (500, Data())
        }

        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    /// Two fixture repositories. The second omits its description and
    /// language so UI tests can exercise the fallback rendering.
    private static let successFixture = Data("""
    [
        {
            "id": 1,
            "name": "swift-algorithms",
            "full_name": "uitest/swift-algorithms",
            "description": "Commonly used sequence and collection algorithms.",
            "stargazers_count": 6200,
            "forks_count": 480,
            "language": "Swift",
            "html_url": "https://github.com/uitest/swift-algorithms",
            "updated_at": "2026-07-01T12:00:00Z"
        },
        {
            "id": 2,
            "name": "mystery-repo",
            "full_name": "uitest/mystery-repo",
            "description": null,
            "stargazers_count": 3,
            "forks_count": 0,
            "language": null,
            "html_url": "https://github.com/uitest/mystery-repo",
            "updated_at": "2026-06-15T08:30:00Z"
        }
    ]
    """.utf8)
}
#endif
