//
//  Stage.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

import Foundation

/// The number of bells a composition is rung on.
///
/// Change ringing names each stage rather than referring to a bell count directly,
/// so the domain uses those names. Each stage knows how many bells it has and how
/// many rows make up a full extent (every possible row rung exactly once).
///
/// `Stage` is part of the Model layer. It is a pure value type with no knowledge of
/// UIKit or of any screen, which is why it is marked `nonisolated` and can be used
/// freely from tests running off the main actor.
nonisolated enum Stage: Int, CaseIterable, Sendable, Hashable {

    /// Five bells.
    case doubles = 5

    /// Six bells.
    case minor = 6

    /// Seven bells.
    case triples = 7

    /// Eight bells.
    case major = 8

    /// The number of bells at this stage.
    var bellCount: Int { rawValue }

    /// The traditional name of the stage, such as `"Minor"`.
    var name: String {
        switch self {
            case .doubles: return "Doubles"
            case .minor: return "Minor"
            case .triples: return "Triples"
            case .major: return "Major"
        }
    }

    /// The number of rows in a full extent: every distinct row rung exactly once.
    ///
    /// This is the factorial of the bell count, since an extent is every permutation
    /// of the bells. It is `120` for Doubles, `720` for Minor, `5040` for Triples,
    /// and `40320` for Major.
    var extentLength: Int {
        (1...bellCount).reduce(1, *)
    }

    /// The `Row` in which every bell sounds in order, from the treble to the tenor.
    ///
    /// Rounds is where every touch starts and ends. For Minor it is `123456`.
    var rounds: Row {
        Row(bells: Array(1...bellCount))
    }
}
