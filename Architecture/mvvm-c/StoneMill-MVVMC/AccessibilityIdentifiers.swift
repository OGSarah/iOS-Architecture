//
//  AccessibilityIdentifiers.swift
//  StoneMill-MVVMC
//
//  Created by Sarah Clark on 7/16/26.
//

import Foundation

/// The accessibility identifiers shared by the views and the UI tests.
///
/// This file is a member of both the app target and the UI test target, so a
/// renamed identifier breaks the test at compile time instead of at runtime.
nonisolated enum AXID {

    /// Identifiers on the setup window.
    nonisolated enum Setup {
        static let hotSeatCard = "setup.opponent.hotSeat"
        static let computerCard = "setup.opponent.computer"
        static let lightName = "setup.name.light"
        static let darkName = "setup.name.dark"
        static let startButton = "setup.start"
        static let rulesToggle = "setup.rules"
        static let historyLink = "setup.history"
        static let validationLabel = "setup.validation"
    }

    /// Identifiers on the match history list.
    nonisolated enum History {
        static let list = "history.list"
        static let emptyState = "history.empty"
    }

    /// Identifiers on the board volume.
    nonisolated enum Board {
        static let status = "board.status"
        static let resetButton = "board.reset"
        static let excavationButton = "board.excavation"

        /// The debug control strip button that taps a board point.
        static func point(_ index: Int) -> String { "board.point.\(index)" }

        /// The debug control strip button that captures the piece at a point.
        static func capture(_ index: Int) -> String { "board.capture.\(index)" }
    }

    /// Identifiers on the immersive excavation space.
    nonisolated enum Excavation {
        static let returnButton = "excavation.return"

        /// The site switcher button for a given site identifier.
        static func siteButton(_ id: String) -> String { "excavation.site.\(id)" }
    }
}
