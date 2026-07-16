//
//  ForecastListView.swift
//  AuroraWatch-MVVM Watch App
//
//  Created by Sarah Clark on 7/16/26.
//

import SwiftUI

/// The root screen: the next three days of forecast windows.
///
/// The view owns its view model's lifetime with `@State`, reads
/// `viewModel.state` in `body`, and renders whichever case it finds.
/// When the view model finishes a load and assigns a new state, the
/// Observation system re-invalidates this body on its own; nothing in the
/// view model points back at the view.
struct ForecastListView: View {

    /// The screen's view model. Declared with no initial value and assigned
    /// in the initializer, which is the required shape now that `@State` is
    /// a macro in SDK 27.
    @State private var viewModel: ForecastListViewModel

    /// Creates the list screen.
    ///
    /// - Parameter service: The forecast source handed down to the
    ///   view model. Injected so previews and UI tests can substitute stubs.
    init(service: any ForecastService) {
        viewModel = ForecastListViewModel(service: service)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Aurora")
                .navigationDestination(for: ForecastWindow.self) { window in
                    ForecastDetailView(window: window)
                }
        }
        .task {
            await viewModel.load()
        }
    }

    /// The state-dependent portion of the screen.
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
                .accessibilityIdentifier(AccessibilityID.loadingView)

        case .loaded(let rows):
            forecastList(rows)

        case .empty:
            ContentUnavailableView(
                "No Forecast",
                systemImage: "moon.stars",
                description: Text("SWPC has not published any forecast windows yet. Check back soon.")
            )
            .accessibilityIdentifier(AccessibilityID.emptyView)

        case .failed(let message):
            errorView(message: message)
        }
    }

    /// The loaded list. Digital Crown scrolling comes free with `List`,
    /// and pull to refresh re-fetches without flashing a spinner.
    private func forecastList(_ rows: [ForecastRow.Model]) -> some View {
        List(rows) { row in
            NavigationLink(value: row.window) {
                ForecastRow(model: row)
            }
        }
        .accessibilityIdentifier(AccessibilityID.forecastList)
        .refreshable {
            await viewModel.refresh()
        }
    }

    /// The inline error state with a retry action.
    private func errorView(message: String) -> some View {
        ContentUnavailableView {
            Label("Forecast Unavailable", systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Retry") {
                Task {
                    await viewModel.load()
                }
            }
            .accessibilityIdentifier(AccessibilityID.retryButton)
        }
        .accessibilityIdentifier(AccessibilityID.errorView)
    }
}

#Preview("Live service") {
    ForecastListView(service: LiveForecastService())
}
