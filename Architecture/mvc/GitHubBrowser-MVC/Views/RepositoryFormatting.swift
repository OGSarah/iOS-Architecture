//
//  RepositoryFormatting.swift
//  GitHubBrowser-MVC
//
//  Created by Sarah Clark on 7/15/26.
//

import Foundation

/// Small formatting helpers used only by the view layer. Keeping these
/// out of the view controller avoids cluttering it with string
/// formatting that has nothing to do with controlling the view.
enum RepositoryFormatting {

    static func compactCount(_ count: Int) -> String {
        switch count {
        case 0..<1000:
            return "\(count)"
        case 1000..<1_000_000:
            return String(format: "%.1fk", Double(count) / 1000)
        default:
            return String(format: "%.1fM", Double(count) / 1_000_000)
        }
    }

    static func relativeUpdatedAt(_ date: Date, now: Date = Date()) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: now)
    }
}
