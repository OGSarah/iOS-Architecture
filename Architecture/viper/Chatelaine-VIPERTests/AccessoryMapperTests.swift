//
//  AccessoryMapperTests.swift
//  Chatelaine-VIPERTests
//
//  Created by Sarah Clark on 7/29/26.
//

import Testing
@testable import Chatelaine_VIPER

@MainActor
struct AccessoryMapperTests {

    @Test("A reachable accessory maps to reachable")
    func reachableMapsToReachable() {
        let descriptor = AccessoryBuilder.make(id: "a", isReachable: true)
        #expect(AccessoryMapper.snapshot(from: descriptor).reachability == .reachable)
    }

    @Test("An unreachable accessory with no bridge maps to a bare unreachable")
    func unreachableDirectMapsToUnreachable() {
        let descriptor = AccessoryBuilder.make(id: "a", isReachable: false, bridgeID: nil)
        #expect(AccessoryMapper.snapshot(from: descriptor).reachability == .unreachable)
    }

    @Test("An unreachable bridged accessory attributes the outage to its bridge")
    func unreachableBridgedMapsToViaBridge() {
        let descriptor = AccessoryBuilder.make(id: "a", isReachable: false, bridgeID: "bridge.1")
        #expect(AccessoryMapper.snapshot(from: descriptor).reachability == .unreachableViaBridge(bridgeID: "bridge.1"))
    }

    @Test("Two accessories behind the same downed bridge collapse to one bridge id")
    func bridgedAccessoriesShareOneBridgeID() {
        let first = AccessoryMapper.snapshot(from: AccessoryBuilder.make(id: "a", isReachable: false, bridgeID: "bridge.1"))
        let second = AccessoryMapper.snapshot(from: AccessoryBuilder.make(id: "b", isReachable: false, bridgeID: "bridge.1"))
        #expect(first.reachability == second.reachability)
        #expect(first.reachability == .unreachableViaBridge(bridgeID: "bridge.1"))
    }

    @Test("Linked services survive the trip into value types")
    func linkedServicesStayGrouped() {
        let fan = ServiceSnapshot(id: "s.fan", type: "fan", name: "Fan", characteristics: [], linkedServiceIDs: ["s.light"])
        let light = ServiceSnapshot(id: "s.light", type: "lightbulb", name: "Light", characteristics: [], linkedServiceIDs: ["s.fan"])
        let descriptor = AccessoryBuilder.make(id: "ceiling", services: [fan, light])
        let snapshot = AccessoryMapper.snapshot(from: descriptor)
        #expect(snapshot.services.first?.linkedServiceIDs == ["s.light"])
        #expect(snapshot.services.last?.linkedServiceIDs == ["s.fan"])
    }
}
