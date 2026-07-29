//
//  AppRouterTests.swift
//  Chatelaine-VIPERTests
//
//  Created by Sarah Clark on 7/29/26.
//

import Foundation
import Testing
@testable import Chatelaine_VIPER

/// Drives `AppRouter` through the same route requests the module routers make, and asserts the
/// column resolution policy directly, in milliseconds, with no UI test in sight.
@MainActor
struct AppRouterTests {

    private func makeRouter(
        collapsed: Bool,
        home: HomeSnapshot? = TestHouseholds.home()
    ) -> (AppRouter, SpySplitViewPresenter) {
        let spy = SpySplitViewPresenter()
        spy.isCollapsed = collapsed
        let router = AppRouter(splitView: spy, moduleFactory: StubModuleFactory())
        router.updateHome(home)
        return (router, spy)
    }

    @Test("At regular width an accessory replaces the secondary column behind an intact sidebar")
    func regularWidthAccessoryFillsThreeColumns() {
        let (router, spy) = makeRouter(collapsed: false)
        router.present(.accessory("accessory.light"))
        #expect(spy.events == [.install(.primary), .install(.supplementary), .install(.secondary)])
    }

    @Test("At compact width the same accessory route is a push onto the collapsed stack")
    func compactWidthAccessoryPushes() {
        let (router, spy) = makeRouter(collapsed: true)
        router.present(.accessory("accessory.light"))
        #expect(spy.events == [.pushDetail])
    }

    @Test("A cold deep link from an App Intent builds all three columns in order")
    func coldDeepLinkBuildsThreeColumnsInOrder() throws {
        let (router, spy) = makeRouter(collapsed: false)
        let url = try #require(URL(string: "chatelaine://accessory/accessory.light"))
        let route = DeepLink.route(from: url)
        #expect(route == .accessory("accessory.light"))
        router.present(try #require(route))
        #expect(spy.events == [.install(.primary), .install(.supplementary), .install(.secondary)])
    }

    @Test("A Matter result returning after the user navigated away is discarded")
    func staleMatterResultIsDiscarded() {
        let (router, spy) = makeRouter(collapsed: false)
        let ticket = UUID()
        router.beginSetup(ticket: ticket)
        router.present(.homes)   // The user navigates elsewhere while setup is out of process.
        spy.clear()
        router.resolveSetup(ticket: ticket, result: .added(accessoryID: "accessory.light"))
        #expect(spy.events.isEmpty)
    }

    @Test("A Matter result matching the pending ticket navigates to the new accessory")
    func freshMatterResultNavigatesToAccessory() {
        let (router, spy) = makeRouter(collapsed: false)
        let ticket = UUID()
        router.beginSetup(ticket: ticket)
        spy.clear()
        router.resolveSetup(ticket: ticket, result: .added(accessoryID: "accessory.light"))
        #expect(spy.events == [.install(.primary), .install(.supplementary), .install(.secondary)])
    }

    @Test("An automation builder route is presented modally, not placed in a column")
    func automationBuilderIsModal() {
        let (router, spy) = makeRouter(collapsed: false)
        router.present(.automationBuilder("draft.1"))
        #expect(spy.events == [.presentModally])
    }
}
