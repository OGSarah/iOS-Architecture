//
//  ChangeRingerAppDelegate.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

import UIKit

/// The application-level entry point.
///
/// This app keeps it deliberately empty: the document scene is built in `SceneDelegate`, and
/// the document lifecycle is owned by `TouchEditorViewController` and its presenter. The app
/// delegate only vends the default scene configuration.
@main
class ChangeRingerAppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // No per-scene resources need releasing when a scene session is discarded.
    }
}
