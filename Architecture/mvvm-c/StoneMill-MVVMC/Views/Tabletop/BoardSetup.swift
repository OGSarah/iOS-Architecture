//
//  BoardSetup.swift
//  StoneMill-MVVMC
//
//  Created by Sarah Clark on 7/16/26.
//

import RealityKit
import Spatial
import TabletopKit
import UIKit

/// Builds the physical layout of the game: the sandstone board slab with its
/// carved grooves, the 24 snap spots, two facing seats, and the stone racks
/// along the table edges.
///
/// Every position on the slab comes from ``Board/layoutPosition(of:)``, the
/// same function the rules tests pin, so the tabletop can never disagree with
/// the rules about where a point is.
@MainActor
struct BoardSetup {

    /// The width and depth of the square board slab in meters.
    nonisolated static let tableSize: Float = 0.56

    /// The thickness of the slab in meters.
    nonisolated static let tableThickness: Float = 0.02

    /// The distance of the rack rows from the slab center in meters.
    nonisolated static let rackOffset: Float = 0.245

    /// The distance of the captured stone columns from the slab center.
    nonisolated static let capturedOffset: Float = 0.255

    /// The table the game plays on.
    let table: StoneMillTable

    /// The two facing seats.
    let seats: [PlayerSeat]

    /// The 24 snap spots, indexed by board point.
    let pointSpots: [PointSpot]

    /// All 18 stones, light first.
    let pieces: [PieceEquipment]

    /// Builds the full table arrangement.
    init() {
        table = StoneMillTable()
        seats = [
            PlayerSeat(id: TableSeatIdentifier(0), position: .init(x: 0, z: 0.7), angleDegrees: 0),
            PlayerSeat(id: TableSeatIdentifier(1), position: .init(x: 0, z: -0.7), angleDegrees: 180),
        ]
        pointSpots = Board.allPoints.map { PointSpot(point: $0) }
        pieces = PlayerColor.allCases.flatMap { color in
            (0..<Board.piecesPerPlayer).map { index in
                PieceEquipment(color: color, index: index, rackPose: Self.rackPose(for: color, index: index))
            }
        }
    }

    /// The rack pose of an unplaced stone: light along the south edge, dark
    /// along the north edge.
    static func rackPose(for color: PlayerColor, index: Int) -> TableVisualState.Pose2D {
        let x = (Float(index) - Float(Board.piecesPerPlayer - 1) / 2) * 0.05
        let z: Float = color == .light ? rackOffset : -rackOffset
        return TableVisualState.Pose2D(position: .init(x: Double(x), z: Double(z)), rotation: .degrees(0))
    }

    /// Where a captured stone retires: columns along the east and west edges.
    static func capturedPose(for color: PlayerColor, index: Int) -> TableVisualState.Pose2D {
        let z = (Float(index) - 3.5) * 0.05
        let x: Float = color == .light ? -capturedOffset : capturedOffset
        return TableVisualState.Pose2D(position: .init(x: Double(x), z: Double(z)), rotation: .degrees(0))
    }
}

