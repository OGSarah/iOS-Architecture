//
//  LiveDocumentStore.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

import UIKit

/// The real `DocumentStoring`, wrapping a `TouchDocument`.
///
/// This is the one place that touches `UIDocument` directly. It forwards edits as change
/// counts so autosave persists them, translates the document's state notifications into
/// ``DocumentState`` values, and reads conflicting versions with `NSFileVersion`. Everything
/// above it, the presenter and the view, sees only the ``DocumentStoring`` protocol, so none
/// of this file coordination leaks upward.
@MainActor
final class LiveDocumentStore: DocumentStoring {

    /// The document being edited.
    private let document: TouchDocument

    /// The observer token for the document's state-change notification.
    ///
    /// Marked `nonisolated(unsafe)` so the nonisolated `deinit` can remove it. This is safe
    /// because the token is only assigned once in `init` and only read in `deinit`.
    nonisolated(unsafe) private var observer: NSObjectProtocol?

    /// The file versions offered in the last conflict, keyed so a choice can be resolved.
    private var versionsByID: [UUID: NSFileVersion] = [:]

    /// A formatter for the modification dates shown in the conflict list.
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    /// Creates a store over a document.
    ///
    /// - Parameter document: The document to wrap.
    init(document: TouchDocument) {
        self.document = document
        observer = NotificationCenter.default.addObserver(
            forName: UIDocument.stateChangedNotification,
            object: document,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.reportState()
            }
        }
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: DocumentStoring

    var touch: Touch { document.touch }

    var stateChanged: ((DocumentState) -> Void)?

    func open() async throws {
        let opened = await document.open()
        guard opened else {
            throw CocoaError(.fileReadUnknown)
        }
    }

    func update(touch: Touch) {
        document.touch = touch
        document.updateChangeCount(.done)
    }

    func close() async {
        await document.close()
    }

    func conflictVersions() -> [DocumentVersion] {
        versionsByID = [:]
        var versions: [DocumentVersion] = []

        // The version currently open in this editor.
        if let current = NSFileVersion.currentVersionOfItem(at: document.fileURL) {
            let id = UUID()
            versionsByID[id] = current
            versions.append(
                DocumentVersion(
                    id: id,
                    title: "This device",
                    detail: detail(for: current)
                )
            )
        }

        // The conflicting versions from other devices.
        let conflicts = NSFileVersion.unresolvedConflictVersionsOfItem(at: document.fileURL) ?? []
        for version in conflicts {
            let id = UUID()
            versionsByID[id] = version
            versions.append(
                DocumentVersion(
                    id: id,
                    title: version.localizedNameOfSavingComputer ?? "Another device",
                    detail: detail(for: version)
                )
            )
        }
        return versions
    }

    func resolveConflict(keeping version: DocumentVersion) async {
        guard let chosen = versionsByID[version.id] else { return }

        // If a version from another device was chosen, replace the current file with it.
        // Choosing the current version needs no replacement: only the others are resolved.
        if chosen.isConflict {
            _ = try? chosen.replaceItem(at: document.fileURL, options: [])
        }

        // Mark every conflicting version resolved so the document leaves the conflict state.
        let conflicts = NSFileVersion.unresolvedConflictVersionsOfItem(at: document.fileURL) ?? []
        for conflict in conflicts {
            conflict.isResolved = true
        }
        try? NSFileVersion.removeOtherVersionsOfItem(at: document.fileURL)

        await document.revert(toContentsOf: document.fileURL)
    }

    // MARK: Private

    /// Maps the document's current option-set state to a single reported state.
    private func reportState() {
        let state = document.documentState
        let reported: DocumentState
        if state.contains(.closed) {
            reported = .closed
        } else if state.contains(.inConflict) {
            reported = .inConflict
        } else if state.contains(.savingError) {
            reported = .savingError
        } else if state.contains(.editingDisabled) {
            reported = .editingDisabled
        } else {
            reported = .normal
        }
        stateChanged?(reported)
    }

    /// Builds the human-readable detail line for a file version.
    private func detail(for version: NSFileVersion) -> String {
        guard let date = version.modificationDate else { return "Unknown date" }
        return "Modified \(dateFormatter.string(from: date))"
    }
}
