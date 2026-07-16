//
//  ForecastDetailViewModelTests.swift
//  AuroraWatch-MVVM Watch AppTests
//
//  Created by Sarah Clark on 7/16/26.
//

import Foundation
import Testing
@testable import AuroraWatch_MVVM_Watch_App

/// Hands ``ForecastDetailViewModel`` fixture windows and asserts its
/// finished display strings directly.
@MainActor
struct ForecastDetailViewModelTests {

    /// A view model with a pinned locale and clock.
    private func makeViewModel(window: ForecastWindow) -> ForecastDetailViewModel {
        ForecastDetailViewModel(
            window: window,
            locale: TestFixtures.enUS,
            now: { TestFixtures.referenceDate }
        )
    }

    @Test func resolvesAStormWindowIntoDisplayStrings() {
        let window = TestFixtures.window(kp: 7.33, hoursFromReference: 3, observation: .predicted)

        let viewModel = makeViewModel(window: window)

        #expect(viewModel.kpText == "Kp 7.33")
        #expect(viewModel.observationText == "Predicted")
        #expect(viewModel.stormText == "G3 Strong storm")
        #expect(viewModel.badgeText == "G3")
        #expect(viewModel.colorRole == .strong)
        #expect(viewModel.timeText == "in 3 hours")
        #expect(viewModel.visibilityText == StormLevel.g3.visibilityDescription)
    }

    @Test func resolvesAQuietObservedWindow() {
        let window = TestFixtures.window(kp: 2.0, hoursFromReference: -1, observation: .observed)

        let viewModel = makeViewModel(window: window)

        #expect(viewModel.kpText == "Kp 2")
        #expect(viewModel.observationText == "Observed")
        #expect(viewModel.stormText == "Quiet")
        #expect(viewModel.badgeText == "Quiet")
        #expect(viewModel.colorRole == .calm)
        #expect(viewModel.timeText == "Now")
    }

    @Test func resolvesAnEstimatedWindow() {
        let window = TestFixtures.window(kp: 5.0, hoursFromReference: 6, observation: .estimated)

        let viewModel = makeViewModel(window: window)

        #expect(viewModel.observationText == "Estimated")
        #expect(viewModel.stormText == "G1 Minor storm")
        #expect(viewModel.badgeText == "G1")
    }
}
