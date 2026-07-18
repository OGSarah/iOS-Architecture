//
//  TouchEditorPresenter.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

import Foundation

/// The presenter for the touch editor: the only type that knows both the domain and the
/// screen.
///
/// It holds the current `Touch`, asks the `RingingEngine` to expand it, asks the
/// `TruthChecker` whether it is still true, formats the rows into display values, decides
/// which bell the blue line follows, and then issues commands to the view. It also owns the
/// document lifecycle: opening is asynchronous and can fail, autosave happens on the
/// system's schedule, and conflicts arrive unprompted, so the presenter, not the view,
/// decides what the user sees for each of those.
///
/// It talks to the view only through the `TouchEditorView` protocol and to the document only
/// through `DocumentStoring`. It has never heard of `UIViewController`, which is exactly why
/// it can be tested with two stubs and no simulator.
@MainActor
final class TouchEditorPresenter {

    /// The passive view this presenter commands. Held weakly to avoid a retain cycle.
    weak var view: TouchEditorView?

    /// The document seam. The presenter's only window onto opening, saving, and conflicts.
    private let store: DocumentStoring

    /// The playback helper that rings the current rows through the audio engine.
    private let playback: PlaybackPresenter

    /// The touch currently being edited. Committed only after the engine accepts it.
    private var touch: Touch

    /// The last rows the engine produced for the committed touch.
    private var rows: [Row] = []

    /// The bell the blue line traces through the grid. Bell two is the usual choice.
    private var blueLineBell = 2

    /// The in-flight open task, exposed read-only so tests can await the open completing.
    private(set) var loadTask: Task<Void, Never>?

    /// Whether the document has finished opening, so edits are safe to persist.
    private var isOpen = false

    /// Creates the presenter with its two injected seams.
    ///
    /// - Parameters:
    ///   - store: The document seam to load from and save to.
    ///   - audio: The bell-ringing seam used for playback. Defaults to a silent stub so a
    ///     presenter built in a test makes no sound.
    init(store: DocumentStoring, audio: BellRinging) {
        self.store = store
        self.touch = store.touch
        self.playback = PlaybackPresenter(audio: audio)

        store.stateChanged = { [weak self] state in
            self?.handle(documentState: state)
        }
        playback.onHighlight = { [weak self] rowIndex in
            self?.view?.setPlaybackHighlight(rowIndex: rowIndex)
        }
        playback.onPlayingChanged = { [weak self] isPlaying in
            self?.view?.setPlaying(isPlaying)
        }
    }

    // MARK: Lifecycle

