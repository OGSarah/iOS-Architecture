//
//  IntentActions.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import Foundation

/// The main actor isolated work behind the App Intents.
///
/// `AppIntent.perform()` runs nonisolated, but `HomeStore` is main actor isolated. These helpers are
/// `@MainActor` and `async`, so an intent simply awaits one and the hop to the main actor is handled
/// for it. Keeping the domain work here also keeps the intents thin, mirroring a passive View.
@MainActor
enum IntentActions {

    /// Turns an accessory on or off, matched by name, and returns a spoken result.
    static func setPower(accessoryName: String, turnOn: Bool) async -> String {
        let store = HomeStore()
        let home = await store.loadPrimaryHome()

        guard let accessory = home?.accessories.first(where: { $0.name.localizedCaseInsensitiveContains(accessoryName) }) else {
            return "I could not find an accessory called \(accessoryName)."
        }
        guard let toggle = accessory.services
            .flatMap(\.characteristics)
            .first(where: { $0.isWritable && $0.controlKind == .toggle }) else {
            return "\(accessory.name) does not have a power control."
        }

        do {
            try await store.write(.bool(turnOn), toCharacteristic: toggle.id)
            return "\(turnOn ? "Turned on" : "Turned off") \(accessory.name)."
        } catch {
            return "I could not change \(accessory.name) right now."
        }
    }

    /// Activates a scene by name and returns a spoken result.
    static func activateScene(named sceneName: String) async -> String {
        let store = HomeStore()
        _ = await store.loadPrimaryHome()
        let activated = await store.activateScene(named: sceneName)
        return activated ? "Activated \(sceneName)." : "I could not find a scene called \(sceneName)."
    }
}