/// The sandstone slab, with the three rings and four spokes carved into it as
/// raised dark umber lines.
nonisolated struct StoneMillTable: EntityTabletop {

    let id: EquipmentIdentifier
    let entity: Entity
    let shape: TabletopShape

    init() {
        self.id = .stoneMillTable
        self.entity = Self.makeBoardEntity(
            size: BoardSetup.tableSize,
            thickness: BoardSetup.tableThickness,
            slabColor: UIColor(red: 0.78, green: 0.69, blue: 0.55, alpha: 1),
            grooveColor: UIColor(red: 0.24, green: 0.18, blue: 0.12, alpha: 1)
        )
        self.shape = .rectangular(entity: entity)
    }

    /// Builds a board slab with groove lines derived from the mill geometry.
    ///
    /// Shared with the immersive view, which renders the same board carved
    /// into each excavation site.
    static func makeBoardEntity(size: Float, thickness: Float, slabColor: UIColor, grooveColor: UIColor) -> Entity {
        let root = Entity()

        var slabMaterial = PhysicallyBasedMaterial()
        slabMaterial.baseColor = .init(tint: slabColor)
        slabMaterial.roughness = 0.95
        slabMaterial.metallic = 0.0
        let slab = ModelEntity(
            mesh: .generateBox(width: size, height: thickness, depth: size, cornerRadius: 0.004),
            materials: [slabMaterial]
        )
        slab.position.y = -thickness / 2
        root.addChild(slab)

        var grooveMaterial = PhysicallyBasedMaterial()
        grooveMaterial.baseColor = .init(tint: grooveColor)
        grooveMaterial.roughness = 0.9
        grooveMaterial.metallic = 0.0

        // One thin bar per mill line, running between its two end points.
        let grooveHeight: Float = 0.0015
        let grooveWidth: Float = 0.006
        for mill in Board.mills {
            let start = Board.layoutPosition(of: mill[0])
            let end = Board.layoutPosition(of: mill[2])
            let length = simd_distance(start, end)
            let isHorizontal = abs(start.y - end.y) < 0.0001
            let bar = ModelEntity(
                mesh: .generateBox(
                    width: isHorizontal ? length : grooveWidth,
                    height: grooveHeight,
                    depth: isHorizontal ? grooveWidth : length
                ),
                materials: [grooveMaterial]
            )
            bar.position = SIMD3((start.x + end.x) / 2, grooveHeight / 2, (start.y + end.y) / 2)
            root.addChild(bar)
        }
        return root
    }
}

/// A snap spot at one of the 24 points: a shallow disc the pieces snap onto,
/// tinted to show what the player may do with it.
nonisolated struct PointSpot: EntityEquipment {

    /// The radius of a spot disc in meters.
    static let radius: Float = 0.021

    let id: EquipmentIdentifier
    let entity: Entity
    var initialState: BaseEquipmentState

    /// Creates the spot for a board point at its pinned layout position.
    init(point: Int) {
        self.id = .pointSpot(point)
        self.entity = Self.makeSpotEntity()
        let position = Board.layoutPosition(of: point)
        self.initialState = BaseEquipmentState(
            parentID: .stoneMillTable,
            seatControl: .any,
            pose: TableVisualState.Pose2D(
                position: .init(x: Double(position.x), z: Double(position.y)),
                rotation: .degrees(0)
            ),
            entity: entity
        )
    }

    private static func makeSpotEntity() -> Entity {
        let root = Entity()
        var material = UnlitMaterial(color: PointSpot.idleColor)
        material.blending = .transparent(opacity: .init(floatLiteral: 0.9))
        let disc = ModelEntity(
            mesh: .generateCylinder(height: 0.001, radius: radius),
            materials: [material]
        )
        disc.name = "spotDisc"
        root.addChild(disc)
        return root
    }

    /// The disc color when nothing may happen at the point.
    static let idleColor = UIColor(red: 0.42, green: 0.35, blue: 0.28, alpha: 0.35)

    /// The disc color when the point may be tapped or dropped on.
    static let selectableColor = UIColor(red: 0.94, green: 0.85, blue: 0.60, alpha: 0.9)

    /// The disc color when the stone on the point may be captured.
    static let capturableColor = UIColor(red: 0.75, green: 0.25, blue: 0.18, alpha: 0.9)

    /// The disc color for the lifted stone's own point.
    static let selectedColor = UIColor(red: 0.98, green: 0.93, blue: 0.75, alpha: 1.0)
}

/// One of the two facing seats at the table.
nonisolated struct PlayerSeat: EntityTableSeat {

    let id: TableSeatIdentifier
    let entity: Entity
    var initialState: TableSeatState

    /// Creates a seat at a position around the table, facing its center.
    init(id: TableSeatIdentifier, position: TableVisualState.Point2D, angleDegrees: Double) {
        self.id = id
        self.entity = Entity()
        self.initialState = TableSeatState(
            pose: TableVisualState.Pose2D(position: position, rotation: .degrees(angleDegrees))
        )
    }
}
