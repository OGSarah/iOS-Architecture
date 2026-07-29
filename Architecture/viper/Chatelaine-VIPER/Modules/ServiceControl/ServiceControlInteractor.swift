//
//  ServiceControlInteractor.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// Holds the optimistic write policy for one service, and owns its notification subscription.
///
/// The rule is exact. Apply the new value to the snapshot, report it upward immediately, then issue
/// the write. On rejection, report the previous value along with a reason. Writes to the same
/// characteristic are serialized so two changes in flight resolve in the order they were made. This
/// type imports neither UIKit nor HomeKit. Its only dependencies are the injected seams.
final class ServiceControlInteractor: ServiceControlInteractorInput {

    weak var output: ServiceControlInteractorOutput?

    /// The current snapshot, the one stateful piece of the module below the Presenter.
    private var service: ServiceSnapshot
    private let writer: CharacteristicWriting
    private let notifications: NotificationPolicy?

    /// The tail of the serial write chain, so writes resolve in call order.
    private var writeChain: Task<Void, Never> = Task {}

    init(service: ServiceSnapshot, writer: CharacteristicWriting, notifications: NotificationPolicy? = nil) {
        self.service = service
        self.writer = writer
        self.notifications = notifications
    }

    func loadInitial() {
        output?.didUpdate(service: service)
    }

    func setValue(_ value: CharacteristicValue, for characteristicID: String) {
        let previous = service

        // Optimistic step: apply and report before the write is even issued.
        service = Self.applying(value, to: characteristicID, in: service)
        output?.didUpdate(service: service)

        // Serialize behind any in flight write so ordering is preserved.
        let priorWrite = writeChain
        writeChain = Task { [weak self] in
            await priorWrite.value
            await self?.performWrite(value, for: characteristicID, rollingBackTo: previous)
        }
    }

    func startNotifications() {
        let ids = service.characteristics.map(\.id)
        Task { await notifications?.enableNotifications(for: ids) }
    }

    /// Awaits any in flight writes. Used by tests to observe the write outcome deterministically.
    func waitForPendingWrites() async {
        await writeChain.value
    }

    func stopNotifications() {
        let ids = service.characteristics.map(\.id)
        Task { await notifications?.disableNotifications(for: ids) }
    }

    // MARK: - Writing

    private func performWrite(
        _ value: CharacteristicValue,
        for characteristicID: String,
        rollingBackTo previous: ServiceSnapshot
    ) async {
        do {
            try await writer.write(value, toCharacteristic: characteristicID)
        } catch {
            // The write was rejected, so the on screen value is now ahead of reality. Roll back.
            service = previous
            let reason = (error as? CharacteristicWriteError)?.reason ?? "The change could not be saved"
            output?.didFailWrite(previous: previous, reason: reason)
        }
    }

    /// Returns a copy of the service with one characteristic's value replaced.
    private static func applying(
        _ value: CharacteristicValue,
        to characteristicID: String,
        in service: ServiceSnapshot
    ) -> ServiceSnapshot {
        let characteristics = service.characteristics.map { characteristic in
            characteristic.id == characteristicID ? characteristic.withValue(value) : characteristic
        }
        return ServiceSnapshot(
            id: service.id,
            type: service.type,
            name: service.name,
            characteristics: characteristics,
            linkedServiceIDs: service.linkedServiceIDs
        )
    }
}
