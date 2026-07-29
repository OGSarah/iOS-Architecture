//
//  HomeStoreProviding.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// The authorization state of the app's access to the user's homes.
enum HomeAuthorizationStatus: Sendable, Equatable {
    case notDetermined
    case restricted
    case authorized
    /// Authorized, but the account contains no homes yet.
    case authorizedNoHomes
}

/// Receives live updates when the home graph changes underneath the app.
///
/// HomeKit is a mutating object graph, so the store pushes fresh snapshots rather than expecting
/// callers to poll. Observers are held weakly by the store.
@MainActor
protocol HomeStoreObserver: AnyObject {
    /// Called when the primary home has changed in any way.
    /// - Parameter home: The new immutable snapshot of the home.
    func homeStoreDidUpdate(_ home: HomeSnapshot)

    /// Called when authorization status changes, for example after the permission prompt.
    /// - Parameter status: The new authorization status.
    func homeStoreDidChangeAuthorization(_ status: HomeAuthorizationStatus)
}

/// The read side seam every Interactor depends on to observe the home graph.
///
/// This is the protocol that lets the tests replace live HomeKit with a scripted household. No
/// Interactor ever depends on `HomeStore` directly, only on this.
@MainActor
protocol HomeStoreProviding: AnyObject {
    /// The current authorization status.
    var authorizationStatus: HomeAuthorizationStatus { get }

    /// Loads the current snapshot of the primary home.
    /// - Returns: The primary home snapshot, or `nil` when none is available.
    func loadPrimaryHome() async -> HomeSnapshot?

    /// Registers an observer for live updates. The store holds it weakly.
    /// - Parameter observer: The observer to add.
    func addObserver(_ observer: HomeStoreObserver)

    /// Removes a previously registered observer.
    /// - Parameter observer: The observer to remove.
    func removeObserver(_ observer: HomeStoreObserver)
}
