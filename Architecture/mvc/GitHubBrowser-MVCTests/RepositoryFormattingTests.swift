//
//  RepositoryFormattingTests.swift
//  GitHubBrowser-MVCTests
//
//  Created by Sarah Clark on 7/15/26.
//

import Foundation
import Testing
@testable import GitHubBrowser_MVC

struct RepositoryFormattingTests {

    @Test(arguments: [
        (0, "0"),
        (42, "42"),
        (999, "999"),
        (1000, "1.0k"),
        (1200, "1.2k"),
        // Documents a rounding quirk at the top of the thousands range:
        // 999,999 renders as "1000.0k" rather than promoting to "1.0M".
        (999_999, "1000.0k"),
        (1_000_000, "1.0M"),
        (2_500_000, "2.5M"),
    ])
    @MainActor
    func `Compact count formats values across magnitudes`(count: Int, expected: String) {
        #expect(RepositoryFormatting.compactCount(count) == expected)
    }

    @Test(arguments: [
        (60.0, "1m ago"),
        (3600.0, "1h ago"),
        (86_400.0, "1d ago"),
        (604_800.0, "1w ago"),
    ])
    @MainActor
    func `Relative updated at is deterministic with an injected now`(secondsAgo: TimeInterval, expected: String) {
        let now = Date(timeIntervalSince1970: 1_750_000_000)
        let date = now.addingTimeInterval(-secondsAgo)

        let formatted = RepositoryFormatting.relativeUpdatedAt(date, now: now, locale: Locale(identifier: "en_US"))

        #expect(formatted == expected)
    }
}
