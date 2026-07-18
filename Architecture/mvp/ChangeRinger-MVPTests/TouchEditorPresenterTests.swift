//
//  TouchEditorPresenterTests.swift
//  ChangeRinger-MVPTests
//
//  Created by Sarah Clark on 7/17/26.
//

import Foundation
import Testing
@testable import ChangeRinger_MVP

/// Tests for the touch editor presenter, driven through the same methods the view controller
/// calls, with a `SpyTouchEditorView` and a `StubDocumentStore`. They assert the exact
/// commands the presenter sends, including its response to failures and conflicts that arrive
/// on the document's own schedule. None of this needs a file or a simulator.
@MainActor
struct TouchEditorPresenterTests {

    /// Builds a presenter wired to a fresh spy and stub.
    private func makePresenter(
        touch: Touch = Touch(method: .plainBobMinor),
        openError: Error? = nil
    ) -> (TouchEditorPresenter, SpyTouchEditorView, StubDocumentStore) {
        let store = StubDocumentStore(touch: touch)
        store.openError = openError
        let spy = SpyTouchEditorView()
        let presenter = TouchEditorPresenter(store: store, audio: SilentBells())
        presenter.view = spy
        return (presenter, spy, store)
    }

    @Test("Starting renders the plain course with no truth failure")
    func startRendersPlainCourse() async {
        let (presenter, spy, _) = makePresenter()
        presenter.start()
        await presenter.loadTask?.value

        #expect(spy.title == "Plain Bob Minor")
        #expect(spy.notation == "X16X16X16X16X16X12")
        #expect(spy.displayedRows.count == 61)
        #expect(spy.truthFailure == nil)
        #expect(spy.clearTruthCount >= 1)
    }

    @Test("Inserting a bob that keeps the touch true shows one display and no banner")
    func insertingTrueBobShowsNoBanner() async {
        let (presenter, spy, store) = makePresenter(touch: TouchFixtures.falsePlainBobMinor)
        presenter.start()
        await presenter.loadTask?.value
        #expect(spy.truthFailure != nil) // starts false at row 72

        presenter.didTapCall(.bob, atRowIndex: 48)

        #expect(spy.truthFailure == nil)
        #expect(store.updatedTouches.last?.calls == [12: .bob, 48: .bob])
        #expect(!spy.displayedRows.isEmpty)
    }

    @Test("Inserting a bob that makes the touch false shows the banner at the false row")
    func insertingFalseBobShowsBanner() async {
        let (presenter, spy, _) = makePresenter()
        presenter.start()
        await presenter.loadTask?.value

        presenter.didTapCall(.bob, atRowIndex: 12)

        #expect(spy.truthFailure?.rowIndex == 72)
    }

    @Test("An illegal call shows an error and leaves the rows untouched")
    func illegalCallLeavesRowsUntouched() async {
        let (presenter, spy, store) = makePresenter()
        presenter.start()
        await presenter.loadTask?.value
        let displaysBefore = spy.displayCallCount

        presenter.didTapCall(.bob, atRowIndex: 5) // row 5 is not a lead end

        #expect(!spy.errors.isEmpty)
        #expect(spy.displayCallCount == displaysBefore)
        #expect(store.updatedTouches.isEmpty)
    }

    @Test("Opening a document that throws shows an error, not an empty grid")
    func openFailureShowsError() async {
        let (presenter, spy, _) = makePresenter(openError: CocoaError(.fileReadNoSuchFile))
        presenter.start()
        await presenter.loadTask?.value

        #expect(!spy.errors.isEmpty)
        #expect(!spy.displayedRows.isEmpty) // the seed touch still rendered
    }

    @Test("A saving error sets the error indicator and reports it")
    func savingErrorIsReported() async {
        let (presenter, spy, store) = makePresenter()
        presenter.start()
        await presenter.loadTask?.value

        store.fire(.savingError)

        #expect(spy.saveIndicator == .error)
        #expect(!spy.errors.isEmpty)
    }

    @Test("A conflict presents its versions")
    func conflictPresentsVersions() async {
        let (presenter, spy, store) = makePresenter()
        store.versionsToReturn = [
            DocumentVersion(id: UUID(), title: "This device", detail: "today"),
            DocumentVersion(id: UUID(), title: "iPad", detail: "today")
        ]
        presenter.start()
        await presenter.loadTask?.value

        store.fire(.inConflict)

        #expect(spy.conflictVersions?.count == 2)
    }

    @Test("Deleting the document underneath the editor dismisses with a message")
    func deletionDismisses() async {
        let (presenter, spy, store) = makePresenter()
        presenter.start()
        await presenter.loadTask?.value

        store.fire(.closed)

        #expect(spy.dismissMessage != nil)
    }

    @Test("Playback reports its start and stop to the view")
    func playbackReportsState() async {
        let (presenter, spy, _) = makePresenter()
        presenter.start()
        await presenter.loadTask?.value

        presenter.didTapPlay()
        #expect(spy.isPlaying == true)

        presenter.didTapStop()
        #expect(spy.isPlaying == false)
    }
}
