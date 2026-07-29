//
//  CharacteristicMapperTests.swift
//  Chatelaine-VIPERTests
//
//  Created by Sarah Clark on 7/29/26.
//

import Testing
@testable import Chatelaine_VIPER

/// The highest value suite in the project: metadata in, control kind out, with no device.
@MainActor
struct CharacteristicMapperTests {

    @Test("A writable boolean becomes a toggle")
    func writableBoolIsToggle() {
        let metadata = MetadataBuilder.make(format: .bool)
        #expect(CharacteristicMapper.controlKind(for: metadata) == .toggle)
    }

    @Test("A read only boolean becomes a readout, not a toggle")
    func readOnlyBoolIsReadout() {
        let metadata = MetadataBuilder.make(format: .bool, write: false)
        #expect(CharacteristicMapper.controlKind(for: metadata) == .readout(unit: .none))
    }

    @Test("A coarse step produces a stepper rather than a continuous slider")
    func coarseStepIsStepper() {
        let metadata = MetadataBuilder.make(format: .int, min: 0, max: 100, step: 10, unit: .percentage)
        #expect(CharacteristicMapper.controlKind(for: metadata) == .stepper(min: 0, max: 100, step: 10, unit: .percentage))
    }

    @Test("A fine step over a wide range produces a slider")
    func fineStepIsSlider() {
        let metadata = MetadataBuilder.make(format: .int, min: 0, max: 100, step: 1, unit: .percentage)
        #expect(CharacteristicMapper.controlKind(for: metadata) == .slider(min: 0, max: 100, unit: .percentage))
    }

    @Test("An enumerated set of valid values produces a picker")
    func enumeratedValuesArePicker() {
        let metadata = MetadataBuilder.make(format: .uint8, min: 0, max: 3, validValues: [0, 1, 2, 3])
        guard case let .picker(options) = CharacteristicMapper.controlKind(for: metadata) else {
            Issue.record("Expected a picker")
            return
        }
        #expect(options.map(\.id) == [0, 1, 2, 3])
    }

    @Test("A write only numeric characteristic with no read permission produces a control, never a readout")
    func writeOnlyNumericIsNotReadout() {
        let metadata = MetadataBuilder.make(format: .int, read: false, write: true, min: 0, max: 100, step: 1)
        let kind = CharacteristicMapper.controlKind(for: metadata)
        if case .readout = kind {
            Issue.record("A write only characteristic should not degrade to a readout")
        }
    }

    @Test("A read only numeric characteristic is a readout even though it has a range")
    func readOnlyNumericIsReadout() {
        let metadata = MetadataBuilder.make(format: .int, write: false, min: 0, max: 100, step: 1, unit: .lux)
        #expect(CharacteristicMapper.controlKind(for: metadata) == .readout(unit: .lux))
    }

    @Test("Numeric metadata missing its bounds degrades to a readout rather than guessing")
    func numericWithoutBoundsIsReadout() {
        let metadata = MetadataBuilder.make(format: .float, min: nil, max: nil)
        #expect(CharacteristicMapper.controlKind(for: metadata) == .readout(unit: .none))
    }

    @Test("An unknown or opaque format degrades to a readout rather than crashing", arguments: [
        CharacteristicFormat.string,
        CharacteristicFormat.data,
        CharacteristicFormat.tlv8,
        CharacteristicFormat.unknown
    ])
    func unknownFormatsAreReadouts(_ format: CharacteristicFormat) {
        let metadata = MetadataBuilder.make(format: format)
        #expect(CharacteristicMapper.controlKind(for: metadata) == .readout(unit: .none))
    }

    @Test("A step that lands exactly on the stepper threshold still prefers a stepper")
    func thresholdStopsAreStepper() {
        // 0 to 100 with a step of 5 gives 20 stops, the largest count that still prefers a stepper.
        let metadata = MetadataBuilder.make(format: .int, min: 0, max: 100, step: 5)
        #expect(CharacteristicMapper.controlKind(for: metadata) == .stepper(min: 0, max: 100, step: 5, unit: .none))
    }
}
