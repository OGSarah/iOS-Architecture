//
//  RingingEngineTests.swift
//  ChangeRinger-MVPTests
//
//  Created by Sarah Clark on 7/17/26.
//

import Testing
@testable import ChangeRinger_MVP

/// Tests for the ringing engine, the reason this domain was chosen. The cases run across the
/// four built-in methods and their four stages, and pin the three rules that make change
/// ringing worth modelling: a bell moves at most one place per change, a touch comes round,
/// and calls are legal only at lead ends.
struct RingingEngineTests {

    @Test("A plain course comes round", arguments: Method.library)
    func plainCourseComesRound(method: Method) {
        let result = RingingEngine.expand(Touch(method: method))
        guard case .success(let rows) = result else {
            Issue.record("Expected \(method.name) to expand")
            return
        }
        let report = TruthChecker.check(rows)
        #expect(report.comesRound)
        #expect(rows.first?.isRounds == true)
        #expect(rows.last?.isRounds == true)
    }

    @Test("A plain course is true", arguments: Method.library)
    func plainCourseIsTrue(method: Method) {
        guard case .success(let rows) = RingingEngine.expand(Touch(method: method)) else {
            Issue.record("Expected \(method.name) to expand")
            return
        }
        #expect(TruthChecker.check(rows).isTrue)
    }

    @Test("Every change moves each bell at most one place", arguments: Method.library)
    func everyChangeIsLegal(method: Method) {
        guard case .success(let rows) = RingingEngine.expand(Touch(method: method)) else {
            Issue.record("Expected \(method.name) to expand")
            return
        }
        for index in 1..<rows.count {
            #expect(rows[index - 1].changesLegally(to: rows[index]), "Illegal change at row \(index)")
        }
    }

    @Test("Every row is a valid permutation", arguments: Method.library)
    func everyRowIsAPermutation(method: Method) {
        guard case .success(let rows) = RingingEngine.expand(Touch(method: method)) else {
            Issue.record("Expected \(method.name) to expand")
            return
        }
        #expect(rows.allSatisfy { $0.isValidPermutation })
    }

    @Test("The plain course of Plain Bob Minor expands to sixty distinct rows")
    func plainBobMinorPlainCourseLength() {
        guard case .success(let rows) = RingingEngine.expand(Touch(method: .plainBobMinor)) else {
            Issue.record("Expected Plain Bob Minor to expand")
            return
        }
        // Sixty rows are rung before the closing return to rounds, and all sixty are distinct.
        let body = rows.dropLast()
        #expect(body.count == 60)
        #expect(Set(body).count == 60)
        #expect(rows.count == 61)
    }

    @Test("A call is rejected anywhere but a lead end")
    func callNotAtLeadEndIsRejected() {
        // Row five is not a lead end for Plain Bob Minor, whose lead length is twelve.
        let touch = Touch(method: .plainBobMinor, calls: [5: .bob])
        #expect(RingingEngine.expand(touch) == .failure(.callNotAtLeadEnd(rowIndex: 5)))
    }

    @Test("A call is accepted at a lead end")
    func callAtLeadEndIsAccepted() {
        let touch = Touch(method: .plainBobMinor, calls: [12: .bob])
        guard case .success = RingingEngine.expand(touch) else {
            Issue.record("Expected a call at a lead end to be accepted")
            return
        }
    }

    @Test("A bobbed touch stays true and comes round")
    func bobbedTouchIsTrue() {
        guard case .success(let rows) = RingingEngine.expand(TouchFixtures.trueBobbedPlainBobMinor) else {
            Issue.record("Expected the bobbed touch to expand")
            return
        }
        let report = TruthChecker.check(rows)
        #expect(report.isValid)
        #expect(report.comeRoundIndex == 72)
    }
}
