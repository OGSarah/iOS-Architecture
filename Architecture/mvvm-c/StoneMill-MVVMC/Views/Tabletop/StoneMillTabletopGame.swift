import RealityKit
import Spatial
import TabletopKit
import UIKit

/// Owns the `TabletopGame`, the entity tree it renders into, and the mapping
/// between rules points and stone equipment.
///
/// The renderer is deliberately one way: ``sync(to:)`` is the single path
/// that moves stones, and it re-derives every move from the authoritative
/// ``GameState``. Human drags, taps, computer replies, resets, and UI test
/// fixtures all render through the same diff, so nothing on the table can
/// drift from the rules.
@MainActor
final class StoneMillTabletopGame {

    /// The TabletopKit game instance the SwiftUI modifier attaches to.
    let tabletopGame: TabletopGame

    /// The root entity added to the volume; the tabletop renders under it.
    let root: Entity

    /// The static layout the table was built from.
    let setup: BoardSetup

    /// Which stone currently sits on each occupied point.
    private(set) var occupancy: [Int: EquipmentIdentifier] = [:]

    /// Stones still in each rack, in the order they will be placed.
    private var rackedPieces: [PlayerColor: [EquipmentIdentifier]] = [:]

    /// Stones that have been captured, in capture order.
    private var capturedPieces: [EquipmentIdentifier] = []

    /// Builds the table, claims a seat, and stands the equipment up.
    init() {
        setup = BoardSetup()
        var tableSetup = TableSetup(tabletop: setup.table)
        for seat in setup.seats {
            tableSetup.add(seat: seat)
        }
        for spot in setup.pointSpots {
            tableSetup.add(equipment: spot)
        }
        for piece in setup.pieces {
            tableSetup.add(equipment: piece)
        }
        tabletopGame = TabletopGame(tableSetup: tableSetup)
        tabletopGame.claimAnySeat()

        root = Entity()
        root.addChild(setup.table.entity)
        resetTracking()
    }

    /// The board point a stone currently occupies, if any.
    func point(of piece: EquipmentIdentifier) -> Int? {
        occupancy.first { $0.value == piece }?.key
    }

    /// Whether a stone is still waiting in its rack.
    func isRacked(_ piece: EquipmentIdentifier) -> Bool {
        guard let owner = piece.pieceOwner else { return false }
        return rackedPieces[owner]?.contains(piece) ?? false
    }

    /// Records a gesture driven move so the following ``sync(to:)`` treats the
    /// stone as already rendered and does not move it a second time.
    func noteGestureMove(of piece: EquipmentIdentifier, to point: Int) {
        if let from = self.point(of: piece) {
            occupancy[from] = nil
        }
        if let owner = piece.pieceOwner {
            rackedPieces[owner]?.removeAll { $0 == piece }
        }
        occupancy[point] = piece
    }

    // MARK: Syncing

    /// Renders a game state by diffing it against what is on the table and
    /// issuing the equipment moves that reconcile the two.
    func sync(to state: GameState) {
        if state.moveCount == 0, state.result == nil, state.emptyPoints.count == Board.pointCount {
            resetTable()
            return
        }

        for color in PlayerColor.allCases {
            // Points that should show this color but do not yet.
            let additions = Board.allPoints.filter { point in
                state.points[point] == color && occupancy[point]?.pieceOwner != color
            }
            // Points showing this color that should no longer.
            var removals = Board.allPoints.filter { point in
                occupancy[point]?.pieceOwner == color && state.points[point] != color
            }

            for point in additions {
                let piece: EquipmentIdentifier
                if let from = removals.popLast(), let moved = occupancy[from] {
                    occupancy[from] = nil
                    piece = moved
                } else if let fromRack = rackedPieces[color]?.popLast() {
                    piece = fromRack
                } else {
                    continue
                }
                occupancy[point] = piece
                move(piece, toSpot: point)
            }

            // Anything left over was captured.
            for point in removals {
                guard let piece = occupancy[point] else { continue }
                occupancy[point] = nil
                capturedPieces.append(piece)
                move(piece, toCapturedSlot: capturedPieces.count - 1, color: color)
            }
        }
    }

    /// Returns every stone to its rack for a fresh match.
    private func resetTable() {
        occupancy = [:]
        capturedPieces = []
        resetTracking()
        for piece in setup.pieces {
            guard let owner = piece.id.pieceOwner,
                  let index = rackedPieces[owner]?.firstIndex(of: piece.id) else { continue }
            tabletopGame.addAction(.moveEquipment(
                matching: piece.id,
                childOf: .stoneMillTable,
                pose: BoardSetup.rackPose(for: owner, index: index)
            ))
        }
    }

    private func resetTracking() {
        rackedPieces = [
            .light: (0..<Board.piecesPerPlayer).map { .piece(for: .light, index: $0) }.reversed(),
            .dark: (0..<Board.piecesPerPlayer).map { .piece(for: .dark, index: $0) }.reversed(),
        ]
    }

    private func move(_ piece: EquipmentIdentifier, toSpot point: Int) {
        tabletopGame.addAction(.moveEquipment(
            matching: piece,
            childOf: .pointSpot(point),
            pose: TableVisualState.Pose2D(position: .init(x: 0, z: 0), rotation: .degrees(0))
        ))
    }

    private func move(_ piece: EquipmentIdentifier, toCapturedSlot index: Int, color: PlayerColor) {
        tabletopGame.addAction(.moveEquipment(
            matching: piece,
            childOf: .stoneMillTable,
            pose: BoardSetup.capturedPose(for: color, index: index)
        ))
    }

    // MARK: Highlights

    /// Tints the snap spot discs to show what the player may do: droppable
    /// points in sand, capturable stones in red, and the lifted stone's spot
    /// in bright sand.
    func updateHighlights(selectable: Set<Int>, capturable: Set<Int>, selected: Int?, mill: [Int]?) {
        for point in Board.allPoints {
            let color: UIColor
            if point == selected {
                color = PointSpot.selectedColor
            } else if capturable.contains(point) {
                color = PointSpot.capturableColor
            } else if selectable.contains(point) {
                color = PointSpot.selectableColor
            } else if let mill, mill.contains(point) {
                color = PointSpot.selectedColor
            } else {
                color = PointSpot.idleColor
            }
            tint(spotAt: point, with: color)
        }
    }

    private func tint(spotAt point: Int, with color: UIColor) {
        guard point < setup.pointSpots.count else { return }
        let spot = setup.pointSpots[point]
        guard let disc = spot.entity.findEntity(named: "spotDisc") as? ModelEntity else { return }
        var material = UnlitMaterial(color: color)
        material.blending = .transparent(opacity: .init(floatLiteral: 0.9))
        disc.model?.materials = [material]
    }
}
