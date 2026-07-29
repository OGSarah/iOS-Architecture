//
//  ServiceControlContract.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// All five protocol boundaries for the ServiceControl module, gathered in one file.
///
/// Every arrow between roles is one of these protocols. Nothing depends on a concrete type across a
/// boundary, which is what makes each role independently substitutable and independently testable.

// MARK: - View

/// What the Presenter is allowed to tell the View to do.
@MainActor
protocol ServiceControlViewInput: AnyObject {
    /// Renders a fully formed view model. The View does no formatting of its own.
    func display(_ viewModel: ServiceControlViewModel)

    /// Posts a message to assistive technologies, for example an inline rollback reason.
    /// - Parameter message: The already localized announcement.
    func announce(_ message: String)
}

/// The raw user intent the View forwards to the Presenter.
@MainActor
protocol ServiceControlViewOutput: AnyObject {
    func viewDidLoad()
    func viewWillDisappear()
    func didToggle(characteristicID: String, isOn: Bool)
    func didChangeValue(_ value: Double, characteristicID: String)
    func didSelectOption(optionID: Int, characteristicID: String)
}

// MARK: - Interactor

/// What the Presenter can ask the Interactor to do.
@MainActor
protocol ServiceControlInteractorInput: AnyObject {
    /// Reports the initial service snapshot upward.
    func loadInitial()
    /// Applies a value optimistically and issues the write.
    func setValue(_ value: CharacteristicValue, for characteristicID: String)
    /// Subscribes to live updates for the service's characteristics.
    func startNotifications()
    /// Unsubscribes from live updates.
    func stopNotifications()
}

/// What the Interactor reports back, without knowing who is listening.
@MainActor
protocol ServiceControlInteractorOutput: AnyObject {
    /// A new immutable snapshot is available, whether from an optimistic write or a live update.
    func didUpdate(service: ServiceSnapshot)
    /// A write was rejected. The previous snapshot is returned along with a reason.
    func didFailWrite(previous: ServiceSnapshot, reason: String)
}

// MARK: - Router

/// The navigation intents this module can express.
@MainActor
protocol ServiceControlRouterInput: AnyObject {
    /// Requests a new automation seeded from a characteristic of this service.
    /// - Parameter characteristicID: The characteristic to build an automation around.
    func routeToAutomation(for characteristicID: String)
}
