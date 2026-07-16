import Foundation
import Testing
@testable import StoneMill_MVVMC

/// Pins the derived board geometry: adjacency, the 16 mills, and the physical
/// layout the tabletop and the immersive board both draw from. A layout tweak
/// cannot silently break the rules while these hold.
struct BoardGeometryTests {

    // MARK: Structure

    @Test func boardHasTwentyFourPoints() {
        #expect(Board.pointCount == 24)
        #expect(Board.adjacency.count == 24)
    }

    /// Adjacency is symmetric: every line can be walked in both directions.
    @Test func adjacencyIsSymmetric() {
        for point in Board.allPoints {
            for neighbor in Board.adjacency[point] {
                #expect(Board.adjacency[neighbor].contains(point))
                #expect(neighbor != point)
            }
        }
    }

    /// Corners meet 2 lines, outer and inner midpoints meet 3, and the middle
    /// ring midpoints, where the spokes cross, meet 4.
    @Test func adjacencyDegreesMatchTheBoard() {
        for point in Board.allPoints {
            let degree = Board.adjacency[point].count
            let slot = Board.slot(of: point)
            let ring = Board.ring(of: point)
            if !Board.isMidpoint(slot: slot) {
                #expect(degree == 2, "Corner \(point) should meet exactly 2 lines")
            } else if ring == 1 {
                #expect(degree == 4, "Middle midpoint \(point) should meet 4 lines")
            } else {
                #expect(degree == 3, "Outer or inner midpoint \(point) should meet 3 lines")
            }
        }
        let edgeCount = Board.adjacency.reduce(0) { $0 + $1.count } / 2
        #expect(edgeCount == 32)
    }

    // MARK: Mills

    @Test func thereAreExactlySixteenMills() {
        #expect(Board.mills.count == 16)
        #expect(Set(Board.mills.map { Set($0) }).count == 16, "No mill is listed twice")
        for mill in Board.mills {
            #expect(mill.count == 3)
            #expect(Set(mill).count == 3)
            #expect(mill.allSatisfy(Board.allPoints.contains))
        }
    }

    /// Every point belongs to at least one mill, midpoints to at least two.
    @Test func everyPointIsInAMill() {
        for point in Board.allPoints {
            let count = Board.mills(containing: point).count
            #expect(count >= 1)
            if Board.isMidpoint(slot: Board.slot(of: point)) {
                #expect(count >= 2, "Midpoint \(point) sits on a side and a spoke or two sides")
            }
        }
    }

    /// Consecutive mill points are adjacent, so every mill is a real line on
    /// the board and not just a triple of indices.
    @Test func millsFollowBoardLines() {
        for mill in Board.mills {
            #expect(Board.isAdjacent(mill[0], mill[1]))
            #expect(Board.isAdjacent(mill[1], mill[2]))
        }
    }

    // MARK: Physical layout

    /// The three points of every mill are collinear in the physical layout.
    @Test(arguments: Board.mills)
    func millsAreCollinearInTheLayout(mill: [Int]) {
        let a = Board.layoutPosition(of: mill[0])
        let b = Board.layoutPosition(of: mill[1])
        let c = Board.layoutPosition(of: mill[2])
        let ab = b - a
        let ac = c - a
        let cross = ab.x * ac.y - ab.y * ac.x
        #expect(abs(cross) < 0.0001, "Mill \(mill) bends in the layout")
    }

    /// Pinned positions for representative points, in meters from the board
    /// center, x east and y south, compared with a small Float tolerance.
    @Test(arguments: [
        (0, SIMD2<Float>(-0.18, -0.18)),
        (1, SIMD2<Float>(0, -0.18)),
        (4, SIMD2<Float>(0.18, 0.18)),
        (9, SIMD2<Float>(0, -0.12)),
        (17, SIMD2<Float>(0, -0.06)),
        (19, SIMD2<Float>(0.06, 0)),
        (23, SIMD2<Float>(-0.06, 0)),
    ])
    func representativeLayoutPositionsArePinned(point: Int, expected: SIMD2<Float>) {
        let actual = Board.layoutPosition(of: point)
        #expect(abs(actual.x - expected.x) < 0.00001, "Point \(point) drifted to \(actual), expected \(expected)")
        #expect(abs(actual.y - expected.y) < 0.00001, "Point \(point) drifted to \(actual), expected \(expected)")
    }

    /// No two points share a physical position.
    @Test func layoutPositionsAreDistinct() {
        let positions = Board.allPoints.map { Board.layoutPosition(of: $0) }
        #expect(Set(positions.map { "\($0.x),\($0.y)" }).count == Board.pointCount)
    }

    /// The diagram notation used by the rules tests maps every point exactly once.
    @Test func diagramNotationCoversTheBoard() {
        let mapped = BoardDiagram.rowPoints.flatMap { $0 }
        #expect(mapped.count == Board.pointCount)
        #expect(Set(mapped).count == Board.pointCount)
    }
}
