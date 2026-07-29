//
//  Typography.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// Dynamic Type helpers, so every label scales with the user's preferred text size by default.
enum Typography {

    /// A font for a text style at an optional weight, scaled for the current content size category.
    /// - Parameters:
    ///   - style: The text style, which sets the base size and scaling behavior.
    ///   - weight: The font weight.
    /// - Returns: A scaled `UIFont`.
    static func font(_ style: UIFont.TextStyle, weight: UIFont.Weight = .regular) -> UIFont {
        let base = UIFont.preferredFont(forTextStyle: style)
        let weighted = UIFont.systemFont(ofSize: base.pointSize, weight: weight)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: weighted)
    }

    /// A label preconfigured for Dynamic Type at the given style and weight.
    /// - Parameters:
    ///   - style: The text style.
    ///   - weight: The font weight.
    /// - Returns: A label that adjusts its font as the content size category changes.
    static func label(_ style: UIFont.TextStyle, weight: UIFont.Weight = .regular) -> UILabel {
        let label = UILabel()
        label.font = font(style, weight: weight)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }
}
