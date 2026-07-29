//
//  ChatelaineModuleFactory.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// The production `ModuleFactory`, assembling each module through its Builder.
///
/// The Builders and their modules arrive in a later milestone. Until then each method returns a
/// styled placeholder so the three column layout is real and navigable, and so `AppRouter` can be
/// exercised end to end. Replacing a placeholder with its Builder call is a one line change.
final class ChatelaineModuleFactory: ModuleFactory {

    /// The router modules call back into for navigation, set after construction to break the cycle.
    weak var router: AppRouter?

    private let homeStore: HomeStore

    init(homeStore: HomeStore) {
        self.homeStore = homeStore
    }

    func makeHomeList() -> UIViewController {
        PlaceholderViewController(title: "Homes")
    }

    func makeRoomList(homeID: HomeSnapshot.ID) -> UIViewController {
        PlaceholderViewController(title: "Rooms")
    }

    func makeAccessoryDetail(accessoryID: AccessorySnapshot.ID) -> UIViewController {
        PlaceholderViewController(title: "Accessory")
    }

    func makeAutomationBuilder(draftID: AutomationDraft.ID) -> UIViewController {
        UINavigationController(rootViewController: PlaceholderViewController(title: "Automation"))
    }

    func makeSetup() -> UIViewController {
        UINavigationController(rootViewController: PlaceholderViewController(title: "Set Up Accessory"))
    }
}

/// A temporary column placeholder shown until the real modules are built.
///
/// It uses the brand palette so the layout reads correctly in light and dark mode while the modules
/// are being filled in.
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
