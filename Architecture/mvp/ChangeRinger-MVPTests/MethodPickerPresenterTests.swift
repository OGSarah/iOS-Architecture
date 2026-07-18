//
//  MethodPickerPresenterTests.swift
//  ChangeRinger-MVPTests
//
//  Created by Sarah Clark on 7/17/26.
//

import Testing
@testable import ChangeRinger_MVP

/// A spy for the method picker view, recording the methods it was told to display.
@MainActor
private final class SpyMethodPickerView: MethodPickerView {
    private(set) var methods: [MethodChoice] = []
    func display(methods: [MethodChoice]) { self.methods = methods }
}

/// Tests for the method picker presenter.
@MainActor
struct MethodPickerPresenterTests {

    @Test("Starting displays every method with its stage and notation")
    func startDisplaysMethods() {
        let spy = SpyMethodPickerView()
        let presenter = MethodPickerPresenter(methods: Method.library) { _ in }
        presenter.view = spy
        presenter.start()

        #expect(spy.methods.count == Method.library.count)
        #expect(spy.methods.first?.name == "Plain Bob Doubles")
        #expect(spy.methods.contains { $0.detail.contains("Minor") })
    }

    @Test("Selecting a method reports the chosen method")
    func selectingReportsMethod() {
        var chosen: Method?
        let presenter = MethodPickerPresenter(methods: Method.library) { chosen = $0 }
        presenter.view = SpyMethodPickerView()
        presenter.start()

        presenter.didSelectMethod(at: 1)

        #expect(chosen == Method.plainBobMinor)
    }

    @Test("Selecting out of range does nothing")
    func selectingOutOfRangeIsIgnored() {
        var chosen: Method?
        let presenter = MethodPickerPresenter(methods: Method.library) { chosen = $0 }
        presenter.view = SpyMethodPickerView()
        presenter.start()

        presenter.didSelectMethod(at: 99)

        #expect(chosen == nil)
    }
}
