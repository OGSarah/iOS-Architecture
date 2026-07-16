//
//  PieceEquipment.swift
//  StoneMill-MVVMC
//
//  Created by Sarah Clark on 7/16/26.
//

import RealityKit
import TabletopKit
import UIKit

/// The identifier scheme for every piece of equipment on the table, pinned by
/// the geometry tests so the mapping between rules points and TabletopKit
/// equipment can never drift silently.
///
/// The table is 1, the 24 snap spots are 100 plus the point index, light
/// stones are 200 through 208, and dark stones are 300 through 308.
nonisolated extension EquipmentIdentifier {

    /// The board slab itself.
    static var stoneMillTable: EquipmentIdentifier { EquipmentIdentifier(1) }

    /// The snap spot equipment for a board point.
    static func pointSpot(_ point: Int) -> EquipmentIdentifier {
        EquipmentIdentifier(100 + point)
    }

    /// The stone with a given index (0 through 8) for a side.
    static func piece(for color: PlayerColor, index: Int) -> EquipmentIdentifier {
        EquipmentIdentifier((color == .light ? 200 : 300) + index)
    }

    /// The board point this identifier snaps to, if it is a point spot.
    var pointIndex: Int? {
        (100..<(100 + Board.pointCount)).contains(rawValue) ? rawValue - 100 : nil
    }

    /// The side that owns this identifier, if it is a stone.
    var pieceOwner: PlayerColor? {
        switch rawValue {
        case 200..<(200 + Board.piecesPerPlayer): .light
        case 300..<(300 + Board.piecesPerPlayer): .dark
        default: nil
        }
    }
}

/// One of the eighteen stones, rendered as a squat RealityKit cylinder in the
/// icon's sandstone or dark umber.
nonisolated struct PieceEquipment: EntityEquipment {

    /// The radius of a stone in meters.
    static let radius: Float = 0.017

    /// The height of a stone in meters.
    static let height: Float = 0.011

    let id: EquipmentIdentifier
    let entity: Entity
    var initialState: BaseEquipmentState

    /// Creates a stone for a side, starting at its rack pose on the table.
    init(color: PlayerColor, index: Int, rackPose: TableVisualState.Pose2D) {
        self.id = .piece(for: color, index: index)
        self.entity = Self.makeStoneEntity(color: color)
        self.initialState = BaseEquipmentState(
            parentID: .stoneMillTable,
            seatControl: .any,
            pose: rackPose,
            entity: entity
        )
    }

    /// Builds a stone entity, shared with the immersive in situ board so both
    /// renderers agree on what a stone looks like.
    static func makeStoneEntity(color: PlayerColor) -> Entity {
        let mesh = MeshResource.generateCylinder(height: height, radius: radius)
        var material = PhysicallyBasedMaterial()
        let uiColor: UIColor = color == .light
            ? UIColor(red: 0.76, green: 0.69, blue: 0.61, alpha: 1)
            : UIColor(red: 0.18, green: 0.14, blue: 0.10, alpha: 1)
        material.baseColor = .init(tint: uiColor)
        material.roughness = 0.85
        material.metallic = 0.0
        let model = ModelEntity(mesh: mesh, materials: [material])
        model.position.y = height / 2
        let root = Entity()
        root.addChild(model)
        return root
    }
}
