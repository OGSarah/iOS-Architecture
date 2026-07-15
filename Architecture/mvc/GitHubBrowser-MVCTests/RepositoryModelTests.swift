//
//  RepositoryModelTests.swift
//  GitHubBrowser-MVCTests
//
//  Created by Sarah Clark on 7/15/26.
//

import Foundation
import Testing
@testable import GitHubBrowser_MVC

// Serialized because every test shares StubURLProtocol.requestHandler,
// which is global state; a class is used so deinit can clear it.
@Suite(.serialized)
final class RepositoryModelTests {

    deinit {
        StubURLProtocol.requestHandler = nil
    }

    @Test func `Fetch all decodes a valid response`() async throws {
        let json = """
        [
            {
                "id": 1,
                "name": "example-repo",
                "full_name": "octocat/example-repo",
                "description": "An example repository",
                "stargazers_count": 42,
                "forks_count": 7,
                "language": "Swift",
                "html_url": "https://github.com/octocat/example-repo",
                "updated_at": "2026-06-01T12:00:00Z"
            }
        ]
        """.data(using: .utf8)!

        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        let repositories = try await Repository.fetchAll(forUsername: "octocat", session: StubURLProtocol.makeSession())

        #expect(repositories.count == 1)
        #expect(repositories.first?.name == "example-repo")
        #expect(repositories.first?.stargazersCount == 42)
    }

    @Test func `Fetch all decodes null description and language as nil`() async throws {
        let json = """
        [
            {
                "id": 2,
                "name": "bare-repo",
                "full_name": "octocat/bare-repo",
                "description": null,
                "stargazers_count": 0,
                "forks_count": 0,
                "language": null,
                "html_url": "https://github.com/octocat/bare-repo",
                "updated_at": "2026-06-01T12:00:00Z"
            }
        ]
        """.data(using: .utf8)!

        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        let repositories = try await Repository.fetchAll(forUsername: "octocat", session: StubURLProtocol.makeSession())

        let repository = try #require(repositories.first)
        #expect(repository.description == nil)
        #expect(repository.language == nil)
    }

    @Test func `Fetch all returns an empty list for an empty response`() async throws {
        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data("[]".utf8))
        }

        let repositories = try await Repository.fetchAll(forUsername: "octocat", session: StubURLProtocol.makeSession())

        #expect(repositories.isEmpty)
    }

    @Test func `Fetch all requests the expected URL and Accept header`() async throws {
        let captured = CapturedRequestBox()
        StubURLProtocol.requestHandler = { request in
            captured.store(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data("[]".utf8))
        }

        _ = try await Repository.fetchAll(forUsername: "octocat", session: StubURLProtocol.makeSession())

        let request = try #require(captured.value)
        #expect(request.url?.absoluteString == "https://api.github.com/users/octocat/repos?sort=updated")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/vnd.github+json")
    }

    @Test func `Fetch all throws on a server error`() async {
        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        await #expect(throws: RepositoryError.requestFailed(statusCode: 500)) {
            _ = try await Repository.fetchAll(forUsername: "octocat", session: StubURLProtocol.makeSession())
        }
    }

    @Test func `Fetch all throws on malformed JSON`() async {
        let malformedJSON = "{ this is not valid json".data(using: .utf8)!

        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, malformedJSON)
        }

        await #expect(throws: RepositoryError.decodingFailed) {
            _ = try await Repository.fetchAll(forUsername: "octocat", session: StubURLProtocol.makeSession())
        }
    }

    @Test func `Fetch all maps transport failures to transportError`() async {
        StubURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        await #expect(throws: RepositoryError.transportError) {
            _ = try await Repository.fetchAll(forUsername: "octocat", session: StubURLProtocol.makeSession())
        }
    }
}
