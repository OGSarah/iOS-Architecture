//
//  AccessibilityIdentifiers.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

/// Accessibility identifiers assigned by the app's views and looked up by the unit and UI
/// tests. Centralizing the strings keeps the app and the tests from drifting apart.
///
/// The UI test target cannot import the app module, so the UI tests duplicate these strings
/// as literals; update both places together.
nonisolated enum AccessibilityID {

    /// Elements owned by the touch editor.
    enum Editor {
        static let grid = "editor.grid"
        static let notationField = "editor.notationField"
        static let truthBanner = "editor.truthBanner"
        static let saveIndicator = "editor.saveIndicator"
        static let playButton = "editor.playButton"
        static let methodButton = "editor.methodButton"
        static let blueLineControl = "editor.blueLineControl"

        /// A row cell in the grid, suffixed with its index, such as `editor.row.12`.
        static func row(_ index: Int) -> String { "editor.row.\(index)" }
    }

    /// Buttons on the call strip.
    enum CallStrip {
        static let container = "callStrip"
        static let plain = "callStrip.plain"
        static let bob = "callStrip.bob"
        static let single = "callStrip.single"
    }

    /// Elements owned by the method picker.
    enum MethodPicker {
        static let table = "methodPicker.table"

        /// A method row, suffixed with its index, such as `methodPicker.row.1`.
        static func row(_ index: Int) -> String { "methodPicker.row.\(index)" }
    }
}
