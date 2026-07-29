//
//  HomeListPresenter.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// Builds the sidebar view model and routes a selection to the home's rooms.
final class HomeListPresenter {

    weak var view: HomeListViewInput?
    private let interactor: HomeListInteractorInput
    private let router: HomeListRouterInput

    private var home: HomeSnapshot?

    init(interactor: HomeListInteractorInput, router: HomeListRouterInput) {
        self.interactor = interactor
        self.router = router
    }
}

// MARK: - HomeListViewOutput

extension HomeListPresenter: HomeListViewOutput {

    func viewDidLoad() {
        interactor.startObserving()
        interactor.loadInitial()
    }

    func viewWillDisappear() {
        interactor.stopObserving()
    }

    func didSelectRow(id: String) {
        // Selecting the home or any of its zones opens that home's rooms in the next column.
        guard let home else { return }
        router.routeToHome(homeID: home.id)
    }

    func didTapAutomations() {
        router.routeToAutomations()
    }

    func didTapSettings() {
        router.routeToSettings()
    }
}

// MARK: - HomeListInteractorOutput

extension HomeListPresenter: HomeListInteractorOutput {

    func didUpdate(home: HomeSnapshot?, authorization: HomeAuthorizationStatus) {
        self.home = home
        view?.display(Self.makeViewModel(home: home, authorization: authorization))
    }
}

// MARK: - View model construction

extension HomeListPresenter {

    static func makeViewModel(home: HomeSnapshot?, authorization: HomeAuthorizationStatus) -> HomeListViewModel {
        guard let home else {
            return HomeListViewModel(title: "Homes", emptyMessage: emptyMessage(for: authorization), rows: [])
        }

        let roomCount = home.rooms.count
        let homeRow = HomeListViewModel.Row(
            id: home.id,
            name: home.name,
            subtitle: roomCount == 1 ? "1 room" : "\(roomCount) rooms",
            kind: .home,
            accessibilityLabel: "\(home.name), \(roomCount) rooms"
        )

        let zoneRows = home.zones.map { zone in
            HomeListViewModel.Row(
                id: zone.id,
                name: zone.name,
                subtitle: zone.roomIDs.count == 1 ? "1 room" : "\(zone.roomIDs.count) rooms",
                kind: .zone,
                accessibilityLabel: "Zone, \(zone.name)"
            )
        }

        return HomeListViewModel(title: "Homes", emptyMessage: nil, rows: [homeRow] + zoneRows)
    }

    static func emptyMessage(for authorization: HomeAuthorizationStatus) -> String {
        switch authorization {
        case .notDetermined: "Grant access to your home to get started."
        case .restricted: "Home access is turned off. You can enable it in Settings."
        case .authorizedNoHomes, .authorized: "No homes yet. Add one in the Home app."
        }
    }
}
