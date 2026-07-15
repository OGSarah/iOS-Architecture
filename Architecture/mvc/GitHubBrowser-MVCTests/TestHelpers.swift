//
//  TestHelpers.swift
//  GitHubBrowser-MVCTests
//
//  Created by Sarah Clark on 7/15/26.
//

import Foundation
import UIKit
@testable import GitHubBrowser_MVC

extension Repository {

    /// Creates a fixture repository so each test only spells out the
    /// fields it actually cares about.
    static func fixture(
        id: Int = 1,
        name: String = "example-repo",
        fullName: String = "octocat/example-repo",
        description: String? = "An example repository",
        stargazersCount: Int = 42,
        forksCount: Int = 7,
        language: String? = "Swift",
        htmlURL: URL = URL(string: "https://github.com/octocat/example-repo")!,
        updatedAt: Date = Date(timeIntervalSince1970: 1_750_000_000)
    ) -> Repository {
        Repository(
            id: id,
            name: name,
            fullName: fullName,
            description: description,
            stargazersCount: stargazersCount,
            forksCount: forksCount,
            language: language,
            htmlURL: htmlURL,
            updatedAt: updatedAt
        )
    }
}

extension UIView {

    /// Recursively finds the first subview (or the receiver) with the
    /// given accessibility identifier, so tests can reach the app's
    /// private labels without widening their access control.
    func firstSubview(withAccessibilityIdentifier identifier: String) -> UIView? {
        if accessibilityIdentifier == identifier { return self }
        for subview in subviews {
            if let match = subview.firstSubview(withAccessibilityIdentifier: identifier) {
                return match
            }
        }
        return nil
    }
}

/// Polls until `condition` is true or the timeout passes, yielding so
/// main-actor UIKit work queued behind the test (diffable data source
/// applies, alert presentation) gets a chance to complete.
@MainActor
func waitUntil(timeout: TimeInterval = 2, _ condition: () -> Bool) async {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() && Date() < deadline {
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(20))
    }
}

/// A thread-safe box for a request captured on URLSession's background
/// loader threads and read back on the test's thread.
final class CapturedRequestBox: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: URLRequest?

    var value: URLRequest? {
        lock.withLock { _value }
    }

    func store(_ request: URLRequest) {
        lock.withLock { _value = request }
    }
}
