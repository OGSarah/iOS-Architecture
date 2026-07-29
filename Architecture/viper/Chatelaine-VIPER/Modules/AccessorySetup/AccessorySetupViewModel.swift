//
//  AccessorySetupViewModel.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// Everything the AccessorySetup View renders.
struct AccessorySetupViewModel: Equatable {
    let title: String
    /// A short explanation, which becomes the unavailable message when setup cannot run.
    let message: String
    let addButtonTitle: String
    /// Whether the add button is tappable. It is disabled when commissioning is unavailable.
    let isAddEnabled: Bool
}
