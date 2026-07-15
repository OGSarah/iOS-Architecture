//
//  Repository.swift
//  GitHubBrowser-MVC
//
//  Created by Sarah Clark on 7/15/26.
//

import Foundation

/// The Model in MVC. It owns its own data and knows how to fetch and
/// decode itself. It has no knowledge of UIKit or of the view
/// controller that will display it.
nonisolated struct Repository: Decodable, Hashable {

    /// The repository's unique GitHub identifier.
    let id: Int

    /// The repository name, such as `"swift-algorithms"`.
    let name: String

    /// The owner-qualified name, such as `"apple/swift-algorithms"`.
    let fullName: String

    /// The owner-provided summary, or `nil` when none was written.
    let description: String?

    /// The number of users who have starred the repository.
    let stargazersCount: Int

    /// The number of times the repository has been forked.
    let forksCount: Int

    /// The primary programming language, or `nil` when GitHub has not
    /// detected one.
    let language: String?

    /// The repository's page on github.com.
    let htmlURL: URL

    /// When the repository was last updated, decoded from ISO 8601.
    let updatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case fullName = "full_name"
        case description
        case stargazersCount = "stargazers_count"
        case forksCount = "forks_count"
        case language
        case htmlURL = "html_url"
        case updatedAt = "updated_at"
    }
}

/// Errors the model layer can throw while fetching repositories. Each
/// case carries user-facing copy so the controller can present the
/// failure directly in an alert without translating it first.
enum RepositoryError: Error, Equatable {

    /// The GitHub API URL could not be built from the username.
    case invalidURL

    /// GitHub responded, but with a non-2xx HTTP status code.
    case requestFailed(statusCode: Int)

    /// The response body could not be decoded into `[Repository]`.
    case decodingFailed

    /// The request never produced a response, typically because the
    /// network is unreachable.
    case transportError

    /// A short, user-facing description suitable for an alert.
    var message: String {
        switch self {
        case .invalidURL:
            return "GitHub username produced an invalid request."
        case .requestFailed(let statusCode):
            return "GitHub returned an error (status: \(statusCode))."
        case .decodingFailed:
            return "The response from GitHub could not be decoded."
        case .transportError:
            return "Check your connection and try again."
        }
    }
}

extension Repository {

    /// Fetches the public repositories for a GitHub user, newest updated first.
    ///
    /// This lives on the model itself, which is the traditional Cocoa MVC
    /// approach: the model layer is responsible for its own data access.
    ///
    /// - Parameters:
    ///   - username: The GitHub account whose public repositories to fetch.
    ///   - session: The session to fetch with. Defaults to `.shared`;
    ///     tests pass a session backed by a stubbed `URLProtocol` instead.
    /// - Returns: The user's public repositories, most recently updated first.
    /// - Throws: A ``RepositoryError`` describing which stage of the
    ///   request failed.
    static func fetchAll(forUsername username: String, session: URLSession = .shared) async throws -> [Repository] {
        guard let url = URL(string: "https://api.github.com/users/\(username)/repos?sort=updated") else {
            throw RepositoryError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw RepositoryError.transportError
        }

        guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw RepositoryError.requestFailed(statusCode: statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode([Repository].self, from: data)
        } catch {
            throw RepositoryError.decodingFailed
        }

    }
}
