//
//  TouchEditorView.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

import Foundation

/// One row as the editor should draw it, formatted entirely by the presenter.
///
/// The view receives finished strings and flags. It never formats a bell, decides whether a
/// row is a lead end, or works out what a call symbol should be: all of that has already
/// been decided by the presenter, so the view only has to lay the values out.
struct EditorRow: Sendable, Equatable {

    /// The row's index, counting rounds as row zero.
    let index: Int

    /// The row in its natural notation, such as `"135264"`.
    let notation: String

    /// The call symbol shown beside a lead end, such as `"-"` for a bob, or empty.
    let callSymbol: String

    /// Whether this row is a lead end, where a call may be placed.
    let isLeadEnd: Bool

    /// The one-based position of the traced bell in this row, or `nil` if none is traced.
    let blueLineColumn: Int?
}

/// How the save indicator should appear.
enum SaveIndicator: Sendable, Equatable {

    /// The document is saved and up to date.
    case saved

    /// The document has unsaved changes that autosave will write shortly.
    case saving

    /// The last save failed.
    case error
}

/// The passive view of the touch editor: the exact set of commands the presenter can issue.
///
/// This protocol is the entire contract between the presenter and the screen. Every method
/// is a single instruction the presenter calls to make one thing happen. The view that
/// conforms to it owns no state and makes no decisions; it just does what it is told, one
/// method call at a time. Because the presenter talks only to this protocol and never to a
/// concrete view controller, it can be tested with no window and no run loop.
@MainActor
protocol TouchEditorView: AnyObject {

    /// Replaces the rows shown in the grid, tracing the blue line where each row supplies a
    /// column for it.
    ///
    /// - Parameter rows: The formatted rows to display, in order from rounds.
    func display(rows: [EditorRow])

    /// Marks a row as the point where the composition first repeats itself.
    ///
    /// - Parameters:
    ///   - rowIndex: The index of the false row.
    ///   - message: The banner text describing the failure.
    func showTruthFailure(at rowIndex: Int, message: String)

    /// Clears any truth-failure banner and marking.
    func clearTruthFailure()

    /// Sets the save indicator's appearance.
    ///
    /// - Parameter indicator: The state to show.
    func setSaveIndicator(_ indicator: SaveIndicator)

    /// Sets the place-notation text shown in the notation bar.
    ///
    /// - Parameter notation: The method's notation string.
    func setNotation(_ notation: String)

    /// Sets the editor's navigation title.
    ///
    /// - Parameter title: The title to show, usually the method name.
    func setTitle(_ title: String)

    /// Presents the conflicting versions of the document for the user to choose between.
    ///
    /// - Parameter versions: The versions to offer.
    func showConflict(versions: [DocumentVersion])

    /// Dismisses the editor after showing a message, for example when the file is deleted.
    ///
    /// - Parameter message: The message to show before dismissing.
    func dismissWithMessage(_ message: String)

    /// Highlights the row currently sounding during playback, or clears the highlight.
    ///
    /// - Parameter rowIndex: The playing row, or `nil` to clear.
    func setPlaybackHighlight(rowIndex: Int?)

    /// Reflects whether playback is running, so the play control can update.
    ///
    /// - Parameter isPlaying: `true` while a touch is being played.
    func setPlaying(_ isPlaying: Bool)

    /// Shows a transient error message, such as an illegal edit or a load failure.
    ///
    /// - Parameter message: The message to show.
    func showError(_ message: String)
}
