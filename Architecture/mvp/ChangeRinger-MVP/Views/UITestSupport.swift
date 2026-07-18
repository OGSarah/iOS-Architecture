//
//  UITestSupport.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

#if DEBUG
import Foundation

/// A scenario the UI tests select through the `UITEST_SCENARIO` launch environment value.
///
/// The app reads this only in DEBUG builds. When a scenario is set, a document created from
/// the browser is seeded with a fixture touch, so a UI test never has to build a composition
/// by tapping out hundreds of rows.
enum UITestScenario: String {

    /// A true, comes-round touch: the plain course of Plain Bob Minor.
    case trueTouch

    /// A false touch, so the truth banner appears.
    case falseTouch

    /// A true touch used to exercise the conflict-resolution flow.
    case conflict

    /// The scenario named by the launch environment, if any.
    static var current: UITestScenario? {
        ProcessInfo.processInfo.environment["UITEST_SCENARIO"].flatMap(UITestScenario.init(rawValue:))
    }

    /// The fixture touch for the scenario.
    func makeTouch() -> Touch {
        switch self {
            case .trueTouch, .conflict:
                return Touch(method: .plainBobMinor)
            case .falseTouch:
                return TouchFixtures.falsePlainBobMinor
        }
    }

    /// Sample conflicting versions used to demonstrate the conflict sheet in DEBUG.
    static let sampleConflictVersions: [DocumentVersion] = [
        DocumentVersion(id: UUID(), title: "This device", detail: "Modified today, 60 rows"),
        DocumentVersion(id: UUID(), title: "Sarah's iPad", detail: "Modified today, 72 rows")
    ]
}
#endif
