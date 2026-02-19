// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing

import XCTest
import SnapKit
import Common
import Shared

@testable import Client

@MainActor
final class ToolbarAnimatorTests: XCTestCase {
    var mockView: MockToolbarView!
    var context: ToolbarContext!
    var delegate: MockToolbarAnimatorDelegate!

    override func setUp() async throws {
        try await super.setUp()
        mockView = MockToolbarView()
        context = ToolbarContext(overKeyboardContainerHeight: 20,
                                 bottomContainerHeight: 80,
                                 headerHeight: -44)
        delegate = MockToolbarAnimatorDelegate()
    }

    override func tearDown() async throws {
        mockView = nil
        context = nil
        delegate = nil
        try await super.tearDown()
    }

    func test_updateToolbarTransition_collapsed_hidesTopToolbar() {
        let subject = createSubject()
        mockView.isBottomSearchBar = false

        subject.updateToolbarTransition(progress: 30, towards: .collapsed)

        XCTAssertNotEqual(mockView.header.transform, .identity)
        XCTAssertNotEqual(mockView.topBlurView.transform, .identity)
    }

    func test_updateToolbarTransition_hidesBottomToolbar() {
        let subject = createSubject()
        mockView.isBottomSearchBar = true

        subject.updateToolbarTransition(progress: 25, towards: .collapsed)

        XCTAssertNotEqual(mockView.bottomContainer.transform, .identity)
        XCTAssertNotEqual(mockView.overKeyboardContainer.transform, .identity)
        XCTAssertNotEqual(mockView.bottomBlurView.transform, .identity)
    }

    func test_showToolbar_resetsTransforms() {
        let subject = createSubject()
        mockView.header.transform = CGAffineTransform(translationX: 0, y: -10)
        mockView.bottomContainer.transform = CGAffineTransform(translationX: 0, y: 10)

        subject.showToolbar()

        XCTAssertEqual(mockView.header.transform, .identity)
        XCTAssertEqual(mockView.bottomContainer.transform, .identity)
    }

    func test_showToolbar_delegateIsCalled() {
        let subject = createSubject()
        subject.showToolbar()

        XCTAssertEqual(delegate.receivedAlphaValue, 1)
    }

    func test_hideToolbar_delegateIsCalled() {
        let subject = createSubject()
        subject.hideToolbar()

        XCTAssertEqual(delegate.receivedAlphaValue, 0)
    }

    func test_noCrash_whenViewIsNil() {
        let subject = createSubject()
        subject.view = nil

        XCTAssertNoThrow(subject.showToolbar())
        XCTAssertNoThrow(subject.hideToolbar())
        XCTAssertNoThrow(subject.updateToolbarTransition(progress: 10, towards: .collapsed))
    }

    // MARK: - Private
    private func createSubject() -> ToolbarAnimator {
        let subject = ToolbarAnimator(context: context)
        subject.view = mockView
        subject.delegate = delegate
        trackForMemoryLeaks(subject)
        return subject
    }
}

// MARK: - Mock ToolbarView
final class MockToolbarView: ToolbarViewProtocol {
    var header = BaseAlphaStackView()
    var topBlurView = UIVisualEffectView()
    var bottomContainer = BaseAlphaStackView()
    var bottomBlurView = UIVisualEffectView()
    var overKeyboardContainer = BaseAlphaStackView()
    var isBottomSearchBar = false
    var headerTopConstraint: Constraint?
    var bottomContainerConstraint: ConstraintReference?
    var overKeyboardContainerConstraint: Constraint?
}

// MARK: - Mock Delegate
final class MockToolbarAnimatorDelegate: ToolbarAnimator.Delegate {
    var receivedAlphaValue: CGFloat = 0

    func dispatchScrollAlphaChange(alpha: CGFloat) {
        receivedAlphaValue = alpha
    }
}
