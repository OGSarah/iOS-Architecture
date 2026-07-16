//
//  AccessibilityIdentifiers.swift
//  AuroraWatch-MVVM Watch App
//
//  Created by Sarah Clark on 7/16/26.
//

import Foundation

/// Accessibility identifier strings attached to the views.
///
/// The UI test target keeps a mirrored copy of these constants, since the
/// two targets do not share source files. If a value changes here, change
/// it there as well; the UI tests will fail loudly if the two drift.
nonisolated enum AccessibilityID {

    /// The forecast list.
    static let forecastList = "forecast.list"

    /// A row in the forecast list. Suffixed with the row's index,
    /// such as `forecast.row.0`.
    static func forecastRow(at index: Int) -> String { "forecast.row.\(index)" }

    /// The loading indicator shown before the first load completes.
    static let loadingView = "forecast.loading"

    /// The empty state shown when the feed has no windows.
    static let emptyView = "forecast.empty"

    /// The error state container.
    static let errorView = "forecast.error"

    /// The retry button inside the error state.
    static let retryButton = "forecast.error.retry"

    /// The detail screen container.
    static let detailView = "forecast.detail"

    /// The Kp value on the detail screen.
    static let detailKp = "forecast.detail.kp"

    /// The observed or predicted label on the detail screen.
    static let detailObservation = "forecast.detail.observation"

    /// The visibility line on the detail screen.
    static let detailVisibility = "forecast.detail.visibility"

    /// The storm level badge, on rows and the detail screen.
    static let stormBadge = "storm.badge"
}
