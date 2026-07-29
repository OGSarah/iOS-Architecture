//
//  Preferences.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import Foundation

/// The small set of user preferences the app persists, wrapped so call sites do not touch keys.
enum Preferences {

    private static let defaults = UserDefaults.standard

    private enum Key {
        static let hasCompletedOnboarding = "chatelaine.hasCompletedOnboarding"
        static let animationsEnabled = "chatelaine.animationsEnabled"
    }

    /// Whether the onboarding flow has been completed. Drives whether it shows on launch.
    static var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Key.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: Key.hasCompletedOnboarding) }
    }

    /// The in app animation toggle. Defaults to on, and combines with the system Reduce Motion
    /// setting inside `MotionManager` to decide whether an animation actually plays.
    static var animationsEnabled: Bool {
        get {
            if defaults.object(forKey: Key.animationsEnabled) == nil { return true }
            return defaults.bool(forKey: Key.animationsEnabled)
        }
        set { defaults.set(newValue, forKey: Key.animationsEnabled) }
    }
}
