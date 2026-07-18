//
//  TouchEditorViewController.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

import UIKit

/// The passive editor screen, and the app's document lifecycle entry point.
///
/// It is a `UIDocumentViewController`, so the system hands it a document and calls
/// `documentDidOpen()`. From there it conforms to `TouchEditorView` and implements every
/// command literally: `display(rows:)` reloads the grid, `showTruthFailure(at:message:)`
/// shows the banner, `setSaveIndicator(_:)` sets an image. There is no branching on domain
/// state in this file. User actions go straight out to the presenter, which owns every
/// decision about what the screen shows.
///
/// The editor's own controls live in a control bar inside the view rather than in the
/// navigation bar, because the document view controller manages its navigation bar heavily.
/// Keeping the controls in the view makes them predictable and keeps this class passive.
final class TouchEditorViewController: UIDocumentViewController {

    /// The presenter, created once a document has opened.
    private var presenter: TouchEditorPresenter?

    /// The lead-end row the user has selected for a call, if any.
    private var selectedLeadEnd: Int?

    /// Whether the editor has already been wired up, so it happens only once.
    private var isEditorConfigured = false

    /// Whether playback is currently running, tracked to toggle the play control.
    private var isPlaying = false

    // MARK: Views

    private let controlBar = UIView()
    private let methodButton = UIButton(configuration: .plain())
    private let traceButton = UIButton(configuration: .plain())
    private let playButton = UIButton(configuration: .plain())
    private let saveButton = UIButton(configuration: .plain())
    private let gridView = RowGridView()
    private let notationBar = NotationBarView()
    private let callStrip = CallStripView()
    private let truthBanner = TruthBannerView()

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.navy
        setUpControlBar()
        setUpLayout()
        wireCallbacks()

        #if DEBUG
        // Seeded UI-test runs open a real, saved document directly, bypassing the system
        // document browser. Setting the document suppresses the launch scene, so the editor
        // is fully interactive, unlike a bare launch container.
        if let scenario = UITestScenario.current {
            seedAndOpenDocument(with: scenario.makeTouch())
            return
        }
        #endif

