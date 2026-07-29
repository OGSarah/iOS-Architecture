//
//  AutomationBuilderViewModel.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// The initial configuration the builder View renders.
struct AutomationBuilderViewModel: Equatable {
    let title: String
    let defaultName: String
    let defaultLower: Double
    let defaultUpper: Double
    /// The characteristic id the form defaults its event and action to.
    let defaultCharacteristicID: String
}
