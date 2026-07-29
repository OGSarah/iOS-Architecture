//
//  ServiceControlViewModel.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// Everything the ServiceControl View is allowed to see, already formatted and already decided.
///
/// There is no `CharacteristicSnapshot` here and certainly no `HMCharacteristic`. Values are strings
/// the View renders verbatim and control kinds the View binds to cells without interpretation.
struct ServiceControlViewModel: Equatable {

    /// One row of the service, corresponding to one characteristic.
    struct Row: Equatable, Identifiable {
        let id: String
        /// The characteristic's display name, for example "Brightness".
        let title: String
        /// The current value already rendered as text, for example "60%".
        let valueText: String
        /// The control the View should draw for this row.
        let control: ControlKind
        /// Whether the control accepts input right now.
        let isEnabled: Bool
        /// An inline reason shown after a rejected write, or `nil` when there is none.
        let reason: String?
        /// The accessibility label the View should expose for the control.
        let accessibilityLabel: String
    }

    /// The service's name, used as the screen title.
    let title: String
    /// A short reachability note shown under the title, or `nil` when reachable.
    let statusNote: String?
    /// The rows, one per characteristic, in display order.
    let rows: [Row]
}
