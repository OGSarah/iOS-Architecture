//
//  MatchHistoryView.swift
//  StoneMill-MVVMC
//
//  Created by Sarah Clark on 7/16/26.
//

import SwiftUI

/// The finished match list, pushed inside the setup window.
///
/// A dumb renderer of ``MatchHistoryViewModel``: it reloads on appearance,
/// shows the records newest first, and forwards deletions.
struct MatchHistoryView: View {

    @State private var viewModel: MatchHistoryViewModel

    /// Creates the list over a coordinator built ViewModel.
    init(viewModel: MatchHistoryViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            if viewModel.records.isEmpty {
                ContentUnavailableView {
                    Label("No finished matches", systemImage: "circle.grid.cross")
                        .foregroundStyle(Color(.umber))
                } description: {
                    Text("Matches you finish on the board will be recorded here.")
                }
                .accessibilityIdentifier(AXID.History.emptyState)
            } else {
                List {
                    ForEach(viewModel.records) { record in
                        MatchRecordRow(record: record)
                    }
                    .onDelete { offsets in
                        for offset in offsets {
                            viewModel.delete(viewModel.records[offset])
                        }
                    }
                }
                .accessibilityIdentifier(AXID.History.list)
            }
        }
        .navigationTitle("Finished matches")
        .task {
            viewModel.reload()
        }
    }
}

/// One finished match: winner, opponent kind, reason, length, and date.
private struct MatchRecordRow: View {

    let record: MatchRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(record.winnerName)
                    .font(.headline)
                    .foregroundStyle(Color(.umber))
                Text("beat \(record.loserName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(record.opponentKind == OpponentKind.computer.rawValue ? "vs Millstone" : "Two players")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.sandLight).opacity(0.5), in: .capsule)
                    .foregroundStyle(Color(.stoneDeep))
            }
            HStack {
                Text("\(record.loserName.isEmpty ? "The loser" : record.loserName) was \(record.reasonSummary) after \(record.moveCount) moves")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(record.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}
