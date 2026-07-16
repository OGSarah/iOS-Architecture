//
//  ForecastRow.swift
//  AuroraWatch-MVVM Watch App
//
//  Created by Sarah Clark on 7/16/26.
//

import SwiftUI

/// One forecast window in the list.
///
/// The row has no view model. It is handed a ``Model`` containing finished
/// strings and a color role, and its only job is layout.
struct ForecastRow: View {

    /// Everything the row needs, fully resolved by the list view model.
    struct Model: Identifiable, Equatable {

        /// The underlying window, carried for navigation.
        let window: ForecastWindow

        /// The relative start time, such as "in 3 hours".
        let timeText: String

        /// The Kp value, such as "Kp 6.33".
        let kpText: String

        /// The badge text, such as "G2" or "Quiet".
        let badgeText: String

        /// The severity bucket for the badge tint.
        let colorRole: StormLevel.ColorRole

        /// The identifier the UI tests look the row up by.
        let accessibilityIdentifier: String

        var id: Date { window.id }
    }

    /// The resolved display model for this row.
    let model: Model

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.timeText)
                    .font(.headline)
                Text(model.kpText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            StormLevelBadge(text: model.badgeText, colorRole: model.colorRole)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(model.accessibilityIdentifier)
    }
}

#Preview("Row") {
    List {
        ForecastRow(model: ForecastRow.Model(
            window: ForecastWindow(date: .now, kp: 6.67, observation: .predicted),
            timeText: "in 3 hours",
            kpText: "Kp 6.67",
            badgeText: "G2",
            colorRole: .moderate,
            accessibilityIdentifier: "forecast.row.0"
        ))
    }
}
