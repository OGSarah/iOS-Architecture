//
//  SetAccessoryPowerIntent.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import AppIntents

/// Turns an accessory on or off from Siri or Shortcuts.
///
/// This is a second entry point into the same domain the UI uses. The work runs on the main actor
/// through `IntentActions`, where an accessory is resolved and its power toggle is found by control
/// kind rather than by a hardcoded characteristic type.
struct SetAccessoryPowerIntent: AppIntent {

    static let title: LocalizedStringResource = "Set Accessory Power"
    static let description = IntentDescription("Turn a HomeKit accessory on or off.")

    @Parameter(title: "Accessory") var accessoryName: String
    @Parameter(title: "Turn On") var turnOn: Bool

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = await IntentActions.setPower(accessoryName: accessoryName, turnOn: turnOn)
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}
