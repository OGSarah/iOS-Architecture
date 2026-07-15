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

    /// Formats a raw count into a compact, display-friendly string.
    ///
    /// Values below one thousand are returned unchanged, thousands are
    /// abbreviated with a `k` suffix, and millions with an `M` suffix:
    /// `42` becomes `"42"`, `1200` becomes `"1.2k"`, and `2_500_000`
    /// becomes `"2.5M"`.
    ///
    /// - Parameter count: The value to format, such as a star or fork count.
    /// - Returns: A compact string representation of `count`.
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

    /// Formats a date as an abbreviated relative string, such as `"2 wk. ago"`.
    ///
    /// - Parameters:
    ///   - date: The date to describe.
    ///   - now: The reference date to measure against. Defaults to the
    ///     current date; tests inject a fixed value for determinism.
    ///   - locale: The locale used to produce the string. Defaults to the
    ///     user's current locale; tests inject a fixed locale so the
    ///     expected output does not depend on the test machine's settings.
    /// - Returns: A localized, abbreviated relative-time string.
    static func relativeUpdatedAt(_ date: Date, now: Date = Date(), locale: Locale = .autoupdatingCurrent) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = locale
        return formatter.localizedString(for: date, relativeTo: now)
    }
}
