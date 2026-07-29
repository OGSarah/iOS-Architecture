//
//  ModuleFactory.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// The seam `AppRouter` uses to obtain a module's view controller without importing every module.
///
/// Each method assembles one module through its Builder and returns the plain `UIViewController` the
/// Builder produces. Keeping this behind a protocol lets `AppRouter` be tested with a stub that
/// returns lightweight controllers, so the column resolution can be asserted on its own.
@MainActor
protocol ModuleFactory: AnyObject {
    /// Builds the homes and zones sidebar for the primary column.
    func makeHomeList() -> UIViewController

    /// Builds the rooms and accessories list for the supplementary column.
    /// - Parameter homeID: The home whose rooms should be shown.
    func makeRoomList(homeID: HomeSnapshot.ID) -> UIViewController

    /// Builds the accessory detail and services for the secondary column.
    /// - Parameter accessoryID: The accessory to show.
    func makeAccessoryDetail(accessoryID: AccessorySnapshot.ID) -> UIViewController

    /// Builds the automation builder modal for a draft.
    /// - Parameter draftID: The draft being edited.
    func makeAutomationBuilder(draftID: AutomationDraft.ID) -> UIViewController

    /// Builds the accessory setup and commissioning modal.
    func makeSetup() -> UIViewController
}
