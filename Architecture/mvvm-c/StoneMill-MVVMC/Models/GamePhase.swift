//
//  GamePhase.swift
//  StoneMill-MVVMC
//
//  Created by Sarah Clark on 7/16/26.
//

import Foundation

/// The phase a game, or a single player, is currently in.
///
/// Placing lasts until both players have set down all nine pieces. Moving and
/// flying are per player: one side can be flying while the other is still
/// sliding, and that asymmetry is usually what decides the endgame.
nonisolated enum GamePhase: String, Equatable, Codable, Sendable {

    /// Players take turns placing one piece on any empty point.
    case placing

    /// Pieces slide one step per turn to an adjacent empty point along a line.
    case moving

    /// A player reduced to exactly three pieces may move to any empty point.
    case flying

    /// The match has a result and no further moves are legal.
    case gameOver
}
