//
//  HomeListViewModel.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// Everything the HomeList sidebar is allowed to see.
struct HomeListViewModel: Equatable {

    /// Whether a row names the home itself or one of its zones.
    enum Kind: Equatable {
        case home
        case zone
    }

    struct Row: Equatable, Identifiable {
        let id: String
        let name: String
        let subtitle: String
        let kind: Kind
        let accessibilityLabel: String
    }

    let title: String
    /// A message shown when there is nothing to list, for example before access is granted.
    let emptyMessage: String?
    let rows: [Row]
}
