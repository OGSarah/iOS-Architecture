//
//  MethodPickerPresenter.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

import Foundation

/// The presenter for the method picker.
///
/// It holds the list of methods to offer, formats each one for display, and reports the
/// user's choice through an injected closure. Like every presenter here, it talks to its
/// view only through a protocol and never references a view controller.
@MainActor
final class MethodPickerPresenter {

    /// The passive picker view this presenter commands.
    weak var view: MethodPickerView?

    /// The methods offered, in display order.
    private let methods: [Method]

    /// The callback invoked with the chosen method.
    private let onSelect: (Method) -> Void

    /// Creates the picker presenter.
    ///
    /// - Parameters:
    ///   - methods: The methods to offer. Defaults to the built-in library.
    ///   - onSelect: Called with the method the user selects.
    init(methods: [Method] = Method.library, onSelect: @escaping (Method) -> Void) {
        self.methods = methods
        self.onSelect = onSelect
    }

    /// Formats the methods and tells the view to display them.
    func start() {
        let choices = methods.map { method in
            MethodChoice(
                name: method.name,
                detail: "\(method.stage.name), \(PlaceNotation.string(from: method.plainLead))"
            )
        }
        view?.display(methods: choices)
    }

    /// Reports the method chosen at a list position.
    ///
    /// - Parameter index: The selected row's index.
    func didSelectMethod(at index: Int) {
        guard methods.indices.contains(index) else { return }
        onSelect(methods[index])
    }
}
