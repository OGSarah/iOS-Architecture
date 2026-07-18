//
//  TestHelpers.swift
//  ChangeRinger-MVPTests
//
//  Created by Sarah Clark on 7/17/26.
//

import Foundation
@testable import ChangeRinger_MVP

/// A silent stand-in for the bell audio, so the playback presenter can be driven in tests
/// without any audio hardware. It records what it was asked to ring.
@MainActor
final class SilentBells: BellRinging {

    /// The bells struck, in order, as `(bell, stage)` pairs.
    private(set) var struck: [(bell: Int, stage: Stage)] = []

    /// The number of times the engine was prepared.
    private(set) var prepareCount = 0

    /// The number of times playback was stopped.
    private(set) var stopCount = 0

    func prepare(for stage: Stage) { prepareCount += 1 }

    func strike(bell: Int, of stage: Stage) { struck.append((bell, stage)) }

    func stopAll() { stopCount += 1 }
}

/// Builds every permutation of `1...bellCount` as rows, for exercising the truth checker at
/// the scale of a full extent without needing a rung composition.
///
/// - Parameter bellCount: The number of bells.
/// - Returns: All `bellCount!` rows, in lexicographic order.
nonisolated func allRows(bellCount: Int) -> [Row] {
    func permute(_ values: [Int]) -> [[Int]] {
        guard values.count > 1 else { return [values] }
        var result: [[Int]] = []
        for (index, value) in values.enumerated() {
            var rest = values
            rest.remove(at: index)
            for tail in permute(rest) {
                result.append([value] + tail)
            }
        }
        return result
    }
    return permute(Array(1...bellCount)).map(Row.init(bells:))
}
