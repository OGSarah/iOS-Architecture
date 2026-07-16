import Foundation
import Observation

/// Presentation state for the immersive excavation space.
///
/// Holds the three sites, the one currently shown, and the board diagram the
/// in situ board renders. Dismissal is reported upward through
/// ``didRequestDismiss``; the ViewModel never touches a scene API.
@Observable
@MainActor
final class ExcavationViewModel {

    /// The sites the panel offers, in display order.
    let sites: [Excavation] = Excavation.all

    /// The site currently rendered around the user.
    private(set) var currentSite: Excavation

    /// The occupancy of the 24 points shown on the in situ board, usually the
    /// final position of the match that just ended.
    let boardPoints: [PlayerColor?]

    /// Reports that the user asked to leave the space. Assigned by the coordinator.
    var didRequestDismiss: (() -> Void)?

    /// Creates the ViewModel showing a given site and board diagram.
    init(siteID: Excavation.ID, boardPoints: [PlayerColor?]) {
        self.currentSite = Excavation.site(id: siteID)
        self.boardPoints = boardPoints
    }

    /// Switches the rendered site. A state change, not a scene transition, so
    /// the ViewModel owns it.
    func selectSite(id: Excavation.ID) {
        currentSite = Excavation.site(id: id)
    }

    /// Forwards the dismiss intent upward.
    func returnTapped() {
        didRequestDismiss?()
    }
}
