//
//  ForecastFormatting.swift
//  AuroraWatch-MVVM Watch App
//
//  Created by Sarah Clark on 7/16/26.
//

import Foundation

/// Pure formatting helpers shared by the view models and the widget.
///
/// Every function takes its inputs explicitly, including the reference date
/// and locale, so the unit tests are deterministic. Nothing in here reads
/// `Date()` or global state.
nonisolated enum ForecastFormatting {

    /// Formats a Kp value for display, such as "Kp 6" or "Kp 4.33".
    ///
    /// Whole values drop the fraction, fractional values keep at most two
    /// digits, matching SWPC's published precision.
    ///
    /// - Parameters:
    ///   - kp: The planetary K-index value.
    ///   - locale: The locale for number formatting. Defaults to `.current`.
    /// - Returns: The display string.
    static func kpString(_ kp: Double, locale: Locale = .current) -> String {
        let number = kp.formatted(
            .number
                .precision(.fractionLength(0 ... 2))
                .locale(locale)
        )
        return "Kp \(number)"
    }

    /// Formats a storm level for display, such as "G3 Strong storm",
    /// or "Quiet" below storm threshold.
    ///
    /// - Parameter level: The storm level.
    /// - Returns: The display string.
    static func stormDescriptor(for level: StormLevel) -> String {
        if let scale = level.scaleLabel {
            return "\(scale) \(level.title)"
        }
        return level.title
    }

    /// Formats how far a window's start is from a reference instant,
    /// such as "in 3 hours" or "2 hours ago".
    ///
    /// - Parameters:
    ///   - date: The window's start.
    ///   - reference: The instant to measure from. Injected rather than
    ///     read from the clock so tests can pin it.
    ///   - locale: The locale for the phrasing. Defaults to `.current`.
    /// - Returns: The relative time string, or "Now" when the window
    ///   contains the reference instant.
    static func relativeTime(from date: Date, reference: Date, locale: Locale = .current) -> String {
        let windowLength: TimeInterval = 3 * 60 * 60
        if date <= reference && reference < date.addingTimeInterval(windowLength) {
            return String(localized: "Now", comment: "Shown when a forecast window is currently in progress")
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.locale = locale
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: reference)
    }
}
