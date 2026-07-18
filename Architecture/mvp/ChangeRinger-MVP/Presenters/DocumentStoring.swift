//
//  DocumentStoring.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

import Foundation

/// The state a document can be in, reported upward without anyone having asked.
///
/// These mirror the states a `UIDocument` moves through, reduced to just what the editor
/// needs to react to. They arrive as notifications on the system's own schedule, which is
/// the whole reason a document editor is a good fit for MVP: the presenter, not the view,
/// decides what each of these means on screen.
enum DocumentState: Sendable, Equatable {

    /// The document is open and editing is enabled.
    case normal

    /// The document is busy and it is not currently safe for user edits.
    case editingDisabled

    /// Saving or reverting failed.
    case savingError

    /// Two versions of the document exist at once and one has to be chosen.
    case inConflict

    /// The document has closed, for example because the file was deleted underneath it.
    case closed
}

/// One version of a document involved in a conflict.
///
/// A conflict means two real versions of the user's work exist at once. Each is described
/// here by a title and a human-readable detail line so the presenter can format the choice
/// and the view can present it without knowing what a file version is.
struct DocumentVersion: Identifiable, Sendable, Equatable {

    /// A stable identifier the view reports back when the user chooses this version.
    let id: UUID

    /// A short title for the version, such as `"This device"`.
    let title: String

    /// A human-readable summary, such as the modification date and a description.
    let detail: String
}

/// The seam between the presenter and the document lifecycle.
///
/// This protocol is the entire surface the presenter is allowed to see of the document. A
/// real implementation wraps a `TouchDocument`, forwards edits as change-count updates, and
/// translates `UIDocument` state notifications into ``DocumentState`` values. A test
/// implementation returns whatever the test wants and records what it was asked to do, which
/// is why the presenter can be tested with no file, no file coordinator, and no simulator.
@MainActor
protocol DocumentStoring: AnyObject {

    /// The touch currently held by the document.
    var touch: Touch { get }

    /// A callback invoked whenever the document's state changes, on the system's schedule.
    var stateChanged: ((DocumentState) -> Void)? { get set }

    /// Opens the document. Opening is asynchronous and can fail.
    func open() async throws

    /// Records an edited touch, marking the document dirty so autosave will persist it.
    ///
    /// - Parameter touch: The new touch to store.
    func update(touch: Touch)

    /// Closes the document, saving any outstanding changes first.
    func close() async

    /// The conflicting versions of the document, valid only in the `.inConflict` state.
    func conflictVersions() -> [DocumentVersion]

    /// Resolves a conflict by keeping one version and discarding the others.
    ///
    /// - Parameter version: The version the user chose to keep.
    func resolveConflict(keeping version: DocumentVersion) async
}
