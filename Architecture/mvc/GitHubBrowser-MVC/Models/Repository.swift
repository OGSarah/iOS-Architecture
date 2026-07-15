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
    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let stargazersCount: Int
    let forksCount: Int
    let language: String?
    let htmlURL: URL
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
enum RepositoryError: Error, Equatable {
    case invalidURL
    case requestFailed(statusCode: Int)
    case decodingFailed
    case transportError

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
    /// This lives on the model itself, which is the traditional Cocoa MVC
    /// approach: the model layer is responsible for its own data access.
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
