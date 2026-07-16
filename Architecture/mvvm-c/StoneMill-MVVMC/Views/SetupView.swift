//
//  SetupView.swift
//  StoneMill-MVVMC
//
//  Created by Sarah Clark on 7/16/26.
//

import SwiftUI

/// The setup window: choose an opponent, name the players, read the rules
/// primer, and browse finished matches.
///
/// The view forwards every intent to its ``SetupViewModel`` and binds its
/// navigation path to the coordinator. It never names another screen and
/// never opens a scene.
struct SetupView: View {

    /// The coordinator, which owns the navigation path and vends ViewModels.
    let coordinator: AppCoordinator

    @State private var viewModel: SetupViewModel

    /// Creates the setup window for a coordinator.
    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        self.viewModel = coordinator.makeSetupViewModel()
    }

    var body: some View {
        @Bindable var coordinator = coordinator
        NavigationStack(path: $coordinator.setupPath) {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    opponentPicker
                    nameFields
                    validationAndStart
                    rulesPrimer
                    historyLink
                }
                .padding(28)
            }
            .background {
                LinearGradient(
                    colors: [Color(.sandLight).opacity(0.35), Color(.sandMid).opacity(0.2)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
            .navigationDestination(for: SetupDestination.self) { destination in
                switch destination {
                case .history:
                    MatchHistoryView(viewModel: coordinator.makeMatchHistoryViewModel())
                }
            }
        }
        .task {
            coordinator.applyUITestScenarioIfNeeded()
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("StoneMill")
                .font(.extraLargeTitle)
                .foregroundStyle(Color(.umber))
            Text("Nine Men's Morris, carved in stone for two thousand years")
                .font(.subheadline)
                .foregroundStyle(Color(.stoneDeep))
        }
        .padding(.top, 8)
    }

    private var opponentPicker: some View {
        HStack(spacing: 16) {
            opponentCard(
                kind: .hotSeat,
                title: "Two players",
                subtitle: "Take turns at this table",
                systemImage: "person.2.fill",
                identifier: AXID.Setup.hotSeatCard
            )
            opponentCard(
                kind: .computer,
                title: "Play Millstone",
                subtitle: "A patient, greedy engine",
                systemImage: "gearshape.2.fill",
                identifier: AXID.Setup.computerCard
            )
        }
        .accessibilityIdentifier(AXID.Setup.opponentPicker)
    }

    private func opponentCard(
        kind: OpponentKind,
        title: String,
        subtitle: String,
        systemImage: String,
        identifier: String
    ) -> some View {
        let isSelected = viewModel.opponentKind == kind
        return Button {
            viewModel.opponentKind = kind
        } label: {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.largeTitle)
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
        .buttonStyle(.plain)
        .background(isSelected ? Color(.sandLight).opacity(0.5) : Color.clear, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isSelected ? Color(.stoneDeep) : Color(.sandMid).opacity(0.4), lineWidth: isSelected ? 3 : 1)
        }
        .accessibilityIdentifier(identifier)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var nameFields: some View {
        VStack(spacing: 12) {
            TextField("Light player's name", text: $viewModel.lightPlayerName)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier(AXID.Setup.lightName)
            if viewModel.opponentKind == .hotSeat {
                TextField("Dark player's name", text: $viewModel.darkPlayerName)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier(AXID.Setup.darkName)
            } else {
                Label("Millstone plays the dark stones", systemImage: "gearshape.2")
                    .font(.callout)
                    .foregroundStyle(Color(.stoneDeep))
            }
        }
    }

    private var validationAndStart: some View {
        VStack(spacing: 12) {
            if let message = viewModel.validationMessage {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(Color(.umberDark))
                    .accessibilityIdentifier(AXID.Setup.validationLabel)
            }
            Button {
                viewModel.startTapped()
            } label: {
                Text("Start the match")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(.stoneDeep))
            .disabled(!viewModel.canStart)
            .accessibilityIdentifier(AXID.Setup.startButton)
        }
    }

    private var rulesPrimer: some View {
        DisclosureGroup(isExpanded: $viewModel.isRulesPrimerPresented) {
            RulesPrimerView()
                .padding(.top, 12)
        } label: {
            Label("How to play", systemImage: "book.closed")
                .font(.headline)
                .foregroundStyle(Color(.umber))
        }
        .padding(16)
        .background(Color(.sandLight).opacity(0.35), in: .rect(cornerRadius: 16))
        .accessibilityIdentifier(AXID.Setup.rulesToggle)
    }

    private var historyLink: some View {
        Button {
            viewModel.historyTapped()
        } label: {
            Label("Finished matches", systemImage: "clock.arrow.circlepath")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.bordered)
        .tint(Color(.umber))
        .accessibilityIdentifier(AXID.Setup.historyLink)
    }
}

/// The rules primer: the goal, the three phases, and the four rules that
/// carry all the strategy.
private struct RulesPrimerView: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Reduce your opponent to two stones, or leave them with no legal move. Three of your stones in a straight line form a mill, which removes one enemy stone.")
                .font(.callout)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                phaseRow("Placing", "Take turns placing one stone on any empty point until all 18 are down")
                phaseRow("Moving", "Slide one stone per turn to an adjacent empty point along a line")
                phaseRow("Flying", "At exactly three stones, move to any empty point on the board")
            }

            VStack(alignment: .leading, spacing: 8) {
                ruleRow("A mill you break and re-form still counts, and captures again.")
                ruleRow("You may not capture a stone in a mill, unless every enemy stone is in one.")
                ruleRow("Being blocked is a loss, not a stalemate.")
                ruleRow("Mills only capture on the turn they form. A standing mill does nothing.")
            }
        }
        .foregroundStyle(Color(.umber))
    }

    private func phaseRow(_ name: String, _ detail: String) -> some View {
        GridRow(alignment: .top) {
            Text(name)
                .font(.callout.bold())
                .gridColumnAlignment(.leading)
            Text(detail)
                .font(.callout)
        }
    }

    private func ruleRow(_ text: String) -> some View {
        Label {
            Text(text).font(.callout)
        } icon: {
            Image(systemName: "diamond.fill")
                .font(.system(size: 8))
                .foregroundStyle(Color(.stoneDeep))
        }
    }
}
