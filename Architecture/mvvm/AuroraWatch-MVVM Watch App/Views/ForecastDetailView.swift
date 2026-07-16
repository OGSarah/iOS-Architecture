//
//  ForecastDetailView.swift
//  AuroraWatch-MVVM Watch App
//
//  Created by Sarah Clark on 7/16/26.
//

import SwiftUI

/// The detail screen for a single forecast window.
///
/// Constructed with a ``ForecastWindow`` from the list. The view model
/// resolves it into finished strings; this view only lays them out.
struct ForecastDetailView: View {

    /// The screen's view model. No initial value at the declaration, per
    /// the SDK 27 `@State` macro rules, assigned in the initializer.
    @State private var viewModel: ForecastDetailViewModel

    /// Creates the detail screen for one window.
    ///
    /// - Parameter window: The window chosen in the list.
    init(window: ForecastWindow) {
        viewModel = ForecastDetailViewModel(window: window)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.kpText)
                    .font(.title2.weight(.bold))
                    .accessibilityIdentifier(AccessibilityID.detailKp)

                StormLevelBadge(text: viewModel.badgeText, colorRole: viewModel.colorRole)

                Divider()

                LabeledContent("Starts", value: viewModel.timeText)
                    .font(.footnote)

                LabeledContent("Source", value: viewModel.observationText)
                    .font(.footnote)
                    .accessibilityIdentifier(AccessibilityID.detailObservation)

                Divider()

                Text(viewModel.visibilityText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier(AccessibilityID.detailVisibility)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
        }
        .navigationTitle(viewModel.stormText)
        .accessibilityIdentifier(AccessibilityID.detailView)
    }
}

#Preview("G3 window") {
    NavigationStack {
        ForecastDetailView(
            window: ForecastWindow(date: .now, kp: 7.33, observation: .predicted)
        )
    }
}