    /// Prepares the screen and opens the document.
    ///
    /// The view controller calls this once its view is ready. The presenter owns the loading
    /// state: the view controller has no `Task` in it and does not know that opening a file
    /// takes time.
    func start() {
        view?.setTitle(touch.method.name)
        view?.setNotation(PlaceNotation.string(from: touch.method.plainLead))
        view?.setSaveIndicator(.saved)
        render()

        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await self.store.open()
                self.isOpen = true
                self.touch = self.store.touch
                self.render()
            } catch {
                self.view?.showError("This composition could not be opened.")
            }
        }
    }

    /// Closes the document when the editor goes away.
    func stop() {
        playback.stop()
        Task { await store.close() }
    }

    // MARK: User intent

    /// Handles a tap on the call strip, placing a call at a row.
    ///
    /// The presenter builds a candidate touch, hands it to the engine, and only commits if
    /// the engine accepts it. An illegal call, one placed anywhere but a lead end, leaves the
    /// rows exactly as they were and shows a message, which is the behaviour the tests pin.
    ///
    /// - Parameters:
    ///   - call: The call to place.
    ///   - rowIndex: The row the user tapped.
    func didTapCall(_ call: Call, atRowIndex rowIndex: Int) {
        let candidate = touch.placing(call, atRowIndex: rowIndex)
        switch RingingEngine.expand(candidate) {
            case .failure(.callNotAtLeadEnd):
                view?.showError("A call can only be placed at a lead end.")
            case .failure(.malformedNotation):
                view?.showError("This method's notation is not valid.")
            case .success(let newRows):
                commit(touch: candidate, rows: newRows)
        }
    }

    /// Handles an edit to the place notation in the notation bar.
    ///
    /// A valid notation rebuilds the method and regenerates every row. An invalid one is
    /// rejected with a message and leaves the current method untouched.
    ///
    /// - Parameter notation: The edited notation string.
    func didEditNotation(_ notation: String) {
        guard let changes = try? PlaceNotation.parse(notation), !changes.isEmpty else {
            view?.showError("That place notation could not be read.")
            view?.setNotation(PlaceNotation.string(from: touch.method.plainLead))
            return
        }
        let method = Method(
            name: touch.method.name,
            stage: touch.method.stage,
            plainLead: changes,
            bobLeadEnd: touch.method.bobLeadEnd,
            singleLeadEnd: touch.method.singleLeadEnd
        )
        var candidate = touch
        candidate.method = method
        candidate.calls = [:]

        switch RingingEngine.expand(candidate) {
            case .failure:
                view?.showError("That method could not be rung at this stage.")
                view?.setNotation(PlaceNotation.string(from: touch.method.plainLead))
            case .success(let newRows):
                commit(touch: candidate, rows: newRows)
        }
    }

    /// Selects the bell the blue line traces, then redraws the grid.
    ///
    /// - Parameter bell: The bell to follow.
    func didSelectBlueLineBell(_ bell: Int) {
        guard (1...touch.method.stage.bellCount).contains(bell) else { return }
        blueLineBell = bell
        render()
    }

    /// Replaces the whole method, for example when one is chosen from the picker.
    ///
    /// Changing the method clears the calls, since a call's row index is only meaningful for
    /// the method it was placed in. The new method is regenerated and its title and notation
    /// pushed to the view.
    ///
    /// - Parameter method: The method to ring.
    func didSelectMethod(_ method: Method) {
        var candidate = touch
        candidate.method = method
        candidate.calls = [:]
        candidate.maxLeads = method.stage.extentLength / method.leadLength + 2

        guard case .success(let newRows) = RingingEngine.expand(candidate) else {
            view?.showError("That method could not be rung.")
            return
        }
        view?.setTitle(method.name)
        view?.setNotation(PlaceNotation.string(from: method.plainLead))
        commit(touch: candidate, rows: newRows)
    }

    /// Starts playing the current rows through the bells at a ringing pace.
    func didTapPlay() {
        playback.play(rows: rows, stage: touch.method.stage)
    }

    /// Stops playback.
    func didTapStop() {
        playback.stop()
    }

    /// Resolves a document conflict by keeping the chosen version.
    ///
    /// - Parameter version: The version the user picked.
    func didResolveConflict(with version: DocumentVersion) {
        Task {
            await store.resolveConflict(keeping: version)
            touch = store.touch
            render()
        }
    }

    // MARK: Private

    /// Commits an accepted touch: stores it, remembers its rows, and redraws.
    private func commit(touch newTouch: Touch, rows newRows: [Row]) {
        touch = newTouch
        rows = newRows
        if isOpen {
            store.update(touch: newTouch)
            view?.setSaveIndicator(.saving)
        }
        render()
    }

    /// Expands the committed touch if needed, formats every row, and issues the draw
    /// commands, including the truth banner.
    private func render() {
        if rows.isEmpty, case .success(let expanded) = RingingEngine.expand(touch) {
            rows = expanded
        }

        let editorRows = rows.enumerated().map { index, row in
            EditorRow(
                index: index,
                notation: row.notation,
                callSymbol: touch.calls[index]?.symbol ?? "",
                isLeadEnd: touch.isLeadEnd(rowIndex: index),
                blueLineColumn: (row.bells.firstIndex(of: blueLineBell)).map { $0 + 1 }
            )
        }
        view?.display(rows: editorRows)

        let report = TruthChecker.check(rows)
        if let falseIndex = report.firstFalseRowIndex {
            let notation = rows[falseIndex].notation
            view?.showTruthFailure(
                at: falseIndex,
                message: "Row \(falseIndex), \(notation), repeats an earlier row."
            )
        } else {
            view?.clearTruthFailure()
        }
    }

    /// Reacts to a document state change reported on the system's schedule.
    private func handle(documentState state: DocumentState) {
        switch state {
            case .normal:
                view?.setSaveIndicator(.saved)
            case .editingDisabled:
                view?.setSaveIndicator(.saving)
            case .savingError:
                view?.setSaveIndicator(.error)
                view?.showError("This composition could not be saved.")
            case .inConflict:
                view?.showConflict(versions: store.conflictVersions())
            case .closed:
                view?.dismissWithMessage("This composition was removed.")
        }
    }
}
