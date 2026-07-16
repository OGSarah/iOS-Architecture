//
//  Excavation.swift
//  StoneMill-MVVMC
//
//  Created by Sarah Clark on 7/16/26.
//

import Foundation
import simd

/// One of the historical sites where a Nine Men's Morris board has actually
/// been found, together with everything the immersive space needs to render
/// it procedurally.
///
/// An excavation is pure placement data: colors as plain float components,
/// primitive prop descriptors, and a pose for the in situ board. The immersive
/// view stays a dumb renderer of this data and holds no knowledge of the
/// individual sites.
nonisolated struct Excavation: Identifiable, Equatable, Sendable {

    /// A UI framework free RGB color.
    struct ColorValue: Equatable, Sendable {
        var red: Float
        var green: Float
        var blue: Float
    }

    /// A primitive shape placed somewhere in the site.
    struct Prop: Equatable, Sendable {

        /// The geometry of a prop.
        enum Shape: Equatable, Sendable {

            /// A box with the given width, height, and depth in meters.
            case box(size: SIMD3<Float>)

            /// A vertical cylinder with the given radius and height in meters.
            case cylinder(radius: Float, height: Float)
        }

        /// The geometry to generate.
        var shape: Shape

        /// The world position of the prop's center, in meters.
        var position: SIMD3<Float>

        /// The rotation of the prop around the vertical axis, in radians.
        var yRotation: Float

        /// The base color of the prop's material.
        var color: ColorValue

        /// The roughness of the prop's material, from 0 (polished) to 1 (matte).
        var roughness: Float
    }

    /// A stable identifier: `kurna`, `gokstad`, or `cloister`.
    let id: String

    /// The display name of the site.
    let name: String

    /// When and where the board was carved.
    let era: String

    /// A short paragraph shown on the site panel.
    let blurb: String

    /// The sky color directly overhead.
    let skyTop: ColorValue

    /// The sky color at the horizon.
    let skyHorizon: ColorValue

    /// The color of the ground disk.
    let groundColor: ColorValue

    /// The radius of the ground disk in meters.
    let groundRadius: Float

    /// The ambient light intensity of the site, in lux.
    let lightIntensity: Float

    /// The world position of the in situ board's center.
    let boardPosition: SIMD3<Float>

    /// The rotation of the board around the vertical axis, in radians.
    let boardYRotation: Float

    /// A uniform scale applied to the board and its stones.
    let boardScale: Float

    /// The stone color the site's board is carved from.
    let boardColor: ColorValue

    /// The primitive props that dress the site.
    let props: [Prop]

    /// The site with a given identifier, falling back to the first site.
    static func site(id: String) -> Excavation {
        all.first { $0.id == id } ?? all[0]
    }

    /// The three sites, in the order the panel presents them.
    static let all: [Excavation] = [kurna, gokstad, cloister]

    /// The mortuary temple of Ramesses II at Kurna, where boards were cut into
    /// the roofing slabs, likely by the masons who built it.
    static let kurna = Excavation(
        id: "kurna",
        name: "Temple at Kurna",
        era: "Egypt, around 1400 BC",
        blurb: "Boards were found cut into the roofing slabs of the temple at Kurna, likely scratched in by the masons who laid them. The board in front of you sits on a fallen slab among the column bases.",
        skyTop: ColorValue(red: 0.45, green: 0.62, blue: 0.80),
        skyHorizon: ColorValue(red: 0.93, green: 0.82, blue: 0.62),
        groundColor: ColorValue(red: 0.79, green: 0.68, blue: 0.48),
        groundRadius: 14,
        lightIntensity: 2200,
        boardPosition: SIMD3(0, 0.72, -1.1),
        boardYRotation: 0,
        boardScale: 1.0,
        boardColor: ColorValue(red: 0.78, green: 0.69, blue: 0.55),
        props: [
            // The fallen roofing slab the board is carved into.
            Prop(shape: .box(size: SIMD3(1.4, 0.72, 0.9)), position: SIMD3(0, 0.36, -1.1), yRotation: 0.06, color: ColorValue(red: 0.76, green: 0.66, blue: 0.50), roughness: 0.95),
            // A row of column drums to the left and right.
            Prop(shape: .cylinder(radius: 0.45, height: 2.6), position: SIMD3(-2.6, 1.3, -2.4), yRotation: 0, color: ColorValue(red: 0.80, green: 0.70, blue: 0.52), roughness: 0.9),
            Prop(shape: .cylinder(radius: 0.45, height: 3.2), position: SIMD3(2.7, 1.6, -2.8), yRotation: 0, color: ColorValue(red: 0.82, green: 0.72, blue: 0.54), roughness: 0.9),
            Prop(shape: .cylinder(radius: 0.45, height: 1.4), position: SIMD3(-3.4, 0.7, -5.0), yRotation: 0, color: ColorValue(red: 0.78, green: 0.68, blue: 0.50), roughness: 0.9),
            Prop(shape: .cylinder(radius: 0.45, height: 2.0), position: SIMD3(3.6, 1.0, -5.6), yRotation: 0, color: ColorValue(red: 0.80, green: 0.70, blue: 0.52), roughness: 0.9),
            // A low ruined wall closing the space behind the board.
            Prop(shape: .box(size: SIMD3(6.0, 1.1, 0.7)), position: SIMD3(0, 0.55, -6.5), yRotation: 0, color: ColorValue(red: 0.74, green: 0.64, blue: 0.47), roughness: 0.95),
            // Scattered blocks.
            Prop(shape: .box(size: SIMD3(0.8, 0.5, 0.6)), position: SIMD3(-1.8, 0.25, -3.6), yRotation: 0.5, color: ColorValue(red: 0.77, green: 0.67, blue: 0.50), roughness: 0.95),
            Prop(shape: .box(size: SIMD3(0.6, 0.4, 0.5)), position: SIMD3(1.9, 0.2, -4.2), yRotation: -0.3, color: ColorValue(red: 0.75, green: 0.65, blue: 0.48), roughness: 0.95),
        ]
    )

    /// The Gokstad ship burial, where a board was cut into the deck planks for
    /// the crew to pass long passages at sea.
    static let gokstad = Excavation(
        id: "gokstad",
        name: "Gokstad Ship",
        era: "Norway, 9th century AD",
        blurb: "A board was cut into the oak deck planks of the Gokstad ship, played by the crew between watches. The board here sits on the planking amidships, with the mast rising behind it.",
        skyTop: ColorValue(red: 0.36, green: 0.46, blue: 0.58),
        skyHorizon: ColorValue(red: 0.70, green: 0.74, blue: 0.76),
        groundColor: ColorValue(red: 0.16, green: 0.22, blue: 0.28),
        groundRadius: 30,
        lightIntensity: 1400,
        boardPosition: SIMD3(0, 0.58, -1.0),
        boardYRotation: 0.12,
        boardScale: 0.9,
        boardColor: ColorValue(red: 0.42, green: 0.32, blue: 0.22),
        props: [
            // Deck planking under and around the player.
            Prop(shape: .box(size: SIMD3(0.55, 0.5, 9.0)), position: SIMD3(-0.9, 0.25, -2.0), yRotation: 0, color: ColorValue(red: 0.40, green: 0.30, blue: 0.20), roughness: 0.85),
            Prop(shape: .box(size: SIMD3(0.55, 0.5, 9.0)), position: SIMD3(-0.3, 0.25, -2.0), yRotation: 0, color: ColorValue(red: 0.44, green: 0.33, blue: 0.22), roughness: 0.85),
            Prop(shape: .box(size: SIMD3(0.55, 0.58, 9.0)), position: SIMD3(0.3, 0.29, -2.0), yRotation: 0, color: ColorValue(red: 0.41, green: 0.31, blue: 0.21), roughness: 0.85),
            Prop(shape: .box(size: SIMD3(0.55, 0.5, 9.0)), position: SIMD3(0.9, 0.25, -2.0), yRotation: 0, color: ColorValue(red: 0.43, green: 0.32, blue: 0.21), roughness: 0.85),
            // Gunwales rising along both sides.
            Prop(shape: .box(size: SIMD3(0.25, 1.0, 9.0)), position: SIMD3(-1.6, 0.5, -2.0), yRotation: 0, color: ColorValue(red: 0.36, green: 0.27, blue: 0.18), roughness: 0.85),
            Prop(shape: .box(size: SIMD3(0.25, 1.0, 9.0)), position: SIMD3(1.6, 0.5, -2.0), yRotation: 0, color: ColorValue(red: 0.36, green: 0.27, blue: 0.18), roughness: 0.85),
            // The mast.
            Prop(shape: .cylinder(radius: 0.16, height: 7.0), position: SIMD3(0, 3.5, -3.4), yRotation: 0, color: ColorValue(red: 0.38, green: 0.29, blue: 0.19), roughness: 0.8),
            // A sea chest the crew sat on.
            Prop(shape: .box(size: SIMD3(0.9, 0.45, 0.45)), position: SIMD3(-1.0, 0.72, -1.1), yRotation: 0.2, color: ColorValue(red: 0.33, green: 0.25, blue: 0.16), roughness: 0.9),
        ]
    )

    /// A cloister bench worn smooth by monks who played between offices.
    static let cloister = Excavation(
        id: "cloister",
        name: "Cloister Bench",
        era: "England, 14th century AD",
        blurb: "Boards survive worn into the stone benches of cloister walks across Europe, played by monks between offices for generations. This one is cut into the bench between two columns of the arcade.",
        skyTop: ColorValue(red: 0.16, green: 0.15, blue: 0.14),
        skyHorizon: ColorValue(red: 0.42, green: 0.38, blue: 0.32),
        groundColor: ColorValue(red: 0.45, green: 0.42, blue: 0.38),
        groundRadius: 10,
        lightIntensity: 900,
        boardPosition: SIMD3(0, 0.52, -0.9),
        boardYRotation: 0,
        boardScale: 0.8,
        boardColor: ColorValue(red: 0.58, green: 0.55, blue: 0.50),
        props: [
            // The bench the board is worn into.
            Prop(shape: .box(size: SIMD3(3.4, 0.52, 0.6)), position: SIMD3(0, 0.26, -0.9), yRotation: 0, color: ColorValue(red: 0.56, green: 0.53, blue: 0.48), roughness: 0.95),
            // The arcade columns on either side of the bench.
            Prop(shape: .cylinder(radius: 0.18, height: 2.6), position: SIMD3(-1.9, 1.3, -1.0), yRotation: 0, color: ColorValue(red: 0.60, green: 0.57, blue: 0.52), roughness: 0.9),
            Prop(shape: .cylinder(radius: 0.18, height: 2.6), position: SIMD3(1.9, 1.3, -1.0), yRotation: 0, color: ColorValue(red: 0.60, green: 0.57, blue: 0.52), roughness: 0.9),
            Prop(shape: .cylinder(radius: 0.18, height: 2.6), position: SIMD3(-3.8, 1.3, -1.0), yRotation: 0, color: ColorValue(red: 0.58, green: 0.55, blue: 0.50), roughness: 0.9),
            Prop(shape: .cylinder(radius: 0.18, height: 2.6), position: SIMD3(3.8, 1.3, -1.0), yRotation: 0, color: ColorValue(red: 0.58, green: 0.55, blue: 0.50), roughness: 0.9),
            // The lintel the columns carry.
            Prop(shape: .box(size: SIMD3(8.5, 0.4, 0.5)), position: SIMD3(0, 2.8, -1.0), yRotation: 0, color: ColorValue(red: 0.54, green: 0.51, blue: 0.46), roughness: 0.95),
            // The cloister wall behind the walk.
            Prop(shape: .box(size: SIMD3(9.0, 3.2, 0.4)), position: SIMD3(0, 1.6, 2.2), yRotation: 0, color: ColorValue(red: 0.50, green: 0.47, blue: 0.43), roughness: 0.95),
        ]
    )
}
