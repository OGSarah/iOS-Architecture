//
//  AccessoryDetailPresenterTests.swift
//  Chatelaine-VIPERTests
//
//  Created by Sarah Clark on 7/29/26.
//

import Testing
@testable import Chatelaine_VIPER

/// Records what the Presenter told the View to render. It can only be handed a view model, which is
/// exactly the boundary being asserted: the View never sees an entity.
@MainActor
final class SpyViewInput: AccessoryDetailViewInput {
    private(set) var viewModels: [AccessoryDetailViewModel] = []
    func display(_ viewModel: AccessoryDetailViewModel) { viewModels.append(viewModel) }
}

@MainActor
struct AccessoryDetailPresenterTests {

    private func unreachableBridgedAccessory() -> AccessorySnapshot {
        AccessorySnapshot(
            id: "accessory.light",
            name: "Bedroom Overhead Light",
            setupID: "12663208",
            roomID: "room.bedroom",
            reachability: .unreachableViaBridge(bridgeID: "bridge.1"),
            isBridge: false,
            services: [TestHouseholds.lightService()]
        )
    }

    @Test("The presenter renders the accessory as a view model of already formatted strings")
    func rendersFormattedViewModel() {
        let view = SpyViewInput()
        let presenter = AccessoryDetailPresenter(
            interactor: NoopAccessoryDetailInteractor(),
            router: NoopAccessoryDetailRouter()
        )
        presenter.view = view

        presenter.didUpdate(accessory: unreachableBridgedAccessory())

        #expect(view.viewModels.count == 1)
        let model = view.viewModels[0]
        #expect(model.title == "Bedroom Overhead Light")
        #expect(model.statusText == "Unreachable, bridge offline")
        #expect(model.services.map(\.name) == ["Overhead Light"])
        #expect(model.services.first?.detail == "2 controls")
    }

    @Test("A reachable accessory has no status note")
    func reachableHasNoStatus() {
        let model = AccessoryDetailPresenter.makeViewModel(from: TestHouseholds.home().accessories[0])
        #expect(model.statusText == nil)
    }
}

// MARK: - Test doubles

@MainActor
private final class NoopAccessoryDetailInteractor: AccessoryDetailInteractorInput {
    func loadInitial() {}
    func startObserving() {}
    func stopObserving() {}
}

@MainActor
private final class NoopAccessoryDetailRouter: AccessoryDetailRouterInput {
    func routeToService(_ service: ServiceSnapshot) {}
}
