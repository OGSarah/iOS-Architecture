//
//  Route.swift
//  StoneMill-MVVMC
//
//  Created by Sarah Clark on 7/16/26.
//

import Foundation

/// The identifiers of the app's three scenes, used both by the scene
/// declarations in `StoneMillApp` and by every ``SceneOpening`` call.
nonisolated enum SceneID: String, Equatable, Sendable, CaseIterable {

    /// The setup window.
    case setup

    /// The volumetric window holding the board.
    case board

    /// The immersive excavation space.
    case excavation
}

/// Everything this app can be showing, as data.
///
/// The coordinator owns a single `Route` and it is the source of truth for
/// which scene the user is in. The enum carries identity, not behavior: it
/// never opens anything itself.
nonisolated enum Route: Equatable, Sendable {

    /// The setup window is frontmost.
    case setup

    /// The board volume for a specific match is open.
    case board(GameState.ID)

    /// The immersive space is open on a specific site.
    case excavation(Excavation.ID)
}

/// In window destinations of the setup window's navigation stack.
///
/// Even push navigation inside the setup window is coordinator owned: the
/// stack path binds to the coordinator, and the view never names this type's
/// destination views.
nonisolated enum SetupDestination: Hashable, Sendable {

    /// The finished match list.
    case history
}
