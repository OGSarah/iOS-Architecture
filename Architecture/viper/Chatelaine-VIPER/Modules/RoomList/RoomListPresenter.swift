//
//  RoomListPresenter.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// Builds a section per room and routes an accessory selection to the detail column.
///
/// It collapses a downed bridge into one message. Every accessory that is unreachable because the
/// same bridge is offline gets the identical note, so the column reads as one condition rather than
/// a wall of separate warnings.
final class RoomListPresenter {

    weak var view: RoomListViewInput?
    private let interactor: RoomListInteractorInput
    private let router: RoomListRouterInput

    private var home: HomeSnapshot?

    init(interactor: RoomListInteractorInput, router: RoomListRouterInput) {
        self.interactor = interactor
        self.router = router
    }
}

// MARK: - RoomListViewOutput

extension RoomListPresenter: RoomListViewOutput {

    func viewDidLoad() {
        interactor.startObserving()
        interactor.loadInitial()
    }

    func viewWillDisappear() {
        interactor.stopObserving()
    }

    func didSelectAccessory(accessoryID: String) {
        router.routeToAccessory(accessoryID: accessoryID)
    }
}

// MARK: - RoomListInteractorOutput

extension RoomListPresenter: RoomListInteractorOutput {

    func didUpdate(home: HomeSnapshot?) {
        self.home = home
        guard let home else {
            view?.display(RoomListViewModel(title: "Rooms", sections: []))
            return
        }
        view?.display(Self.makeViewModel(from: home))
    }
}

// MARK: - View model construction

extension RoomListPresenter {

    static func makeViewModel(from home: HomeSnapshot) -> RoomListViewModel {
        let sections = home.rooms.map { room -> RoomListViewModel.Section in
            let accessories = home.accessories(in: room.id)
                .filter { !$0.isBridge }
                .map { accessory in
                    RoomListViewModel.Accessory(
                        id: accessory.id,
                        name: accessory.name,
                        statusText: statusText(for: accessory.reachability),
                        accessibilityLabel: accessibilityLabel(for: accessory)
                    )
                }
            return RoomListViewModel.Section(id: room.id, name: room.name, accessories: accessories)
        }
        return RoomListViewModel(title: home.name, sections: sections)
    }

    static func statusText(for reachability: Reachability) -> String? {
        switch reachability {
        case .reachable: nil
        case .unreachable: "Unreachable"
        case .unreachableViaBridge: "Bridge offline"
        }
    }

    static func accessibilityLabel(for accessory: AccessorySnapshot) -> String {
        if let status = statusText(for: accessory.reachability) {
            return "\(accessory.name), \(status)"
        }
        return accessory.name
    }
}
