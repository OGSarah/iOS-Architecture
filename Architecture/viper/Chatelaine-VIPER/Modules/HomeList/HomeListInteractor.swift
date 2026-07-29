//
//  HomeListInteractor.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// Loads the home and reports it, along with authorization, so the sidebar can show an empty state.
final class HomeListInteractor: HomeListInteractorInput, HomeStoreObserver {

    weak var output: HomeListInteractorOutput?

    private let homeStore: HomeStoreProviding

    init(homeStore: HomeStoreProviding) {
        self.homeStore = homeStore
    }

    func loadInitial() {
        Task { [weak self] in
            guard let self else { return }
            let home = await homeStore.loadPrimaryHome()
            output?.didUpdate(home: home, authorization: homeStore.authorizationStatus)
        }
    }

    func startObserving() {
        homeStore.addObserver(self)
    }

    func stopObserving() {
        homeStore.removeObserver(self)
    }

    func homeStoreDidUpdate(_ home: HomeSnapshot) {
        output?.didUpdate(home: home, authorization: homeStore.authorizationStatus)
    }

    func homeStoreDidChangeAuthorization(_ status: HomeAuthorizationStatus) {
        Task { [weak self] in
            guard let self else { return }
            let home = await homeStore.loadPrimaryHome()
            output?.didUpdate(home: home, authorization: status)
        }
    }
}
