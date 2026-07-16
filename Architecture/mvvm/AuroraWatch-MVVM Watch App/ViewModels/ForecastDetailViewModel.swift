//
//  ForecastDetailViewModel.swift
//  AuroraWatch-MVVM Watch App
//
//  Created by Sarah Clark on 7/16/26.
//

import Foundation
import Observation

/// Owns the presentation of a single forecast window.
///
/// Constructed with a ``ForecastWindow`` from the list, it resolves the
/// value into finished display strings up front. The detail view reads
/// these properties and lays them out; there is no `if kp >= 5` anywhere
/// in a view body.
@MainActor
@Observable
final class ForecastDetailViewModel {

    /// The Kp value ready for display, such as "Kp 7.33".
    let kpText: String

    /// Whether the value was observed, estimated, or predicted,
    /// capitalized for display.
    let observationText: String

    /// The storm scale line, such as "G3 Strong storm" or "Quiet".
    let stormText: String

    /// The plain English aurora visibility line for this storm level.
    let visibilityText: String

    /// When the window starts, phrased relative to now,
    /// such as "in 3 hours" or "Now".
    let timeText: String

    /// The badge text, the scale label when storming or the severity
    /// name when quiet.
    let badgeText: String

    /// The semantic color role for the storm badge.
    let colorRole: StormLevel.ColorRole

    /// Creates the view model for one window.
    ///
    /// - Parameters:
    ///   - window: The window to present.
    ///   - locale: The locale for display strings. Defaults to `.current`.
    ///   - now: The clock used to phrase the window's relative time.
    ///     Defaults to `Date.init`; tests inject a fixed instant.
    init(
        window: ForecastWindow,
        locale: Locale = .current,
        now: () -> Date = { Date() }
    ) {
        let level = window.stormLevel
        kpText = ForecastFormatting.kpString(window.kp, locale: locale)
        observationText = window.observation.rawValue.capitalized(with: locale)
        stormText = ForecastFormatting.stormDescriptor(for: level)
        visibilityText = level.visibilityDescription
        timeText = ForecastFormatting.relativeTime(from: window.date, reference: now(), locale: locale)
        badgeText = level.scaleLabel ?? level.title
        colorRole = level.colorRole
    }
}
