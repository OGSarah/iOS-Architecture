//
//  AccessoryDetailPresenter.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// Converts an accessory snapshot into a view model and decides when to open a service.
///
/// It holds the current snapshot so a service selection can be resolved against the latest data. It
/// never hands the View an entity, only a `AccessoryDetailViewModel`.
final class AccessoryDetailPresenter {

    weak var view: AccessoryDetailViewInput?
    private let interactor: AccessoryDetailInteractorInput
    private let router: AccessoryDetailRouterInput

    private var accessory: AccessorySnapshot?

    init(interactor: AccessoryDetailInteractorInput, router: AccessoryDetailRouterInput) {
        self.interactor = interactor
        self.router = router
    }
}

// MARK: - AccessoryDetailViewOutput

extension AccessoryDetailPresenter: AccessoryDetailViewOutput {

    func viewDidLoad() {
        interactor.startObserving()
        interactor.loadInitial()
    }

    func viewWillDisappear() {
        interactor.stopObserving()
    }

    func didSelectService(serviceID: String) {
        guard let service = accessory?.services.first(where: { $0.id == serviceID }) else { return }
        router.routeToService(service)
    }
}

// MARK: - AccessoryDetailInteractorOutput

extension AccessoryDetailPresenter: AccessoryDetailInteractorOutput {

    func didUpdate(accessory: AccessorySnapshot) {
        self.accessory = accessory
        view?.display(Self.makeViewModel(from: accessory))
    }
}

// MARK: - View model construction

extension AccessoryDetailPresenter {

    /// Builds the view model. Static and pure so the presenter test can assert it directly.
    static func makeViewModel(from accessory: AccessorySnapshot) -> AccessoryDetailViewModel {
        let services = accessory.services.map { service in
            let count = service.characteristics.count
            let detail = count == 1 ? "1 control" : "\(count) controls"
            return AccessoryDetailViewModel.ServiceRow(
                id: service.id,
                name: service.name,
                detail: detail,
                accessibilityLabel: "\(service.name), \(detail)"
            )
        }
        return AccessoryDetailViewModel(
            title: accessory.name,
            statusText: statusText(for: accessory.reachability),
            services: services
        )
    }

    /// Turns reachability into a short human note, collapsing a bridge outage into one line.
    static func statusText(for reachability: Reachability) -> String? {
        switch reachability {
        case .reachable: nil
        case .unreachable: "Unreachable"
        case .unreachableViaBridge: "Unreachable, bridge offline"
        }
    }
}
