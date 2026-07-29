//
//  DeepLink.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import Foundation

/// Parses an App Intent request or a URL into a `Route`.
///
/// This is the second entry point into the same Router the UI uses. An App Intent can resolve an
/// accessory and hand its id here, and the resulting `Route` drives `AppRouter` through exactly the
/// same column reconstruction the UI would trigger.
enum DeepLink {

    /// The custom URL scheme the app answers to.
    static let scheme = "chatelaine"

    /// Turns a URL such as `chatelaine://accessory/<id>` into a route.
    /// - Parameter url: The incoming URL.
    /// - Returns: The route it names, or `nil` when the URL is not recognized.
    static func route(from url: URL) -> Route? {
        guard url.scheme == scheme, let host = url.host else { return nil }
        let identifier = url.pathComponents.first { $0 != "/" }

        switch host {
        case "homes":
            return .homes
        case "home":
            return identifier.map { .home($0) }
        case "room":
            return identifier.map { .room($0) }
        case "accessory":
            return identifier.map { .accessory($0) }
        case "setup":
            return .setup
        default:
            return nil
        }
    }

    /// The route an accessory power intent resolves to.
    /// - Parameter accessoryID: The accessory the intent targeted.
    /// - Returns: The accessory route.
    static func accessoryRoute(accessoryID: AccessorySnapshot.ID) -> Route {
        .accessory(accessoryID)
    }
}
