//
//  BoardVolumeView.swift
//  StoneMill-MVVMC
//
//  Created by Sarah Clark on 7/16/26.
//

import RealityKit
import SwiftUI
import TabletopKit

/// The volumetric window holding the board.
///
/// The view renders whatever ``BoardViewModel`` the coordinator has active.
/// All rule decisions live in the ViewModel; all stone movement goes through
/// ``StoneMillTabletopGame/sync(to:)``; this file only wires them together
/// and draws the ornaments.
struct BoardVolumeView: View {

    /// The coordinator, read for the active board ViewModel.
    let coordinator: AppCoordinator

    var body: some View {
        Group {
            if let viewModel = coordinator.activeBoardViewModel {
                BoardContentView(viewModel: viewModel)
                    .id(ObjectIdentifier(viewModel))
            } else {
                ContentUnavailableView(
                    "No match is running",
                    systemImage: "circle.grid.cross",
                    description: Text("Start a match from the setup window.")
                )
            }
        }
    }
}

/// The equatable bundle of highlight inputs, read in the body so Observation
/// tracks them, and forwarded to the renderer when they change.
private struct HighlightState: Equatable {
    var selectable: Set<Int>
    var capturable: Set<Int>
    var selected: Int?
    var mill: [Int]?
}

/// The live board for one match: the RealityKit volume, the TabletopKit
/// wiring, the status ornament, and the results card.
private struct BoardContentView: View {

    let viewModel: BoardViewModel

    @State private var game: StoneMillTabletopGame

    init(viewModel: BoardViewModel) {
        self.viewModel = viewModel
        self.game = StoneMillTabletopGame()
    }

    var body: some View {
        let highlights = HighlightState(
            selectable: viewModel.selectablePoints,
            capturable: viewModel.capturablePieces,
            selected: viewModel.selectedPoint,
            mill: viewModel.highlightedMill
        )
        GeometryReader3D { proxy in
            RealityView { content in
                content.add(game.root)
                // Rest the table on the floor of the volume.
                let frame = content.convert(proxy.frame(in: .local), from: .local, to: .scene)
                game.root.position.y = frame.min.y
                game.sync(to: viewModel.gameState)
                viewModel.onStateChange = { [weak game] state in
                    game?.sync(to: state)
                }
            }
        }
        .tabletopGame(game.tabletopGame, parent: game.root) { _ in
            InteractionHandler(viewModel: viewModel, game: game)
        }
        .onChange(of: highlights, initial: true) { _, new in
            game.updateHighlights(
                selectable: new.selectable,
                capturable: new.capturable,
                selected: new.selected,
                mill: new.mill
            )
        }
        .ornament(attachmentAnchor: .scene(.bottomFront)) {
            statusOrnament
        }
        .ornament(attachmentAnchor: .scene(.front)) {
            if viewModel.interaction == .matchOver {
                resultsCard
            }
        }
        #if DEBUG
        .ornament(attachmentAnchor: .scene(.back)) {
            if UITestScenario.isDriving {
                UITestControlStrip(viewModel: viewModel)
            }
        }
        #endif
    }

    /// The status line and the reset control, floating under the board.
    private var statusOrnament: some View {
        HStack(spacing: 16) {
            Text(viewModel.statusText)
                .font(.headline)
                .accessibilityIdentifier(AXID.Board.status)
            Button {
                viewModel.resetMatch()
            } label: {
                Label("Start over", systemImage: "arrow.counterclockwise")
                    .labelStyle(.iconOnly)
            }
            .accessibilityIdentifier(AXID.Board.resetButton)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .glassBackgroundEffect()
    }

    /// The card shown when the match ends, offering the excavation visit.
    private var resultsCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "crown.fill")
                .font(.largeTitle)
                .foregroundStyle(Color(.sandLight))
            Text(viewModel.statusText)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            Text("This board has been carved into temples, ship decks, and cloister benches. See where it was actually found.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 12) {
                Button {
                    viewModel.resetMatch()
                } label: {
                    Label("Play again", systemImage: "arrow.counterclockwise")
                }
                Button {
                    viewModel.excavationTapped()
                } label: {
                    Label("Visit the excavation", systemImage: "mountain.2.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(.stoneDeep))
                .accessibilityIdentifier(AXID.Board.excavationButton)
            }
        }
        .padding(26)
        .frame(maxWidth: 460)
        .glassBackgroundEffect()
    }
}

#if DEBUG

/// A control strip rendered only under a `UITEST_SCENARIO` launch, so UI
/// tests can drive a scripted match through the same ViewModel intents the
/// tabletop uses, without 3D hit testing.
private struct UITestControlStrip: View {

    let viewModel: BoardViewModel

    var body: some View {
        VStack(spacing: 4) {
            Text("UI test controls")
                .font(.caption2)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(40)), count: 12), spacing: 4) {
                ForEach(0..<Board.pointCount, id: \.self) { point in
                    Button("\(point)") {
                        viewModel.pointTapped(point)
                    }
                    .font(.caption2)
                    .accessibilityIdentifier(AXID.Board.point(point))
                }
                ForEach(0..<Board.pointCount, id: \.self) { point in
                    Button("c\(point)") {
                        viewModel.commitCapture(at: point)
                    }
                    .font(.caption2)
                    .accessibilityIdentifier(AXID.Board.capture(point))
                }
            }
        }
        .padding(12)
        .glassBackgroundEffect()
    }
}

#endif
