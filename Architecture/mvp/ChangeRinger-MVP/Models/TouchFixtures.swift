//
//  TouchFixtures.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

import Foundation

/// Ready-made touches used by the seeded UI-test scenarios and by the unit tests.
///
/// Keeping them in the app target, rather than in a test file, lets both the DEBUG seeding
/// and the unit tests draw the same fixtures from one place. Each is a real composition the
/// engine expands, not a hand-written row list.
nonisolated enum TouchFixtures {

    /// A false touch: a single bob at the first lead end of Plain Bob Minor sends the ringing
    /// into rows it has already struck, so it repeats at row seventy-two and never comes
    /// round. The truth checker reports that exact false row. The calling was found with the
    /// engine itself, then pinned here.
    static let falsePlainBobMinor = Touch(method: .plainBobMinor, calls: [12: .bob])

    /// The row index at which ``falsePlainBobMinor`` first repeats, asserted by the tests.
    static let falsePlainBobMinorFirstFalseRow = 72

    /// A true bobbed touch: bobs at the first and fourth lead ends of Plain Bob Minor join
    /// two courses into a longer touch that stays true and comes round at row seventy-two.
    /// Adding the second bob to ``falsePlainBobMinor`` is what turns it true, which the
    /// presenter tests rely on.
    static let trueBobbedPlainBobMinor = Touch(method: .plainBobMinor, calls: [12: .bob, 48: .bob])
}
