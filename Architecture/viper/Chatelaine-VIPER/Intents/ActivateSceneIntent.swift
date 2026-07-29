//
//  ActivateSceneIntent.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import AppIntents

/// Activates a HomeKit scene by name from Siri or Shortcuts.
struct ActivateSceneIntent: AppIntent {

    static let title: LocalizedStringResource = "Activate Scene"
    static let description = IntentDescription("Run a HomeKit scene by name.")

    @Parameter(title: "Scene") var sceneName: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = await IntentActions.activateScene(named: sceneName)
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}
