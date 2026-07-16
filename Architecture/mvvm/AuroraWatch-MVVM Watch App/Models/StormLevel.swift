//
//  StormLevel.swift
//  AuroraWatch-MVVM Watch App
//
//  Created by Sarah Clark on 7/16/26.
//

import Foundation

/// NOAA's geomagnetic storm scale (G-scale), derived from a Kp value.
///
/// The Kp to G-scale mapping is a property of the data, not of any screen,
/// so it lives in the model layer. Both the app and the widget read it
/// without a view model in between.
nonisolated enum StormLevel: Int, CaseIterable, Comparable, Sendable {

    /// Kp below 5, no geomagnetic storm.
    case quiet = 0
    /// G1, minor storm, Kp 5 range.
    case g1
    /// G2, moderate storm, Kp 6 range.
    case g2
    /// G3, strong storm, Kp 7 range.
    case g3
    /// G4, severe storm, Kp 8 range.
    case g4
    /// G5, extreme storm, Kp 9.
    case g5

    /// Maps a Kp value onto the G-scale.
    ///
    /// The G1 boundary sits at exactly 5.0 on purpose: NOAA defines G1 as
    /// Kp 5, so 4.99 is quiet and 5.0 is a minor storm. The unit tests pin
    /// this edge.
    init(kp: Double) {
        switch kp {
        case ..<5.0: self = .quiet
        case ..<6.0: self = .g1
        case ..<7.0: self = .g2
        case ..<8.0: self = .g3
        case ..<9.0: self = .g4
        default: self = .g5
        }
    }

    /// The NOAA scale label, such as "G1", or `nil` below storm threshold.
    var scaleLabel: String? {
        switch self {
        case .quiet: nil
        case .g1: "G1"
        case .g2: "G2"
        case .g3: "G3"
        case .g4: "G4"
        case .g5: "G5"
        }
    }

    /// NOAA's severity name for the level.
    var title: String {
        switch self {
        case .quiet: "Quiet"
        case .g1: "Minor storm"
        case .g2: "Moderate storm"
        case .g3: "Strong storm"
        case .g4: "Severe storm"
        case .g5: "Extreme storm"
        }
    }

    /// A plain English line describing how far south the aurora may be
    /// visible at this level.
    var visibilityDescription: String {
        switch self {
        case .quiet: "Aurora unlikely outside polar latitudes."
        case .g1: "Aurora possible at high latitudes, such as northern Scandinavia and Alaska."
        case .g2: "Aurora may reach northern tier states and central Scandinavia."
        case .g3: "Aurora may be seen as far south as Illinois and Oregon."
        case .g4: "Aurora may be seen as far south as Alabama and northern California."
        case .g5: "Aurora may be seen as far south as Florida and southern Texas."
        }
    }

    /// A semantic color role the views translate into a concrete `Color`.
    ///
    /// The model names the meaning, the view picks the pixels. This keeps
    /// SwiftUI out of the model layer.
    var colorRole: ColorRole {
        switch self {
        case .quiet: .calm
        case .g1: .minor
        case .g2: .moderate
        case .g3: .strong
        case .g4: .severe
        case .g5: .extreme
        }
    }

    /// Severity buckets the UI maps to colors.
    enum ColorRole: Sendable {
        case calm
        case minor
        case moderate
        case strong
        case severe
        case extreme
    }

    static func < (lhs: StormLevel, rhs: StormLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
