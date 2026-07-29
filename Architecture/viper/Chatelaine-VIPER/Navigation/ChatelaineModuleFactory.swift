//
//  ChatelaineModuleFactory.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// The production `ModuleFactory`, assembling each module through its Builder.
///
/// The automation builder and setup modules arrive in later milestones and are still placeholders.
/// The three columns of the main experience are wired to their real Builders.
final class ChatelaineModuleFactory: ModuleFactory {

    /// The router modules call back into for navigation, set after construction to break the cycle.
    weak var router: AppRouter?

    private let homeStore: HomeServicing

    init(homeStore: HomeServicing) {
        self.homeStore = homeStore
    }

    func makeHomeList() -> UIViewController {
        HomeListBuilder.build(homeStore: homeStore, appRouter: router)
    }

    func makeRoomList(homeID: HomeSnapshot.ID) -> UIViewController {
        RoomListBuilder.build(homeID: homeID, homeStore: homeStore, appRouter: router)
    }

    func makeAccessoryDetail(accessoryID: AccessorySnapshot.ID) -> UIViewController {
        AccessoryDetailBuilder.build(accessoryID: accessoryID, homeStore: homeStore, appRouter: router)
    }

    func makeAutomationBuilder(draftID: AutomationDraft.ID) -> UIViewController {
        // The automations modal opens on the list, and the list pushes the builder to create one.
        AutomationListBuilder.build(homeStore: homeStore, appRouter: router)
    }

    func makeSetup() -> UIViewController {
        AccessorySetupBuilder.build(commissioner: MatterCommissioner(), appRouter: router)
    }

    func makeSettings() -> UIViewController {
        SettingsBuilder.build(appRouter: router)
    }

    func makeOnboarding(onFinish: @escaping () -> Void) -> UIViewController {
        OnboardingBuilder.build(onFinish: onFinish)
    }
}

/// A temporary placeholder for the modules not yet built.
final class PlaceholderViewController: UIViewController {

    private let displayTitle: String

    init(title: String) {
        self.displayTitle = title
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used, this controller is built in code")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = displayTitle
        view.backgroundColor = UIColor(named: "BrandNavy")

        let label = UILabel()
        label.text = displayTitle
        label.textColor = UIColor(named: "AccentColor")
        label.font = .preferredFont(forTextStyle: .largeTitle)
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
