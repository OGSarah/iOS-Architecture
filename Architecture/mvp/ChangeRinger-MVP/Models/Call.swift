//
//  Call.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

import Foundation

/// A call: an instruction that substitutes different notation for the lead-end change.
///
/// Most leads are rung plain. A conductor can call a bob or a single at a lead end to
/// alter the course of the composition, which is how a method is joined to itself to
/// produce a longer, true touch. A call is legal only at a lead end, the one position in
/// the method's cycle where the calling notation is defined, so a call is never a free
/// edit and the engine can refuse one placed anywhere else.
///
/// `Call` is a pure Model type with no knowledge of UIKit.
nonisolated enum Call: String, CaseIterable, Sendable, Hashable {

    /// No call: the lead is rung with its plain lead-end change.
    case plain

    /// A bob: the most common call, substituting the method's bob lead-end change.
    case bob

    /// A single: substitutes the method's single lead-end change.
    case single

    /// The short symbol a conductor would call, used on the call strip and in labels.
    ///
    /// A plain lead has no symbol because it is the absence of a call.
    var symbol: String {
        switch self {
            case .plain: return ""
            case .bob: return "-"
            case .single: return "s"
        }
    }

    /// The human-readable name of the call, suitable for a VoiceOver label.
    var name: String {
        switch self {
            case .plain: return "Plain"
            case .bob: return "Bob"
            case .single: return "Single"
        }
    }
}
