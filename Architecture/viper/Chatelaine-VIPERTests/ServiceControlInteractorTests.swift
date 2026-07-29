//
//  ServiceControlInteractorTests.swift
//  Chatelaine-VIPERTests
//
//  Created by Sarah Clark on 7/29/26.
//

import Testing
@testable import Chatelaine_VIPER

/// Records characteristic writes, and can be told to reject them, in call order.
@MainActor
final class SpyCharacteristicWriter: CharacteristicWriting {
    private(set) var writes: [(value: CharacteristicValue, id: String)] = []
    var shouldFail = false
    var failure: CharacteristicWriteError = .unreachable

    func write(_ value: CharacteristicValue, toCharacteristic characteristicID: String) async throws {
        writes.append((value, characteristicID))
        if shouldFail { throw failure }
    }
}

/// Records what the Interactor reported upward.
@MainActor
final class SpyInteractorOutput: ServiceControlInteractorOutput {
    private(set) var updates: [ServiceSnapshot] = []
    private(set) var failures: [(previous: ServiceSnapshot, reason: String)] = []

    func didUpdate(service: ServiceSnapshot) { updates.append(service) }
    func didFailWrite(previous: ServiceSnapshot, reason: String) { failures.append((previous, reason)) }
}

@MainActor
struct ServiceControlInteractorTests {

    private func value(_ service: ServiceSnapshot, _ id: String) -> CharacteristicValue? {
        service.characteristics.first { $0.id == id }?.value
    }

    @Test("An optimistic value is reported before the write is issued")
    func optimisticBeforeWrite() async {
        let output = SpyInteractorOutput()
        let writer = SpyCharacteristicWriter()
        let interactor = ServiceControlInteractor(service: TestHouseholds.lightService(), writer: writer)
        interactor.output = output

        interactor.setValue(.bool(true), for: "char.power")

        // The optimistic update is synchronous, the write is not yet issued.
        #expect(output.updates.count == 1)
        #expect(value(output.updates[0], "char.power") == .bool(true))
        #expect(writer.writes.isEmpty)

        await interactor.waitForPendingWrites()
        #expect(writer.writes.count == 1)
    }

    @Test("A rejected write reports the previous value, not a default")
    func rejectionReportsPreviousValue() async {
        let output = SpyInteractorOutput()
        let writer = SpyCharacteristicWriter()
        writer.shouldFail = true
        let interactor = ServiceControlInteractor(service: TestHouseholds.lightService(brightness: 60), writer: writer)
        interactor.output = output

        interactor.setValue(.int(80), for: "char.brightness")
        await interactor.waitForPendingWrites()

        #expect(output.failures.count == 1)
        #expect(value(output.failures[0].previous, "char.brightness") == .int(60))
        #expect(output.failures[0].reason == CharacteristicWriteError.unreachable.reason)
    }

    @Test("Two writes to the same characteristic in flight resolve in order")
    func twoWritesResolveInOrder() async {
        let output = SpyInteractorOutput()
        let writer = SpyCharacteristicWriter()
        let interactor = ServiceControlInteractor(service: TestHouseholds.lightService(), writer: writer)
        interactor.output = output

        interactor.setValue(.int(10), for: "char.brightness")
        interactor.setValue(.int(20), for: "char.brightness")
        await interactor.waitForPendingWrites()

        #expect(writer.writes.map(\.value) == [.int(10), .int(20)])
    }

    @Test("Loading initial reports the starting snapshot once")
    func loadInitialReportsSnapshot() {
        let output = SpyInteractorOutput()
        let interactor = ServiceControlInteractor(service: TestHouseholds.lightService(power: true), writer: SpyCharacteristicWriter())
        interactor.output = output

        interactor.loadInitial()

        #expect(output.updates.count == 1)
        #expect(value(output.updates[0], "char.power") == .bool(true))
    }
}
