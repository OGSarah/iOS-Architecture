//
//  StoneMillApp.swift
//  StoneMill-MVVMC
//
//  Created by Sarah Clark on 7/16/26.
//

import SwiftData
import SwiftUI

/// The app entry point: builds the SwiftData container and the single
/// ``AppCoordinator``, and declares the three scenes.
///
/// Every scene root installs the real scene opener on the coordinator and
/// reports its disappearance, so the coordinator always knows what is open,
/// even when the user closes a scene with the window control or the Digital
/// Crown. Nothing here or below ever calls a scene action directly.
@main
struct StoneMillApp: App {

    @State private var coordinator: AppCoordinator

    init() {
        var inMemory = false
        #if DEBUG
        // UI tests and screenshot runs must not pollute, or depend on, the
        // simulator's persistent history.
        inMemory = UITestScenario.current != nil
        #endif
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
            let container = try ModelContainer(for: MatchRecord.self, configurations: configuration)
            self.coordinator = AppCoordinator(modelContainer: container)
        } catch {
            fatalError("Could not create the match history container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup(id: SceneID.setup.rawValue) {
            SetupView(coordinator: coordinator)
                .installSceneOpener(coordinator)
        }
        .modelContainer(coordinator.modelContainer)
        .defaultSize(width: 640, height: 760)

        WindowGroup(id: SceneID.board.rawValue) {
            BoardVolumeView(coordinator: coordinator)
                .installSceneOpener(coordinator)
                .onDisappear {
                    coordinator.handleSceneDisappeared(.board)
                }
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 0.85, height: 0.55, depth: 0.85, in: .meters)

        ImmersiveSpace(id: SceneID.excavation.rawValue) {
            ExcavationImmersiveView(coordinator: coordinator)
                .installSceneOpener(coordinator)
                .onDisappear {
                    coordinator.handleSceneDisappeared(.excavation)
                }
        }
        .immersionStyle(selection: .constant(.full), in: .full)
    }
}
