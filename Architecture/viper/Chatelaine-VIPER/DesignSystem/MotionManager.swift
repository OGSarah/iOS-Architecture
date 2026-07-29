//
//  MotionManager.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// The single gate every animation in the app passes through.
///
/// Animations play only when the system Reduce Motion setting is off and the in app toggle is on.
/// When either disables motion, `animate` applies the end state instantly instead of tweening, so a
/// fun transition degrades to a correct, still result rather than being skipped or half applied.
enum MotionManager {

    /// Posted when the in app motion toggle changes, so interested views can refresh.
    static let didChangeNotification = Notification.Name("chatelaine.motionDidChange")

    /// Whether animations should currently play.
    static var animationsEnabled: Bool {
        !UIAccessibility.isReduceMotionEnabled && Preferences.animationsEnabled
    }

    /// Runs an animation, or applies it instantly when motion is disabled.
    /// - Parameters:
    ///   - duration: The animation duration when motion is enabled.
    ///   - animations: The changes to animate.
    ///   - completion: Called when the animation, or the instant application, finishes.
    static func animate(
        withDuration duration: TimeInterval = 0.3,
        _ animations: @escaping () -> Void,
        completion: ((Bool) -> Void)? = nil
    ) {
        if animationsEnabled {
            UIView.animate(withDuration: duration, animations: animations, completion: completion)
        } else {
            animations()
            completion?(true)
        }
    }

    /// Updates the in app motion toggle and notifies observers.
    /// - Parameter enabled: Whether the in app toggle should allow animations.
    static func setInAppEnabled(_ enabled: Bool) {
        Preferences.animationsEnabled = enabled
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }
}
