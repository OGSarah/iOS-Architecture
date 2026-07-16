import Foundation
import SwiftData

/// A finished match, persisted locally with SwiftData.
///
/// This is the only model type that imports SwiftData. The board layer
/// reports a plain ``MatchOutcome`` value upward, and the coordinator turns
/// it into a record and inserts it into the container.
@Model
final class MatchRecord {

    /// When the match ended.
    var date: Date

    /// The raw value of the ``OpponentKind`` that was faced.
    var opponentKind: String

    /// The display name of the winner.
    var winnerName: String

    /// The display name of the loser.
    var loserName: String

    /// The raw value of the ``WinReason`` the match ended with.
    var winReason: String

    /// The number of placements and movements in the match.
    var moveCount: Int

    /// The wall clock length of the match in seconds.
    var duration: TimeInterval

    /// Creates a record from its stored fields.
    init(
        date: Date,
        opponentKind: String,
        winnerName: String,
        loserName: String,
        winReason: String,
        moveCount: Int,
        duration: TimeInterval
    ) {
        self.date = date
        self.opponentKind = opponentKind
        self.winnerName = winnerName
        self.loserName = loserName
        self.winReason = winReason
        self.moveCount = moveCount
        self.duration = duration
    }

    /// Creates a record from the outcome a finished board reported.
    convenience init(outcome: MatchOutcome, date: Date = .now) {
        self.init(
            date: date,
            opponentKind: outcome.opponentKind.rawValue,
            winnerName: outcome.winnerName,
            loserName: outcome.loserName,
            winReason: outcome.reason.rawValue,
            moveCount: outcome.moveCount,
            duration: outcome.duration
        )
    }

    /// A one line summary of how the match ended, for the history list.
    var summary: String {
        "\(winnerName) beat \(loserName), \(reasonSummary), in \(moveCount) moves"
    }

    /// The human readable form of ``winReason``.
    var reasonSummary: String {
        WinReason(rawValue: winReason)?.summary ?? winReason
    }
}
