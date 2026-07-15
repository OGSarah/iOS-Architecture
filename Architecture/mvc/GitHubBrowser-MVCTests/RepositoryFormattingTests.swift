//
//  RepositoryFormattingTests.swift
//  GitHubBrowser-MVCTests
//
//  Created by Sarah Clark on 7/15/26.
//

import Testing
@testable import GitHubBrowser_MVC

struct RepositoryFormattingTests {

    @Test(arguments: [
        (42, "42"),
        (1200, "1.2k"),
        (2_500_000, "2.5M"),
    ])
    @MainActor
    func `Compact count formats values across magnitudes`(count: Int, expected: String) {
        #expect(RepositoryFormatting.compactCount(count) == expected)
    }

}
