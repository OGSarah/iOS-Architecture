//
//  MethodPickerView.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

import Foundation

/// One method as the picker should list it, formatted by the presenter.
struct MethodChoice: Sendable, Equatable {

    /// The method's name, such as `"Plain Bob Minor"`.
    let name: String

    /// A secondary line describing the stage and notation.
    let detail: String
}

/// The passive view of the method picker: the commands its presenter can issue.
///
/// As with the editor, the view owns no state and makes no decisions. The presenter formats
/// the list of methods and tells the view to show it, and the view forwards the user's
/// selection straight back.
@MainActor
protocol MethodPickerView: AnyObject {

    /// Shows the list of methods to choose from.
    ///
    /// - Parameter methods: The formatted method choices, in order.
    func display(methods: [MethodChoice])
}