        configureLaunchScene()
    }

    #if DEBUG
    /// Saves and opens a temporary document for a seeded UI-test run, then wires the editor.
    ///
    /// - Parameter touch: The fixture touch to seed the document with.
    private func seedAndOpenDocument(with touch: Touch) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("UITest-\(UUID().uuidString).touch")
        let document = TouchDocument(fileURL: url)
        document.touch = touch
        title = touch.method.name

        Task { @MainActor in
            _ = await document.save(to: url, for: .forCreating)
            _ = await document.open()
            self.document = document
            self.configureEditor(with: LiveDocumentStore(document: document), bellCount: touch.method.stage.bellCount)
        }
    }
    #endif

    override func documentDidOpen() {
        guard let document = document as? TouchDocument else { return }
        configureEditor(with: LiveDocumentStore(document: document), bellCount: document.touch.method.stage.bellCount)
    }

    // MARK: Setup

    /// Builds the control bar's buttons and their identifiers.
    private func setUpControlBar() {
        controlBar.backgroundColor = Theme.navyElevated

        configure(methodButton, title: "Method", identifier: AccessibilityID.Editor.methodButton)
        configure(traceButton, title: "Trace 2", identifier: AccessibilityID.Editor.blueLineControl)
        configure(playButton, image: "play.fill", identifier: AccessibilityID.Editor.playButton, label: "Play")

        configure(saveButton, image: "checkmark.icloud", identifier: AccessibilityID.Editor.saveIndicator, label: "Saved")
        saveButton.isUserInteractionEnabled = false

        methodButton.addAction(UIAction { [weak self] _ in self?.presentMethodPicker() }, for: .primaryActionTriggered)
        playButton.addAction(UIAction { [weak self] _ in self?.togglePlayback() }, for: .primaryActionTriggered)
        traceButton.showsMenuAsPrimaryAction = true

        let stack = UIStackView(arrangedSubviews: [methodButton, traceButton, UIView(), saveButton, playButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        controlBar.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: controlBar.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: controlBar.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: controlBar.topAnchor, constant: 6),
            stack.bottomAnchor.constraint(equalTo: controlBar.bottomAnchor, constant: -6)
        ])
    }

    /// Applies the shared styling to a control-bar button.
    private func configure(_ button: UIButton, title: String? = nil, image: String? = nil, identifier: String, label: String? = nil) {
        var configuration = button.configuration ?? .plain()
        configuration.title = title
        if let image { configuration.image = UIImage(systemName: image) }
        configuration.baseForegroundColor = Theme.gold
        button.configuration = configuration
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.accessibilityIdentifier = identifier
        if let label { button.accessibilityLabel = label }
        button.setContentHuggingPriority(.required, for: .horizontal)
    }

    /// Lays out the control bar, grid, notation bar, call strip, and truth banner.
    private func setUpLayout() {
        [controlBar, gridView, notationBar, callStrip, truthBanner].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            controlBar.topAnchor.constraint(equalTo: guide.topAnchor),
            controlBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            gridView.topAnchor.constraint(equalTo: controlBar.bottomAnchor),
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: notationBar.topAnchor),

            notationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            notationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            notationBar.bottomAnchor.constraint(equalTo: callStrip.topAnchor),

            callStrip.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            callStrip.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            callStrip.bottomAnchor.constraint(equalTo: guide.bottomAnchor),

            truthBanner.topAnchor.constraint(equalTo: controlBar.bottomAnchor, constant: 8),
            truthBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            truthBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    /// Configures the document launch scene shown before a document opens.
    private func configureLaunchScene() {
        launchOptions.title = "ChangeRinger"
        launchOptions.background.backgroundColor = Theme.navy
        launchOptions.browserViewController.delegate = self
    }

    /// Wires each passive view's raw callbacks to the presenter.
    private func wireCallbacks() {
        gridView.onSelectLeadEnd = { [weak self] index in
            guard let self else { return }
            self.selectedLeadEnd = index
            self.gridView.setSelectedRow(index)
            self.callStrip.setEnabled(true)
        }
        callStrip.onCall = { [weak self] call in
            guard let self, let index = self.selectedLeadEnd else { return }
            self.presenter?.didTapCall(call, atRowIndex: index)
        }
        notationBar.onCommit = { [weak self] notation in
            self?.presenter?.didEditNotation(notation)
        }
    }

    /// Builds the presenter over a store and starts it. Runs at most once.
    ///
    /// - Parameters:
    ///   - store: The document seam to drive.
    ///   - bellCount: The number of bells, used to build the trace menu.
    private func configureEditor(with store: DocumentStoring, bellCount: Int) {
        guard !isEditorConfigured else { return }
        isEditorConfigured = true

        let presenter = TouchEditorPresenter(store: store, audio: BellAudioEngine())
        presenter.view = self
        self.presenter = presenter
        updateTraceMenu(bellCount: bellCount)
        presenter.start()

        #if DEBUG
        // In the conflict UI-test scenario, surface the conflict sheet once the editor is up
        // so the flow and its screenshot can be exercised without a second real device.
        if UITestScenario.current == .conflict {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(600))
                self.showConflict(versions: UITestScenario.sampleConflictVersions)
            }
        }
        #endif
    }

    /// Rebuilds the trace menu so the user can pick which bell the blue line follows.
    private func updateTraceMenu(bellCount: Int) {
        let actions = (1...bellCount).map { bell in
            UIAction(title: "Bell \(bell)") { [weak self] _ in
                self?.presenter?.didSelectBlueLineBell(bell)
                self?.traceButton.configuration?.title = "Trace \(bell)"
            }
        }
        traceButton.menu = UIMenu(title: "Trace bell", children: actions)
    }

    // MARK: Actions

    /// Presents the method picker modally.
    private func presentMethodPicker() {
        let pickerPresenter = MethodPickerPresenter { [weak self] method in
            self?.presenter?.didSelectMethod(method)
        }
        let picker = MethodPickerViewController(presenter: pickerPresenter)
        let navigation = UINavigationController(rootViewController: picker)
        present(navigation, animated: true)
    }

    /// Toggles between playing and stopping the touch.
    private func togglePlayback() {
        if isPlaying {
            presenter?.didTapStop()
        } else {
            presenter?.didTapPlay()
        }
    }

    /// Shows a brief message that fades away on its own, used for transient errors.
    ///
    /// - Parameter message: The message to flash.
    fileprivate func flashMessage(_ message: String) {
        let label = PaddedLabel()
        label.text = message
        label.font = Theme.font(.subheadline)
        label.textColor = Theme.navy
        label.backgroundColor = Theme.gold
        label.numberOfLines = 0
        label.textAlignment = .center
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityTraits = .staticText
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: callStrip.topAnchor, constant: -16),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])

        UIAccessibility.post(notification: .announcement, argument: message)

        UIView.animate(withDuration: 0.3, delay: 1.8, options: []) {
            label.alpha = 0
        } completion: { _ in
            label.removeFromSuperview()
        }
    }
}

