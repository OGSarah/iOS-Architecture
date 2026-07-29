//
//  AccessibilityIdentifiers.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// Identifier strings shared by the views and the UI tests, so neither drifts from the other.
///
/// Keeping them in one place means a UI test and the view it drives always agree on the string, and
/// renaming a screen is a single edit rather than a hunt through string literals.
enum AccessibilityIdentifiers {

    enum HomeList {
        static let collection = "homeList.collection"
    }

    enum RoomList {
        static let collection = "roomList.collection"
    }

    enum AccessoryDetail {
        static let collection = "accessoryDetail.collection"
    }

    enum ServiceControl {
        static let collection = "serviceControl.collection"
        /// The identifier for a control in a given characteristic row.
        static func control(_ characteristicID: String) -> String { "serviceControl.control.\(characteristicID)" }
        /// The identifier for the inline reason label in a given row.
        static func reason(_ characteristicID: String) -> String { "serviceControl.reason.\(characteristicID)" }
    }

    enum AutomationBuilder {
        static let saveButton = "automationBuilder.save"
        static let cancelButton = "automationBuilder.cancel"
    }

    enum Setup {
        static let cancelButton = "setup.cancel"
    }

    enum Onboarding {
        static let pageControl = "onboarding.pageControl"
        static let continueButton = "onboarding.continue"
        static let skipButton = "onboarding.skip"
    }
}
