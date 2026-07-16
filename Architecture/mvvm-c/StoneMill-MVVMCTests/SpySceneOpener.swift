//
//  SpySceneOpener.swift
//  StoneMill-MVVMC
//
//  Created by Sarah Clark on 7/16/26.
//

import Foundation
@testable import StoneMill_MVVMC

/// A ``SceneOpening`` that records scene transitions instead of performing
/// them.
///
/// This is the seam that makes navigation itself unit testable: coordinator
/// tests assert the exact sequence of recorded events, and choose how a
/// requested immersive space responds.
@MainActor
final class SpySceneOpener: SceneOpening {

    /// One recorded scene transition.
    enum Event: Equatable {
        case openWindow(String)
        case dismissWindow(String)
        case openImmersiveSpace(String)
        case dismissImmersiveSpace
    }

    /// Every transition the coordinator requested, in order.
    private(set) var events: [Event] = []

    /// What the next `openImmersiveSpace` call reports back.
    var immersiveResult: ImmersiveOpenResult = .opened

    func openWindow(id: String) {
        events.append(.openWindow(id))
    }

    func dismissWindow(id: String) {
        events.append(.dismissWindow(id))
    }

    func openImmersiveSpace(id: String) async -> ImmersiveOpenResult {
        events.append(.openImmersiveSpace(id))
        return immersiveResult
    }

    func dismissImmersiveSpace() async {
        events.append(.dismissImmersiveSpace)
    }

    /// Clears the recorded events between phases of a test.
    func reset() {
        events.removeAll()
    }
}
