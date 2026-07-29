//
//  RoomListInteractor.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// Loads the home whose rooms fill the supplementary column, and keeps it current.
final class RoomListInteractor: RoomListInteractorInput, HomeStoreObserver {

    weak var output: RoomListInteractorOutput?

    private let homeID: String
    private let homeStore: HomeStoreProviding

    init(homeID: String, homeStore: HomeStoreProviding) {
        self.homeID = homeID
        self.homeStore = homeStore
    }

    func loadInitial() {
        Task { [weak self] in
            guard let self else { return }
            output?.didUpdate(home: await homeStore.loadPrimaryHome())
        }
    }

    func startObserving() {
        homeStore.addObserver(self)
    }

    func stopObserving() {
        homeStore.removeObserver(self)
    }

    func homeStoreDidUpdate(_ home: HomeSnapshot) {
        output?.didUpdate(home: home)
    }

    func homeStoreDidChangeAuthorization(_ status: HomeAuthorizationStatus) {}
}
