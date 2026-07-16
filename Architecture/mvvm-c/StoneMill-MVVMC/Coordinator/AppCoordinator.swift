import Foundation
import Observation
import SwiftData

/// The owner of navigation.
///
/// The coordinator decides which scenes exist, in what order, and how they
/// are presented. It creates every ViewModel, hands it its dependencies,
/// subscribes to its event closures, and performs every scene transition
/// through the injected ``SceneOpening`` seam. No view ever opens a scene,
/// and no ViewModel ever names another screen.
@Observable
@MainActor
final class AppCoordinator {

    /// What the app is currently showing. The single source of truth.
    private(set) var route: Route = .setup

    /// The navigation path of the setup window, coordinator owned so even in
    /// window pushes stay out of the views.
    var setupPath: [SetupDestination] = []

    /// The SwiftData container holding finished matches.
    let modelContainer: ModelContainer

    /// The ViewModel behind the currently open board volume, if any.
    private(set) var activeBoardViewModel: BoardViewModel?

    /// The ViewModel behind the currently open immersive space, if any.
    private(set) var activeExcavationViewModel: ExcavationViewModel?

    private var sceneOpener: (any SceneOpening)?
    private var lastFinishedState: GameState?

    /// Dismissals the coordinator performed itself, so the matching
    /// `onDisappear` does not get mistaken for the user closing the scene.
    private var expectedDismissals: [SceneID] = []
    #if DEBUG
    private var appliedScenario = false
    #endif

    /// Creates the coordinator.
    ///
    /// The production app installs the real scene opener later, from the first
    /// scene root that appears. Tests inject a spy here instead.
    init(modelContainer: ModelContainer, sceneOpener: (any SceneOpening)? = nil) {
        self.modelContainer = modelContainer
        self.sceneOpener = sceneOpener
    }

    /// Accepts the scene opener from the first scene root that appears.
    /// Later installs are ignored, so any scene may safely be first.
    func attachSceneOpenerIfNeeded(_ opener: any SceneOpening) {
        guard sceneOpener == nil else { return }
        sceneOpener = opener
    }

    // MARK: ViewModel factories

    /// Builds the setup ViewModel and wires its events to the flows below.
    func makeSetupViewModel() -> SetupViewModel {
        let viewModel = SetupViewModel()
        viewModel.didStartMatch = { [weak self] configuration in
            self?.startMatch(configuration)
        }
        viewModel.didSelectHistory = { [weak self] in
            self?.showHistory()
        }
        return viewModel
    }

    /// Builds the history ViewModel on the container's main context.
    func makeMatchHistoryViewModel() -> MatchHistoryViewModel {
        MatchHistoryViewModel(modelContext: modelContainer.mainContext)
    }

    /// Builds the excavation ViewModel for a site, showing the final position
    /// of the last finished match, or a canonical mid game diagram.
    func makeExcavationViewModel(siteID: Excavation.ID) -> ExcavationViewModel {
        let viewModel = ExcavationViewModel(
            siteID: siteID,
            boardPoints: lastFinishedState?.points ?? Self.canonicalBoardPoints
        )
        viewModel.didRequestDismiss = { [weak self] in
            Task { await self?.dismissExcavation() }
        }
        return viewModel
    }

    // MARK: Flows

    /// Starts a match: builds the board ViewModel, routes to it, and opens the
    /// board volume.
    func startMatch(_ configuration: MatchConfiguration, fixture: GameState? = nil) {
        let state = fixture ?? .initial()
        let viewModel = BoardViewModel(configuration: configuration, initialState: state)
        viewModel.didFinishMatch = { [weak self] outcome in
            self?.boardDidFinish(outcome)
        }
        viewModel.didRequestExcavation = { [weak self] in
            Task { await self?.showExcavation() }
        }
        activeBoardViewModel = viewModel
        route = .board(state.id)
        sceneOpener?.openWindow(id: SceneID.board.rawValue)
    }

    /// Pushes the finished match list inside the setup window.
    func showHistory() {
        if setupPath.last != .history {
            setupPath.append(.history)
        }
    }

