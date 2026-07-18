//
//  Touch.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

import Foundation

/// A touch: a composition to be rung, defined by a method and the calls placed in it.
///
/// A touch is edited rather than rung directly. It stores the method and the set of calls,
/// each pinned to the lead-end row it applies at. The `RingingEngine` turns a touch into
/// the actual rows. A touch is a value type, so editing it, inserting a call or changing
/// the method, produces a new touch and never mutates a rung sequence in place.
///
/// `Touch` is a pure Model type with no knowledge of UIKit.
nonisolated struct Touch: Sendable, Hashable {

    /// The method being rung.
    var method: Method

    /// The calls in the touch, keyed by the row index of the lead end they apply at.
    ///
    /// A row index counts rows from rounds, which is row `0`. A lead end falls on every
    /// multiple of the method's lead length. Only bobs and singles are stored; a plain
    /// lead is simply the absence of an entry.
    var calls: [Int: Call]

    /// The greatest number of leads the engine will ring before giving up on coming round.
    ///
    /// This is a safety bound so an invalid touch that never returns to rounds still
    /// produces a finite sequence. It defaults to a little more than a full extent's worth
    /// of leads, which is ample for any true touch at the stage.
    var maxLeads: Int

    /// Creates a touch.
    ///
    /// - Parameters:
    ///   - method: The method to ring.
    ///   - calls: The calls, keyed by lead-end row index. Defaults to none.
    ///   - maxLeads: The safety bound on leads. Defaults to a full extent plus slack.
    init(method: Method, calls: [Int: Call] = [:], maxLeads: Int? = nil) {
        self.method = method
        self.calls = calls
        self.maxLeads = maxLeads ?? (method.stage.extentLength / method.leadLength + 2)
    }

    /// Whether a row index falls exactly on a lead end, where a call is legal.
    ///
    /// - Parameter rowIndex: The row index, counting rounds as row `0`.
    /// - Returns: `true` if a call may be placed at this row.
    func isLeadEnd(rowIndex: Int) -> Bool {
        rowIndex > 0 && rowIndex % method.leadLength == 0
    }

    /// Returns a copy of the touch with a call placed at the given lead-end row.
    ///
    /// Placing `.plain` removes any existing call at that row. This method does not judge
    /// legality: it will store a call at any row so the presenter can hand the result to
    /// the engine and let the engine be the single authority that accepts or rejects it.
    ///
    /// - Parameters:
    ///   - call: The call to place.
    ///   - rowIndex: The lead-end row index to place it at.
    /// - Returns: A new touch with the call applied.
    func placing(_ call: Call, atRowIndex rowIndex: Int) -> Touch {
        var copy = self
        if call == .plain {
            copy.calls[rowIndex] = nil
        } else {
            copy.calls[rowIndex] = call
        }
        return copy
    }
}
