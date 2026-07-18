//
//  TruthCheckerTests.swift
//  ChangeRinger-MVPTests
//
//  Created by Sarah Clark on 7/17/26.
//

import Testing
@testable import ChangeRinger_MVP

/// Tests for the truth checker: a true touch, a touch that repeats a row, a touch that never
/// comes round, and one that comes round early. The reported index is asserted, not just the
/// boolean, since that index is the exact row the editor marks.
struct TruthCheckerTests {

    @Test("A true touch reports no false row and comes round")
    func trueTouch() {
        guard case .success(let rows) = RingingEngine.expand(Touch(method: .plainBobMinor)) else {
            Issue.record("Expected expansion")
            return
        }
        let report = TruthChecker.check(rows)
        #expect(report.isTrue)
        #expect(report.firstFalseRowIndex == nil)
        #expect(report.comesRound)
        #expect(report.comeRoundIndex == 60)
    }

    @Test("A false touch reports the exact repeating row")
    func falseTouchReportsIndex() {
        guard case .success(let rows) = RingingEngine.expand(TouchFixtures.falsePlainBobMinor) else {
            Issue.record("Expected expansion")
            return
        }
        let report = TruthChecker.check(rows)
        #expect(!report.isTrue)
        #expect(report.firstFalseRowIndex == TouchFixtures.falsePlainBobMinorFirstFalseRow)
    }

    @Test("A touch that never comes round is reported as such")
    func neverComesRound() {
        let rounds = Stage.minor.rounds
        let rows = [rounds, Row(bells: [2, 1, 4, 3, 6, 5]), Row(bells: [2, 4, 1, 6, 3, 5])]
        let report = TruthChecker.check(rows)
        #expect(!report.comesRound)
        #expect(report.comeRoundIndex == nil)
        #expect(report.isTrue)
    }

    @Test("A touch that comes round early is reported at that index")
    func comesRoundEarly() {
        let rounds = Stage.minor.rounds
        let rows = [rounds, Row(bells: [2, 1, 4, 3, 6, 5]), rounds]
        let report = TruthChecker.check(rows)
        #expect(report.comesRound)
        #expect(report.comeRoundIndex == 2)
        #expect(report.isTrue)
    }

    @Test("Truth holds over a full extent of distinct rows")
    func fullExtentIsTrue() {
        let rows = allRows(bellCount: 6)
        #expect(rows.count == 720)
        let report = TruthChecker.check(rows)
        #expect(report.isTrue)
        #expect(report.firstFalseRowIndex == nil)
    }

    @Test("A repeat anywhere in a large sequence is caught at its index")
    func repeatInLargeSequenceIsCaught() {
        var rows = allRows(bellCount: 6)
        rows[500] = rows[10]
        let report = TruthChecker.check(rows)
        #expect(!report.isTrue)
        #expect(report.firstFalseRowIndex == 500)
    }
}
