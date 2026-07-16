//
//  AuroraWatch_MVVMApp.swift
//  AuroraWatch-MVVM Watch App
//
//  Created by Sarah Clark on 7/16/26.
//

import SwiftUI

/// The app entry point.
///
/// Builds the root scene and performs the one piece of composition the app
/// needs: choosing the ``ForecastService`` implementation. Everything below
/// this point receives the service by injection.
@main
struct AuroraWatch_MVVM_Watch_AppApp: App {

    var body: some Scene {
        WindowGroup {
            ForecastListView(service: Self.makeService())
        }
    }

    /// Chooses the forecast source for this launch.
    ///
    /// In DEBUG builds, a `UITEST_STUB_SCENARIO` environment value swaps in
    /// the fixture stub so UI tests never touch the live network. Every
    /// other launch talks to NOAA.
    private static func makeService() -> any ForecastService {
        #if DEBUG
        if let scenario = UITestStubScenario.fromEnvironment() {
            return UITestForecastStub(scenario: scenario)
        }
        #endif
        return LiveForecastService()
    }
}
