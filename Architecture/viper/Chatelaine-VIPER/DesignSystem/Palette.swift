//
//  Palette.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// Named accessors for the brand palette, so views reference a role rather than an asset string.
///
/// The colors are derived from the app icon and tuned for WCAG AA contrast in both light and dark
/// mode. Prefer semantic system colors for content text, and these for the functional layer and
/// accents.
enum Palette {

    static var accent: UIColor { color("AccentColor") }
    static var brandNavy: UIColor { color("BrandNavy") }
    static var brandNavyElevated: UIColor { color("BrandNavyElevated") }
    static var brandCharcoal: UIColor { color("BrandCharcoal") }
    static var brassMuted: UIColor { color("BrassMuted") }
    static var textPrimary: UIColor { color("TextPrimary") }
    static var textSecondary: UIColor { color("TextSecondary") }
    static var warningAmber: UIColor { color("WarningAmber") }

    /// Looks up a named color, falling back to a system color so a missing asset never crashes.
    private static func color(_ name: String) -> UIColor {
        UIColor(named: name) ?? .label
    }
}
