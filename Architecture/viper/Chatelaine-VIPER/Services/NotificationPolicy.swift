//
//  NotificationPolicy.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// The seam that controls which characteristics stay subscribed to live updates, and when.
///
/// Notifications are opt in and are not free. Leaving them enabled for every characteristic on
/// every accessory costs battery on the accessory itself, so an Interactor enables them when its
/// module appears and disables them when it goes away.
@MainActor
protocol NotificationPolicy: AnyObject {
    /// Enables live notifications for a set of characteristics.
    /// - Parameter characteristicIDs: The characteristics to subscribe to.
    func enableNotifications(for characteristicIDs: [String]) async

    /// Disables live notifications for a set of characteristics.
    /// - Parameter characteristicIDs: The characteristics to unsubscribe from.
    func disableNotifications(for characteristicIDs: [String]) async
}
