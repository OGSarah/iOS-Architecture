//
//  ForecastFormattingTests.swift
//  AuroraWatch-MVVM Watch AppTests
//
//  Created by Sarah Clark on 7/16/26.
//

import Foundation
import Testing
@testable import AuroraWatch_MVVM_Watch_App

/// Pins the display strings, made deterministic by injecting the reference
/// date and locale rather than reading `Date()`.
struct ForecastFormattingTests {

    @Test func wholeKpDropsTheFraction() {
        #expect(ForecastFormatting.kpString(6.0, locale: TestFixtures.enUS) == "Kp 6")
    }

    @Test func fractionalKpKeepsTwoDigits() {
        #expect(ForecastFormatting.kpString(4.33, locale: TestFixtures.enUS) == "Kp 4.33")
    }

    @Test func singleDecimalKpKeepsOneDigit() {
        #expect(ForecastFormatting.kpString(5.5, locale: TestFixtures.enUS) == "Kp 5.5")
    }

    @Test func stormDescriptorJoinsScaleAndTitle() {
        #expect(ForecastFormatting.stormDescriptor(for: .g3) == "G3 Strong storm")
    }

    @Test func stormDescriptorBelowThresholdIsJustTheTitle() {
        #expect(ForecastFormatting.stormDescriptor(for: .quiet) == "Quiet")
    }

    @Test func futureWindowPhrasesAsIn() {
        let date = TestFixtures.referenceDate.addingTimeInterval(3 * 60 * 60)

        let text = ForecastFormatting.relativeTime(
            from: date, reference: TestFixtures.referenceDate, locale: TestFixtures.enUS
        )

        #expect(text == "in 3 hours")
    }

    @Test func pastWindowPhrasesAsAgo() {
        let date = TestFixtures.referenceDate.addingTimeInterval(-4 * 60 * 60)

        let text = ForecastFormatting.relativeTime(
            from: date, reference: TestFixtures.referenceDate, locale: TestFixtures.enUS
        )

        #expect(text == "4 hours ago")
    }

    @Test func inProgressWindowReadsNow() {
        let date = TestFixtures.referenceDate.addingTimeInterval(-60 * 60)

        let text = ForecastFormatting.relativeTime(
            from: date, reference: TestFixtures.referenceDate, locale: TestFixtures.enUS
        )

        #expect(text == "Now")
    }

    @Test func windowStartingExactlyNowReadsNow() {
        let text = ForecastFormatting.relativeTime(
            from: TestFixtures.referenceDate, reference: TestFixtures.referenceDate, locale: TestFixtures.enUS
        )

        #expect(text == "Now")
    }
}
