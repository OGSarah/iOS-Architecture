import Foundation
import Observation

/// Presentation state for the setup window: opponent choice, player names,
/// and the rules primer.
///
/// The ViewModel validates the configuration and reports upward through
/// ``didStartMatch`` when the user starts a match. It has no idea which scene
/// comes next; the coordinator decides that.
@Observable
@MainActor
final class SetupViewModel {

    /// The kind of opponent the user picked. Choosing the computer locks the
    /// dark player's name to the engine's name.
    var opponentKind: OpponentKind = .hotSeat {
        didSet {
            if opponentKind == .computer {
                darkPlayerName = MatchConfiguration.computerName
            } else if darkPlayerName == MatchConfiguration.computerName {
                darkPlayerName = ""
            }
        }
    }

    /// The light player's display name.
    var lightPlayerName: String = ""

    /// The dark player's display name, fixed while playing the engine.
    var darkPlayerName: String = ""

    /// Whether the rules primer disclosure is expanded.
    var isRulesPrimerPresented = false

    /// Reports a validated configuration upward. Assigned by the coordinator.
    var didStartMatch: ((MatchConfiguration) -> Void)?

    /// Reports that the user asked for the match history. Assigned by the coordinator.
    var didSelectHistory: (() -> Void)?

    /// Why the current configuration cannot start, or nil when it can.
    var validationMessage: String? {
        if trimmedLightName.isEmpty {
            return "The light player needs a name."
        }
        if opponentKind == .hotSeat {
            if trimmedDarkName.isEmpty {
                return "The dark player needs a name."
            }
            if trimmedLightName.caseInsensitiveCompare(trimmedDarkName) == .orderedSame {
                return "The players need different names."
            }
        }
        return nil
    }

    /// Whether the Start button is enabled.
    var canStart: Bool {
        validationMessage == nil
    }

    /// Validates the configuration and reports it upward.
    func startTapped() {
        guard canStart else { return }
        let configuration = MatchConfiguration(
            opponentKind: opponentKind,
            lightPlayerName: trimmedLightName,
            darkPlayerName: opponentKind == .computer ? MatchConfiguration.computerName : trimmedDarkName
        )
        didStartMatch?(configuration)
    }

    /// Forwards the history intent upward.
    func historyTapped() {
        didSelectHistory?()
    }

    private var trimmedLightName: String {
        lightPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedDarkName: String {
        darkPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
