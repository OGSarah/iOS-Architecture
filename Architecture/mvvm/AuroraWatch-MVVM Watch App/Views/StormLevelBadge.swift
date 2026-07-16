//
//  StormLevelBadge.swift
//  AuroraWatch-MVVM Watch App
//
//  Created by Sarah Clark on 7/16/26.
//

import SwiftUI

/// A capsule badge showing a storm scale label, such as "G3" or "Quiet".
///
/// A pure function of its inputs: no view model, no state. Color is never
/// the only signal, the badge always carries its text, so the storm level
/// survives color blindness and monochrome rendering.
struct StormLevelBadge: View {

    /// The text inside the badge.
    let text: String

    /// The severity bucket that decides the badge's tint.
    let colorRole: StormLevel.ColorRole

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(colorRole.color.opacity(0.25), in: .capsule)
            .foregroundStyle(colorRole.color)
            .accessibilityIdentifier(AccessibilityID.stormBadge)
    }
}

extension StormLevel.ColorRole {

    /// The concrete color for a severity bucket.
    ///
    /// This mapping lives in the view layer on purpose: the model names
    /// the meaning, the view picks the pixels.
    var color: Color {
        switch self {
        case .calm: .green
        case .minor: .yellow
        case .moderate: .orange
        case .strong: .red
        case .severe: .pink
        case .extreme: .purple
        }
    }
}

#Preview("Storm levels") {
    VStack(spacing: 6) {
        StormLevelBadge(text: "Quiet", colorRole: .calm)
        StormLevelBadge(text: "G1", colorRole: .minor)
        StormLevelBadge(text: "G3", colorRole: .strong)
        StormLevelBadge(text: "G5", colorRole: .extreme)
    }
}
