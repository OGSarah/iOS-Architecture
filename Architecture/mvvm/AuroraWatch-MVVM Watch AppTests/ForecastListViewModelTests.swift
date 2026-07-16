//
//  ForecastListViewModelTests.swift
//  AuroraWatch-MVVM Watch AppTests
//
//  Created by Sarah Clark on 7/16/26.
//

import Foundation
import Testing
@testable import AuroraWatch_MVVM_Watch_App

/// Drives ``ForecastListViewModel`` through its real `load()` and
/// `refresh()` with a ``FakeForecastService``.
///
/// No window, no hosting controller, no rendering: the tests assert on
/// `viewModel.state`, which is the same property the view observes.
@MainActor
struct ForecastListViewModelTests {

    /// A view model with a pinned locale and clock.
    private func makeViewModel(service: FakeForecastService) -> ForecastListViewModel {
        ForecastListViewModel(
            service: service,
            locale: TestFixtures.enUS,
            now: { TestFixtures.referenceDate }
        )
    }

    @Test func loadPublishesFinishedRowModels() async {
        let windows = [
            TestFixtures.window(kp: 6.33, hoursFromReference: 3),
            TestFixtures.window(kp: 3.0, hoursFromReference: 6, observation: .observed),
        ]
        let service = FakeForecastService(result: .success(windows))
        let viewModel = makeViewModel(service: service)

        await viewModel.load()

        guard case .loaded(let rows) = viewModel.state else {
            Issue.record("Expected .loaded, got \(viewModel.state)")
            return
        }
        #expect(rows.count == 2)
        #expect(rows[0].kpText == "Kp 6.33")
        #expect(rows[0].timeText == "in 3 hours")
        #expect(rows[0].badgeText == "G2")
        #expect(rows[0].colorRole == .moderate)
        #expect(rows[0].accessibilityIdentifier == "forecast.row.0")
        #expect(rows[1].badgeText == "Quiet")
        #expect(rows[1].accessibilityIdentifier == "forecast.row.1")
    }

    @Test func loadSurfacesOnlyCurrentAndUpcomingWindows() async {
        let windows = [
            TestFixtures.window(kp: 3.0, hoursFromReference: -6, observation: .observed),
            TestFixtures.window(kp: 4.0, hoursFromReference: -1, observation: .observed),
            TestFixtures.window(kp: 5.33, hoursFromReference: 3),
        ]
        let service = FakeForecastService(result: .success(windows))
        let viewModel = makeViewModel(service: service)

        await viewModel.load()

        guard case .loaded(let rows) = viewModel.state else {
            Issue.record("Expected .loaded, got \(viewModel.state)")
            return
        }
        #expect(rows.count == 2)
        #expect(rows[0].timeText == "Now")
        #expect(rows[1].timeText == "in 3 hours")
    }

    @Test func feedWithOnlyExpiredWindowsBecomesEmptyState() async {
        let service = FakeForecastService(result: .success([
            TestFixtures.window(kp: 3.0, hoursFromReference: -12, observation: .observed),
        ]))
        let viewModel = makeViewModel(service: service)

        await viewModel.load()

        #expect(viewModel.state == .empty)
    }

    @Test func emptyFeedBecomesEmptyState() async {
        let service = FakeForecastService(result: .success([]))
        let viewModel = makeViewModel(service: service)

        await viewModel.load()

        #expect(viewModel.state == .empty)
    }

    @Test func failurePublishesTheErrorMessage() async {
        let service = FakeForecastService(result: .failure(.server(statusCode: 503)))
        let viewModel = makeViewModel(service: service)

        await viewModel.load()

        #expect(viewModel.state == .failed(message: ForecastError.server(statusCode: 503).message))
    }

    @Test func retryAfterFailureRecovers() async {
        let service = FakeForecastService(result: .failure(.network))
        let viewModel = makeViewModel(service: service)
        await viewModel.load()

        await service.set(result: .success([TestFixtures.window()]))
        await viewModel.load()

        guard case .loaded(let rows) = viewModel.state else {
            Issue.record("Expected .loaded after retry, got \(viewModel.state)")
            return
        }
        #expect(rows.count == 1)
    }

    @Test func refreshDoesNotFlashASpinnerOverExistingContent() async {
        let service = FakeForecastService(result: .success([TestFixtures.window()]))
        let viewModel = makeViewModel(service: service)
        await viewModel.load()

        await service.gateNextFetch()
        let refreshTask = Task { await viewModel.refresh() }
        while await service.callCount < 2 {
            await Task.yield()
        }

        guard case .loaded = viewModel.state else {
            Issue.record("refresh() flipped state to \(viewModel.state) mid-flight")
            await service.open()
            return
        }

        await service.open()
        await refreshTask.value
        guard case .loaded = viewModel.state else {
            Issue.record("Expected .loaded after refresh, got \(viewModel.state)")
            return
        }
    }

    @Test func secondLoadWhileInFlightDoesNotDoubleFetch() async {
        let service = FakeForecastService(result: .success([TestFixtures.window()]))
        await service.gateNextFetch()
        let viewModel = makeViewModel(service: service)

        let firstLoad = Task { await viewModel.load() }
        while await service.callCount < 1 {
            await Task.yield()
        }

        await viewModel.load()
        #expect(await service.callCount == 1)

        await service.open()
        await firstLoad.value
        #expect(await service.callCount == 1)
        guard case .loaded = viewModel.state else {
            Issue.record("Expected .loaded, got \(viewModel.state)")
            return
        }
    }
}
