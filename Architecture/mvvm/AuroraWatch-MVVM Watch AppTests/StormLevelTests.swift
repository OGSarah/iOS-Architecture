//
//  StormLevelTests.swift
//  AuroraWatch-MVVM Watch AppTests
//
//  Created by Sarah Clark on 7/16/26.
//

import Testing
@testable import AuroraWatch_MVVM_Watch_App

/// Pins the Kp to G-scale mapping across every boundary.
///
/// The G1 edge at exactly 5.0 is the case most worth guarding: NOAA defines
/// G1 as Kp 5, so 4.99 must stay quiet while 5.0 storms.
struct StormLevelTests {

    @Test(arguments: [
        (0.0, StormLevel.quiet),
        (3.67, StormLevel.quiet),
        (4.99, StormLevel.quiet),
        (5.0, StormLevel.g1),
        (5.67, StormLevel.g1),
        (5.99, StormLevel.g1),
        (6.0, StormLevel.g2),
        (6.99, StormLevel.g2),
        (7.0, StormLevel.g3),
        (7.99, StormLevel.g3),
        (8.0, StormLevel.g4),
        (8.99, StormLevel.g4),
        (9.0, StormLevel.g5),
        (9.67, StormLevel.g5),
    ])
    func mapsKpOntoTheGScale(kp: Double, expected: StormLevel) {
        #expect(StormLevel(kp: kp) == expected)
    }

    @Test func scaleLabelsMatchNOAA() {
        #expect(StormLevel.quiet.scaleLabel == nil)
        #expect(StormLevel.g1.scaleLabel == "G1")
        #expect(StormLevel.g2.scaleLabel == "G2")
        #expect(StormLevel.g3.scaleLabel == "G3")
        #expect(StormLevel.g4.scaleLabel == "G4")
        #expect(StormLevel.g5.scaleLabel == "G5")
    }

    @Test func titlesMatchNOAASeverityNames() {
        #expect(StormLevel.quiet.title == "Quiet")
        #expect(StormLevel.g1.title == "Minor storm")
        #expect(StormLevel.g2.title == "Moderate storm")
        #expect(StormLevel.g3.title == "Strong storm")
        #expect(StormLevel.g4.title == "Severe storm")
        #expect(StormLevel.g5.title == "Extreme storm")
    }

    @Test(arguments: StormLevel.allCases)
    func everyLevelHasAVisibilityLine(level: StormLevel) {
        #expect(!level.visibilityDescription.isEmpty)
    }

    @Test func levelsOrderBySeverity() {
        #expect(StormLevel.quiet < StormLevel.g1)
        #expect(StormLevel.g1 < StormLevel.g5)
    }
}
