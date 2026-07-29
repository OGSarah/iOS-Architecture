//
//  GlassStyling.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// Helpers for applying iOS 27 Liquid Glass to the functional layer, sparingly and accessibly.
///
/// Per the Human Interface Guidelines, glass belongs on controls and navigation that float above
/// content, not in the content layer itself. System bars adopt it automatically, so these helpers
/// are for the few custom functional elements, such as the onboarding call to action. When Reduce
/// Transparency is on, they fall back to a solid brand surface so legibility is never at risk.
enum GlassStyling {

    /// A rounded background view using Liquid Glass, or a solid surface when transparency is reduced.
    /// - Parameter cornerRadius: The corner radius of the surface.
    /// - Returns: A view suitable for placing behind a floating control.
    static func glassBackground(cornerRadius: CGFloat) -> UIView {
        guard !UIAccessibility.isReduceTransparencyEnabled else {
            let solid = UIView()
            solid.backgroundColor = Palette.brandNavyElevated
            solid.layer.cornerRadius = cornerRadius
            solid.layer.cornerCurve = .continuous
            return solid
        }

        let effectView = UIVisualEffectView(effect: UIGlassEffect())
        effectView.layer.cornerRadius = cornerRadius
        effectView.layer.cornerCurve = .continuous
        effectView.clipsToBounds = true
        return effectView
    }
}
