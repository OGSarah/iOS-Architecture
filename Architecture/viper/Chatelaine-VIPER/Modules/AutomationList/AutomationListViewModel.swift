//
//  AutomationListViewModel.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// Everything the AutomationList View is allowed to see.
struct AutomationListViewModel: Equatable {

    struct Row: Equatable, Identifiable {
        let id: String
        let name: String
        let detail: String
        let accessibilityLabel: String
    }

    let title: String
    /// A message shown when there are no automations yet.
    let emptyMessage: String?
    let rows: [Row]
}
