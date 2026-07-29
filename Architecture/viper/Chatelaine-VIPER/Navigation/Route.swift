//
//  Route.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// Everything this app can be showing, expressed as data rather than behavior.
///
/// A `Route` names a destination. It says nothing about how that destination reaches the screen,
/// which is width dependent and belongs to `AppRouter`. Module routers can only express one of
/// these, never a `UINavigationController` call or a size class question.
enum Route: Sendable, Equatable, Hashable {
    /// The list of homes and zones in the sidebar.
    case homes
    /// A specific home selected, which fills the supplementary column with its rooms.
    case home(HomeSnapshot.ID)
    /// A specific room selected within the supplementary column.
    case room(RoomSnapshot.ID)
    /// A specific accessory, whose services fill the detail column.
    case accessory(AccessorySnapshot.ID)
    /// The automation builder for a draft, presented modally.
    case automationBuilder(AutomationDraft.ID)
    /// The accessory setup and commissioning flow, presented modally.
    case setup
}
