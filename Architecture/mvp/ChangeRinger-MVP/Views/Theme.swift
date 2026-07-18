//
//  Theme.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

import UIKit

/// The app's visual theme: a navy and gold palette with Dynamic Type fonts.
///
/// Colours are defined in code as dynamic providers so they adapt to light and dark mode and
/// keep the same navy and gold identity in both, with contrast chosen to stay legible. Fonts
/// are derived from the system text styles so every label scales with the user's preferred
/// text size. Centralising this keeps the views free of scattered colour and font literals.
@MainActor
enum Theme {

    // MARK: Palette

    /// The deep navy that anchors the app, darker in light mode and a touch lifted in dark.
    static let navy = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.09, green: 0.14, blue: 0.26, alpha: 1)
            : UIColor(red: 0.10, green: 0.16, blue: 0.32, alpha: 1)
    }

    /// A lighter navy for raised surfaces such as the notation bar and call strip.
    static let navyElevated = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.13, green: 0.19, blue: 0.34, alpha: 1)
            : UIColor(red: 0.16, green: 0.24, blue: 0.44, alpha: 1)
    }

    /// The gold accent used for calls, selection, and interactive tint.
    static let gold = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.87, green: 0.72, blue: 0.38, alpha: 1)
            : UIColor(red: 0.79, green: 0.62, blue: 0.24, alpha: 1)
    }

    /// A muted, desaturated gold for disabled controls.
    ///
    /// It stays light enough that dark navy text remains legible on top, so a disabled call
    /// button reads clearly as inactive without vanishing against the navy bar behind it.
    static let goldMuted = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.58, green: 0.52, blue: 0.38, alpha: 1)
            : UIColor(red: 0.82, green: 0.74, blue: 0.55, alpha: 1)
    }

    /// The primary text colour shown on navy: near-white for strong contrast.
    static let primaryText = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.96, alpha: 1)
            : UIColor(white: 0.98, alpha: 1)
    }

    /// A muted variant of the primary text for secondary detail.
    static let secondaryText = UIColor(white: 0.75, alpha: 1)

    /// The blue of the traced line, distinct from navy so it reads over the grid.
    static let blueLine = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.40, green: 0.70, blue: 1.0, alpha: 1)
            : UIColor(red: 0.20, green: 0.55, blue: 0.95, alpha: 1)
    }

    /// The colour marking a false row, chosen to remain distinct for colour-blind users by
    /// pairing it with a text label rather than relying on colour alone.
    static let falseRow = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 1.0, green: 0.45, blue: 0.42, alpha: 1)
            : UIColor(red: 0.82, green: 0.18, blue: 0.15, alpha: 1)
    }

    // MARK: Fonts

    /// The monospaced font used for rows, so the bell columns line up vertically.
    ///
    /// It is built from the body text style through `UIFontMetrics`, so it scales with
    /// Dynamic Type while keeping fixed-width digits.
    static func rowFont() -> UIFont {
        let base = UIFont.monospacedSystemFont(ofSize: 20, weight: .semibold)
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: base)
    }

    /// A scaled font for a given text style, for labels that should track Dynamic Type.
    ///
    /// - Parameter style: The text style to derive from.
    /// - Returns: The preferred font for that style.
    static func font(_ style: UIFont.TextStyle) -> UIFont {
        UIFont.preferredFont(forTextStyle: style)
    }
}
