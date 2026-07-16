//
//  ForecastListViewModel.swift
//  AuroraWatch-MVVM Watch App
//
//  Created by Sarah Clark on 7/16/26.
//

import Foundation
import Observation

/// The lifecycle of a screen's data, as a single value.
///
/// One enum instead of the usual pile of `isLoading`, `error`, and `items`
/// booleans that can contradict each other. The view switches over this and
/// renders; there is no combination of properties that renders nonsense.
enum ViewState<Value> {

    /// The first fetch is in flight and there is nothing to show yet.
    case loading

    /// The fetch succeeded and produced content.
    case loaded(Value)

    /// The fetch succeeded but the feed was empty.
    case empty

    /// The fetch failed. `message` is ready for display.
    case failed(message: String)
}

extension ViewState: Equatable where Value: Equatable {}

/// Owns the forecast list screen's state.
///
/// The view model holds the injected ``ForecastService``, exposes
/// ``load()`` and ``refresh()``, and publishes a single ``state`` the view
/// renders directly. It never references a view: it mutates its own
/// properties and the Observation system re-invalidates whoever is reading
/// them.
@MainActor
@Observable
final class ForecastListViewModel {

    /// What the list screen should currently show.
    private(set) var state: ViewState<[ForecastRow.Model]> = .loading

    /// The source of forecast windows. A protocol so tests inject a fake.
    private let service: any ForecastService

    /// The locale used for display strings. Injected for deterministic tests.
    private let locale: Locale

    /// The clock used for relative times. Injected for deterministic tests.
    private let now: () -> Date

    /// Guards against overlapping fetches: a second `load()` or `refresh()`
    /// while one is in flight is a no-op rather than a duplicate request.
    private var isFetching = false

    /// Creates the view model.
    ///
    /// - Parameters:
    ///   - service: The forecast source.
    ///   - locale: The locale for display strings. Defaults to `.current`.
    ///   - now: The clock used to phrase relative times. Defaults to `Date.init`.
    init(
        service: any ForecastService,
        locale: Locale = .current,
        now: @escaping () -> Date = { Date() }
    ) {
        self.service = service
        self.locale = locale
        self.now = now
    }

    /// Performs the initial fetch, showing the loading state first.
    ///
    /// Safe to call repeatedly: an in-flight fetch makes further calls
    /// no-ops, so a `.task` re-fire cannot double fetch.
    func load() async {
        guard !isFetching else { return }
        state = .loading
        await fetch()
    }

    /// Re-fetches without disturbing existing content.
    ///
    /// Unlike ``load()``, this never flips the state back to `.loading`,
    /// so a pull to refresh does not flash a spinner over rows the user
    /// is already looking at.
    func refresh() async {
        guard !isFetching else { return }
        await fetch()
    }

    /// How long one forecast window lasts. SWPC publishes in three hour steps.
    private static let windowLength: TimeInterval = 3 * 60 * 60

    /// Fetches windows and resolves them into the next ``state``.
    ///
    /// The live feed carries a week of observed history ahead of the
    /// forecast. Deciding what is worth surfacing is this view model's job:
    /// only windows still in progress or upcoming make it to the screen.
    private func fetch() async {
        isFetching = true
        defer { isFetching = false }

        do {
            let reference = now()
            let windows = try await service.windows()
                .filter { $0.date.addingTimeInterval(Self.windowLength) > reference }
            state = windows.isEmpty ? .empty : .loaded(rowModels(from: windows, reference: reference))
        } catch let error as ForecastError {
            state = .failed(message: error.message)
        } catch {
            state = .failed(message: ForecastError.network.message)
        }
    }

    /// Maps model values into finished row display models.
    ///
    /// Every string and color decision is made here so the row view has no
    /// branching or computation left to do.
    private func rowModels(from windows: [ForecastWindow], reference: Date) -> [ForecastRow.Model] {
        windows.enumerated().map { index, window in
            ForecastRow.Model(
                window: window,
                timeText: ForecastFormatting.relativeTime(from: window.date, reference: reference, locale: locale),
                kpText: ForecastFormatting.kpString(window.kp, locale: locale),
                badgeText: window.stormLevel.scaleLabel ?? window.stormLevel.title,
                colorRole: window.stormLevel.colorRole,
                accessibilityIdentifier: AccessibilityID.forecastRow(at: index)
            )
        }
    }
}