    /// Persists the outcome of a finished match.
    ///
    /// The volume stays open showing the results card; visiting the
    /// excavation afterwards is the player's choice.
    func boardDidFinish(_ outcome: MatchOutcome) {
        lastFinishedState = activeBoardViewModel?.gameState
        let record = MatchRecord(outcome: outcome)
        modelContainer.mainContext.insert(record)
        try? modelContainer.mainContext.save()
    }

    /// Opens the immersive excavation space.
    ///
    /// Opening is async and can be denied, and the system allows only one
    /// immersive space at a time. The board volume is dismissed before the
    /// space opens. On `.userCancelled` or `.error` the route is left
    /// unchanged and the volume is reopened, so the user keeps the scene they
    /// were in rather than being stranded.
    func showExcavation(siteID: Excavation.ID = Excavation.all[0].id) async {
        guard let sceneOpener else { return }
        if case .excavation = route {
            await sceneOpener.dismissImmersiveSpace()
        }
        var cameFromBoard = false
        if case .board = route {
            cameFromBoard = true
            expectedDismissals.append(.board)
            sceneOpener.dismissWindow(id: SceneID.board.rawValue)
        }
        activeExcavationViewModel = makeExcavationViewModel(siteID: siteID)
        switch await sceneOpener.openImmersiveSpace(id: SceneID.excavation.rawValue) {
        case .opened:
            route = .excavation(siteID)
        case .userCancelled, .error:
            activeExcavationViewModel = nil
            if cameFromBoard {
                sceneOpener.openWindow(id: SceneID.board.rawValue)
            }
        }
    }

    /// Leaves the excavation space and returns to the setup window.
    func dismissExcavation() async {
        guard let sceneOpener else { return }
        expectedDismissals.append(.excavation)
        await sceneOpener.dismissImmersiveSpace()
        activeExcavationViewModel = nil
        route = .setup
        sceneOpener.openWindow(id: SceneID.setup.rawValue)
    }

    /// Reconciles the route when the user closes a scene from outside the
    /// app, with the window's close control or the Digital Crown.
    ///
    /// Called from `onDisappear` of the board and excavation roots so the
    /// coordinator never believes a scene is open that the system has closed.
    func handleSceneDisappeared(_ sceneID: SceneID) {
        if let index = expectedDismissals.firstIndex(of: sceneID) {
            expectedDismissals.remove(at: index)
            return
        }
        switch sceneID {
        case .board:
            if case .board = route {
                route = .setup
                activeBoardViewModel = nil
            }
        case .excavation:
            if case .excavation = route {
                route = .setup
                activeExcavationViewModel = nil
            }
        case .setup:
            break
        }
    }

    /// A pleasant mid game position for the in situ board when no match
    /// preceded the excavation visit.
    static let canonicalBoardPoints: [PlayerColor?] = {
        var points = [PlayerColor?](repeating: nil, count: Board.pointCount)
        for point in [0, 1, 2, 12, 17] { points[point] = .light }
        for point in [5, 8, 10, 19, 21] { points[point] = .dark }
        return points
    }()

    /// Seeds the scenario named in the `UITEST_SCENARIO` launch environment.
    ///
    /// Called once from the setup scene's first appearance. Does nothing in
    /// release builds, so UI tests and screenshot runs can start deep inside
    /// a flow without shipping the fixtures.
    func applyUITestScenarioIfNeeded() {
        #if DEBUG
        guard !appliedScenario, let scenario = UITestScenario.current else { return }
        appliedScenario = true
        switch scenario {
        case .freshSetup:
            break
        case .midPlacing, .flying, .oneMoveToWin, .matchOver:
            startMatch(GameState.fixtureConfiguration, fixture: GameState.fixture(for: scenario))
        case .excavationKurna:
            lastFinishedState = GameState.fixture(for: scenario)
            Task { await showExcavation(siteID: Excavation.kurna.id) }
        case .excavationCloister:
            lastFinishedState = GameState.fixture(for: scenario)
            Task { await showExcavation(siteID: Excavation.cloister.id) }
        }
        #endif
    }
}