extension TouchEditorViewController: TouchEditorView {

    func display(rows: [EditorRow]) {
        gridView.setRows(rows)
    }

    func showTruthFailure(at rowIndex: Int, message: String) {
        gridView.setFalseRow(rowIndex)
        truthBanner.show(message: message)
    }

    func clearTruthFailure() {
        gridView.setFalseRow(nil)
        truthBanner.hide()
    }

    func setSaveIndicator(_ indicator: SaveIndicator) {
        switch indicator {
            case .saved:
                saveButton.configuration?.image = UIImage(systemName: "checkmark.icloud")
                saveButton.configuration?.baseForegroundColor = Theme.gold
                saveButton.accessibilityLabel = "Saved"
            case .saving:
                saveButton.configuration?.image = UIImage(systemName: "icloud.and.arrow.up")
                saveButton.configuration?.baseForegroundColor = Theme.gold
                saveButton.accessibilityLabel = "Saving"
            case .error:
                saveButton.configuration?.image = UIImage(systemName: "exclamationmark.icloud")
                saveButton.configuration?.baseForegroundColor = Theme.falseRow
                saveButton.accessibilityLabel = "Save failed"
        }
    }

    func setNotation(_ notation: String) {
        notationBar.setNotation(notation)
    }

    func setTitle(_ title: String) {
        self.title = title
        navigationItem.title = title
    }

    func showConflict(versions: [DocumentVersion]) {
        let alert = UIAlertController(
            title: "Resolve Conflict",
            message: "Two versions of this composition exist. Choose which one to keep.",
            preferredStyle: .actionSheet
        )
        for version in versions {
            alert.addAction(UIAlertAction(title: "\(version.title): \(version.detail)", style: .default) {
                [weak self] _ in
                self?.presenter?.didResolveConflict(with: version)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.popoverPresentationController?.sourceView = saveButton
        present(alert, animated: true)
    }

    func dismissWithMessage(_ message: String) {
        let alert = UIAlertController(title: "Composition Removed", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func setPlaybackHighlight(rowIndex: Int?) {
        gridView.setPlaybackRow(rowIndex)
    }

    func setPlaying(_ isPlaying: Bool) {
        self.isPlaying = isPlaying
        playButton.configuration?.image = UIImage(systemName: isPlaying ? "stop.fill" : "play.fill")
        playButton.accessibilityLabel = isPlaying ? "Stop" : "Play"
    }

    func showError(_ message: String) {
        flashMessage(message)
    }
}

extension TouchEditorViewController: UIDocumentBrowserViewControllerDelegate {

    /// Creates a new empty composition when the user asks for one from the browser.
    ///
    /// In a UI-test run the new document is seeded with the scenario's fixture so a test does
    /// not have to build a composition by tapping.
    func documentBrowser(
        _ controller: UIDocumentBrowserViewController,
        didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void
    ) {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Untitled.touch")
        let document = TouchDocument(fileURL: url)

        #if DEBUG
        if let scenario = UITestScenario.current {
            document.touch = scenario.makeTouch()
        }
        #endif

        Task { @MainActor in
            let saved = await document.save(to: url, for: .forCreating)
            await document.close()
            importHandler(saved ? url : nil, saved ? .move : .none)
        }
    }
}

/// A label with a small inset, used for the transient flash message.
private final class PaddedLabel: UILabel {

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + 32, height: size.height + 20)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.insetBy(dx: 16, dy: 10))
    }
}
