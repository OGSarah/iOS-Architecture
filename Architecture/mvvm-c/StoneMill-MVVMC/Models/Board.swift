//
//  Board.swift
//  StoneMill-MVVMC
//
//  Created by Sarah Clark on 7/16/26.
//

import Foundation
import simd

/// The static geometry of a Nine Men's Morris board.
///
/// The board is 24 points arranged as three concentric square rings connected
/// by four spokes through the midpoints of their sides. Points are indexed as
/// `ring * 8 + slot`, where ring 0 is the outer square, ring 2 is the inner
/// square, and slots run clockwise from the north-west corner:
///
/// ```
/// slot 0: NW corner   slot 1: N midpoint   slot 2: NE corner   slot 3: E midpoint
/// slot 4: SE corner   slot 5: S midpoint   slot 6: SW corner   slot 7: W midpoint
/// ```
///
/// Adjacency and the 16 mill lines are derived from that indexing rather than
/// hand written, so a single scheme drives the rules, the tabletop layout, and
/// the immersive rendering.
nonisolated enum Board {

    /// The number of points on the board.
    static let pointCount = 24

    /// The number of concentric square rings.
    static let ringCount = 3

    /// The number of slots on each ring.
    static let slotsPerRing = 8

    /// The number of pieces each player starts with.
    static let piecesPerPlayer = 9

    /// The valid range of point indices.
    static let allPoints = 0..<pointCount

    /// The half width of the outer ring in meters, used by ``layoutPosition(of:)``.
    static let boardRadius: Float = 0.18

    /// The ring (0 outer, 1 middle, 2 inner) that contains a point.
    static func ring(of point: Int) -> Int { point / slotsPerRing }

    /// The clockwise slot (0 through 7, starting at the north-west corner) of a point within its ring.
    static func slot(of point: Int) -> Int { point % slotsPerRing }

    /// Whether a slot is a side midpoint. Midpoints are the only points that connect neighboring rings.
    static func isMidpoint(slot: Int) -> Bool { slot % 2 == 1 }

    /// The neighbors of every point, indexed by point.
    ///
    /// Within a ring, each slot connects to the slots on either side of it.
    /// Across rings, each midpoint slot connects to the same slot on the
    /// neighboring ring. Corners therefore have 2 neighbors, outer and inner
    /// midpoints have 3, and middle ring midpoints have 4.
    static let adjacency: [[Int]] = {
        var neighbors = Array(repeating: [Int](), count: pointCount)
        for point in allPoints {
            let r = ring(of: point)
            let s = slot(of: point)
            neighbors[point].append(r * slotsPerRing + (s + 1) % slotsPerRing)
            neighbors[point].append(r * slotsPerRing + (s + slotsPerRing - 1) % slotsPerRing)
            if isMidpoint(slot: s) {
                if r > 0 { neighbors[point].append((r - 1) * slotsPerRing + s) }
                if r < ringCount - 1 { neighbors[point].append((r + 1) * slotsPerRing + s) }
            }
        }
        return neighbors.map { $0.sorted() }
    }()

    /// The 16 mill lines of the board, each an array of three point indices.
    ///
    /// Every ring contributes its four sides (12 mills), and each of the four
    /// spokes that join the rings at their midpoints contributes one more.
    static let mills: [[Int]] = {
        var lines: [[Int]] = []
        for r in 0..<ringCount {
            let base = r * slotsPerRing
            for corner in stride(from: 0, to: slotsPerRing, by: 2) {
                lines.append([base + corner, base + (corner + 1) % slotsPerRing, base + (corner + 2) % slotsPerRing])
            }
        }
        for midpoint in stride(from: 1, to: slotsPerRing, by: 2) {
            lines.append([midpoint, slotsPerRing + midpoint, 2 * slotsPerRing + midpoint])
        }
        return lines
    }()

    /// The mills that pass through a given point.
    static func mills(containing point: Int) -> [[Int]] {
        mills.filter { $0.contains(point) }
    }

    /// Whether two points are connected by a line on the board.
    static func isAdjacent(_ a: Int, _ b: Int) -> Bool {
        allPoints.contains(a) && adjacency[a].contains(b)
    }

    /// The physical position of a point on the board surface, in meters.
    ///
    /// The result is an offset from the board center in the board's own plane:
    /// `x` grows to the east and `y` grows to the south, matching RealityKit's
    /// x and z axes for a board lying flat. This single function feeds both the
    /// tabletop equipment layout and the immersive in-situ board, and is pinned
    /// by the geometry tests so a layout tweak cannot silently move the rules.
    static func layoutPosition(of point: Int) -> SIMD2<Float> {
        let ringHalfWidths: [Float] = [boardRadius, boardRadius * 2 / 3, boardRadius / 3]
        let unitOffsets: [SIMD2<Float>] = [
            SIMD2(-1, -1), SIMD2(0, -1), SIMD2(1, -1), SIMD2(1, 0),
            SIMD2(1, 1), SIMD2(0, 1), SIMD2(-1, 1), SIMD2(-1, 0),
        ]
        return unitOffsets[slot(of: point)] * ringHalfWidths[ring(of: point)]
    }
}
