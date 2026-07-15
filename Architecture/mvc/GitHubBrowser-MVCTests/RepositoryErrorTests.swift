//
//  RepositoryErrorTests.swift
//  GitHubBrowser-MVCTests
//
//  Created by Sarah Clark on 7/15/26.
//

import Testing
@testable import GitHubBrowser_MVC

/// Pins the user-facing copy that the list controller's error alert
/// displays, so wording changes are deliberate rather than accidental.
struct RepositoryErrorTests {

    @Test(arguments: [
        (RepositoryError.invalidURL, "GitHub username produced an invalid request."),
        (RepositoryError.requestFailed(statusCode: 404), "GitHub returned an error (status: 404)."),
        (RepositoryError.decodingFailed, "The response from GitHub could not be decoded."),
        (RepositoryError.transportError, "Check your connection and try again."),
    ])
    @MainActor
    func `Each error case produces its user facing message`(error: RepositoryError, expected: String) {
        #expect(error.message == expected)
    }
}
