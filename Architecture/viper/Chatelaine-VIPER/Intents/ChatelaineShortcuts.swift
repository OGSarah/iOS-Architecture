//
//  ChatelaineShortcuts.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import AppIntents

/// Exposes the app's intents to Siri and Shortcuts with spoken phrases.
struct ChatelaineShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SetAccessoryPowerIntent(),
            phrases: [
                "Set an accessory in \(.applicationName)",
                "Turn an accessory on with \(.applicationName)"
            ],
            shortTitle: "Set Accessory Power",
            systemImageName: "power"
        )
        AppShortcut(
            intent: ActivateSceneIntent(),
            phrases: [
                "Activate a scene in \(.applicationName)",
                "Run a \(.applicationName) scene"
            ],
            shortTitle: "Activate Scene",
            systemImageName: "theatermasks"
        )
    }
}
