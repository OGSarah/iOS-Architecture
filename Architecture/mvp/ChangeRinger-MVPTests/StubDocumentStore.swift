//
//  StubDocumentStore.swift
//  ChangeRinger-MVPTests
//
//  Created by Sarah Clark on 7/17/26.
//

import Foundation
@testable import ChangeRinger_MVP

/// A document lifecycle with no file behind it.
///
/// It returns whatever the test wants from `open`, records the touches it is asked to save,
/// and can fire any `DocumentState` on command. This is the seam that lets the presenter's
/// response to a save failure or a conflict be asserted in milliseconds, with no file, no
/// file coordinator, and no simulator.
@MainActor
final class StubDocumentStore: DocumentStoring {

    var touch: Touch
    var stateChanged: ((DocumentState) -> Void)?

    /// An error to throw from `open`, or `nil` to open successfully.
    var openError: Error?

    /// The versions to hand back when asked during a conflict.
    var versionsToReturn: [DocumentVersion] = []

    private(set) var openCount = 0
    private(set) var updatedTouches: [Touch] = []
    private(set) var closeCount = 0
    private(set) var resolvedVersion: DocumentVersion?

    /// Creates a stub seeded with a touch.
    ///
    /// - Parameter touch: The touch the store starts with.
    init(touch: Touch) {
        self.touch = touch
    }

    func open() async throws {
        openCount += 1
        if let openError { throw openError }
    }

    func update(touch: Touch) {
        self.touch = touch
        updatedTouches.append(touch)
    }

    func close() async {
        closeCount += 1
    }

    func conflictVersions() -> [DocumentVersion] {
        versionsToReturn
    }

    func resolveConflict(keeping version: DocumentVersion) async {
        resolvedVersion = version
    }

    /// Fires a state change, as the real document would on the system's schedule.
    ///
    /// - Parameter state: The state to report to the presenter.
    func fire(_ state: DocumentState) {
        stateChanged?(state)
    }
}
