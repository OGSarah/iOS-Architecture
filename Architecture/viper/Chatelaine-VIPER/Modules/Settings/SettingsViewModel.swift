//
//  SettingsViewModel.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// Everything the Settings screen renders.
struct SettingsViewModel: Equatable {
    let title: String
    let animationsRowTitle: String
    let animationsEnabled: Bool
    /// Explains that the toggle combines with the system Reduce Motion setting.
    let animationsFootnote: String
    let replayTitle: String
    let appearanceNote: String
    let versionText: String
}
