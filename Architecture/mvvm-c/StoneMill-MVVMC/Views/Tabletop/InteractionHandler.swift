//
//  InteractionHandler.swift
//  StoneMill-MVVMC
//
//  Created by Sarah Clark on 7/16/26.
//

import Spatial
import TabletopKit

/// Translates TabletopKit gestures into ``BoardViewModel`` intents.
///
/// There is no rule logic in this file: it maps equipment identifiers to
/// board points, asks the ViewModel whether the intent is legal, and either
/// lets the drop snap or cancels the gesture so the stone glides home. Taps
/// on spots and capturable stones go through the same ``BoardViewModel/pointTapped(_:)``
/// fallback the debug control strip uses.
@MainActor
final class InteractionHandler: TabletopInteraction.Delegate {

    private weak var viewModel: BoardViewModel?
    private weak var game: StoneMillTabletopGame?

    /// Creates a handler forwarding to a ViewModel and its renderer.
    init(viewModel: BoardViewModel, game: StoneMillTabletopGame) {
        self.viewModel = viewModel
        self.game = game
    }

    func update(interaction: TabletopInteraction) {
        switch interaction.value.phase {
        case .started:
            handleStart(of: interaction)
        case .ended:
            handleEnd(of: interaction)
        default:
            break
        }
    }

    /// Decides what a fresh gesture may do: capture with a tap, lift a stone
    /// and restrict its destinations, or cancel outright.
    private func handleStart(of interaction: TabletopInteraction) {
        guard let viewModel, let game else {
            interaction.cancel()
            return
        }
        let equipment = interaction.value.startingEquipmentID

        // A tap on a snap spot drives the select, move, capture loop directly.
        if let point = equipment.pointIndex {
            viewModel.pointTapped(point)
            interaction.cancel()
            return
        }

        guard let owner = equipment.pieceOwner else {
            interaction.cancel()
            return
        }

        // A tap on a capturable enemy stone removes it.
        if let point = game.point(of: equipment), viewModel.capturablePieces.contains(point) {
            viewModel.commitCapture(at: point)
            interaction.cancel()
            return
        }

        // Lifting an own stone on the board: restrict the drop to its legal
        // destinations.
        if let point = game.point(of: equipment) {
            guard viewModel.canLift(pieceAt: point) else {
                interaction.cancel()
                return
            }
            restrict(interaction, to: viewModel.destinations(forPieceAt: point))
            return
        }

        // Lifting a racked stone during placement: any empty point is legal.
        if game.isRacked(equipment),
           viewModel.isHumanTurn,
           owner == viewModel.gameState.currentPlayer,
           viewModel.gameState.phase(for: owner) == .placing,
           !viewModel.gameState.pendingCapture {
            restrict(interaction, to: Set(viewModel.gameState.emptyPoints))
            return
        }

        interaction.cancel()
    }

    /// Commits the drop through the rules engine and snaps or cancels.
    private func handleEnd(of interaction: TabletopInteraction) {
        guard let viewModel, let game else {
            interaction.cancel()
            return
        }
        let equipment = interaction.value.startingEquipmentID
        guard equipment.pieceOwner != nil,
              let destination = interaction.value.proposedDestination,
              let point = destination.equipmentID.pointIndex else {
            interaction.cancel()
            return
        }

        // Legality is checked before the render mapping is touched, so a
        // rejected drop can never leave a stone tracked at the wrong point.
        let accepted: Bool
        if let from = game.point(of: equipment),
           viewModel.destinations(forPieceAt: from).contains(point) {
            // Record the render before committing: the commit triggers
            // sync(to:), which must see this stone as already moved.
            game.noteGestureMove(of: equipment, to: point)
            accepted = viewModel.commitMove(from: from, to: point)
        } else if game.isRacked(equipment),
                  viewModel.selectablePoints.contains(point),
                  viewModel.gameState.points[point] == nil {
            game.noteGestureMove(of: equipment, to: point)
            accepted = viewModel.commitPlace(at: point)
        } else {
            accepted = false
        }

        guard accepted else {
            interaction.cancel()
            return
        }
        interaction.addAction(.moveEquipment(
            matching: equipment,
            childOf: destination.equipmentID,
            pose: TableVisualState.Pose2D(position: .init(x: 0, z: 0), rotation: .degrees(0))
        ))
    }

    private func restrict(_ interaction: TabletopInteraction, to points: Set<Int>) {
        let spots = points.map { EquipmentIdentifier.pointSpot($0) }
        interaction.setConfiguration(.init(allowedDestinations: .restricted(spots)))
    }
}
