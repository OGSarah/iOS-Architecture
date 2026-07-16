import SwiftUI

/// The result of asking the system to open an immersive space, mirrored into
/// a UI framework free value so the coordinator and its tests never touch
/// SwiftUI's own result type.
nonisolated enum ImmersiveOpenResult: Equatable, Sendable {

    /// The space opened.
    case opened

    /// The person declined, or the system was showing something that blocked it.
    case userCancelled

    /// The space failed to open.
    case error
}

/// The seam between the coordinator and SwiftUI's scene actions.
///
/// The real implementation forwards to `openWindow`, `dismissWindow`,
/// `openImmersiveSpace`, and `dismissImmersiveSpace`. The test implementation
/// records the calls instead of performing them, which is what makes
/// navigation itself unit testable.
@MainActor
protocol SceneOpening {

    /// Opens the window scene with the given identifier.
    func openWindow(id: String)

    /// Dismisses the window scene with the given identifier.
    func dismissWindow(id: String)

    /// Opens the immersive space with the given identifier and reports how it went.
    func openImmersiveSpace(id: String) async -> ImmersiveOpenResult

    /// Dismisses the currently open immersive space, if any.
    func dismissImmersiveSpace() async
}

/// The production ``SceneOpening`` wrapping the four SwiftUI environment
/// action values.
///
/// Environment actions are only readable inside a view, so this type is
/// constructed by ``SceneOpenerInstaller`` on a scene root and handed to the
/// coordinator once.
struct RealSceneOpener: SceneOpening {

    let openWindowAction: OpenWindowAction
    let dismissWindowAction: DismissWindowAction
    let openImmersiveSpaceAction: OpenImmersiveSpaceAction
    let dismissImmersiveSpaceAction: DismissImmersiveSpaceAction

    func openWindow(id: String) {
        openWindowAction(id: id)
    }

    func dismissWindow(id: String) {
        dismissWindowAction(id: id)
    }

    func openImmersiveSpace(id: String) async -> ImmersiveOpenResult {
        switch await openImmersiveSpaceAction(id: id) {
        case .opened: .opened
        case .userCancelled: .userCancelled
        case .error: .error
        @unknown default: .error
        }
    }

    func dismissImmersiveSpace() async {
        await dismissImmersiveSpaceAction()
    }
}

/// Reads the scene actions from the environment of a scene root and installs
/// them on the coordinator, idempotently.
///
/// This modifier is the only place in the app that touches the environment
/// scene actions. Views forward intent to their ViewModels and never open
/// scenes themselves; that import is the smell this pattern exists to remove.
struct SceneOpenerInstaller: ViewModifier {

    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    /// The coordinator receiving the opener.
    let coordinator: AppCoordinator

    func body(content: Content) -> some View {
        content.onAppear {
            coordinator.attachSceneOpenerIfNeeded(
                RealSceneOpener(
                    openWindowAction: openWindow,
                    dismissWindowAction: dismissWindow,
                    openImmersiveSpaceAction: openImmersiveSpace,
                    dismissImmersiveSpaceAction: dismissImmersiveSpace
                )
            )
        }
    }
}

extension View {

    /// Installs the real scene opener on the coordinator when this scene appears.
    func installSceneOpener(_ coordinator: AppCoordinator) -> some View {
        modifier(SceneOpenerInstaller(coordinator: coordinator))
    }
}
