//
//  SpyTouchEditorView.swift
//  ChangeRinger-MVPTests
//
//  Created by Sarah Clark on 7/17/26.
//

import Foundation
@testable import ChangeRinger_MVP

/// Records the commands the presenter sends, so a test can assert the exact sequence of UI
/// updates without a window, a view hierarchy, or a run loop. This is the heart of what MVP
/// buys: the whole behaviour of the screen is observable as plain method calls on this spy.
@MainActor
final class SpyTouchEditorView: TouchEditorView {

    private(set) var displayedRows: [EditorRow] = []
    private(set) var displayCallCount = 0
    private(set) var truthFailure: (rowIndex: Int, message: String)?
    private(set) var clearTruthCount = 0
    private(set) var saveIndicator: SaveIndicator?
    private(set) var notation: String?
    private(set) var title: String?
    private(set) var conflictVersions: [DocumentVersion]?
    private(set) var dismissMessage: String?
    private(set) var playbackHighlight: Int??
    private(set) var isPlaying: Bool?
    private(set) var errors: [String] = []

    func display(rows: [EditorRow]) {
        displayedRows = rows
        displayCallCount += 1
    }

    func showTruthFailure(at rowIndex: Int, message: String) {
        truthFailure = (rowIndex, message)
    }

    func clearTruthFailure() {
        truthFailure = nil
        clearTruthCount += 1
    }

    func setSaveIndicator(_ indicator: SaveIndicator) {
        saveIndicator = indicator
    }

    func setNotation(_ notation: String) {
        self.notation = notation
    }

    func setTitle(_ title: String) {
        self.title = title
    }

    func showConflict(versions: [DocumentVersion]) {
        conflictVersions = versions
    }

    func dismissWithMessage(_ message: String) {
        dismissMessage = message
    }

    func setPlaybackHighlight(rowIndex: Int?) {
        playbackHighlight = rowIndex
    }

    func setPlaying(_ isPlaying: Bool) {
        self.isPlaying = isPlaying
    }

    func showError(_ message: String) {
        errors.append(message)
    }
}
