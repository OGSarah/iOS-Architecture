//
//  AccessoryDetailInteractor.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// Resolves one accessory from the home store and keeps it current as the graph mutates.
///
/// It depends only on `HomeStoreProviding`, so a test can hand it a scripted household. It never
/// touches UIKit or HomeKit directly.
final class AccessoryDetailInteractor: AccessoryDetailInteractorInput, HomeStoreObserver {

    weak var output: AccessoryDetailInteractorOutput?

    private let accessoryID: String
    private let homeStore: HomeStoreProviding

    init(accessoryID: String, homeStore: HomeStoreProviding) {
        self.accessoryID = accessoryID
        self.homeStore = homeStore
    }

    func loadInitial() {
        Task { [weak self] in
            guard let self else { return }
            let home = await homeStore.loadPrimaryHome()
            report(from: home)
        }
    }

    func startObserving() {
        homeStore.addObserver(self)
    }

    func stopObserving() {
        homeStore.removeObserver(self)
    }

    // MARK: - HomeStoreObserver

    func homeStoreDidUpdate(_ home: HomeSnapshot) {
        report(from: home)
    }

    func homeStoreDidChangeAuthorization(_ status: HomeAuthorizationStatus) {}

    private func report(from home: HomeSnapshot?) {
        guard let accessory = home?.accessory(accessoryID) else { return }
        output?.didUpdate(accessory: accessory)
    }
}
