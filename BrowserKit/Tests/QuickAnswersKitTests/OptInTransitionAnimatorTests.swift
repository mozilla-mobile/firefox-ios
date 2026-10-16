// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import QuickAnswersKit
import TestKit
import UIKit
import XCTest

@MainActor
final class OptInTransitionAnimatorTests: XCTestCase {
    private var controller: UIViewController!
    private var fallback: SourceRevealTransitionAnimator!
    private var transitionContext: MockTransitionContext!
    private var isOptInSheetPending = false
    private let finalFrame = CGRect(x: 0, y: 100, width: 320, height: 500)

    override func setUp() async throws {
        try await super.setUp()
        controller = UIViewController()
        fallback = SourceRevealTransitionAnimator(sourceRect: .zero, isOptInVisible: false)
        transitionContext = MockTransitionContext()
        transitionContext.finalFrame = finalFrame
        isOptInSheetPending = false
    }

    override func tearDown() async throws {
        controller = nil
        fallback = nil
        transitionContext = nil
        try await super.tearDown()
    }

    // MARK: - animationController(forPresented:)
    func test_animationControllerForPresented_whenOptInSheetPending_returnsItself() {
        isOptInSheetPending = true
        let subject = createSubject()

        let animator = subject.animationController(forPresented: controller, presenting: controller, source: controller)

        XCTAssertTrue(animator === subject)
    }

    func test_animationControllerForPresented_whenOptInSheetNotPending_returnsFallbackAnimator() {
        let subject = createSubject()

        let animator = subject.animationController(forPresented: controller, presenting: controller, source: controller)

        XCTAssertTrue(animator === fallback)
    }

    func test_animationControllerForPresented_withoutFallback_returnsNil() {
        let subject = createSubject(hasFallback: false)

        let animator = subject.animationController(forPresented: controller, presenting: controller, source: controller)

        XCTAssertNil(animator)
    }

    // MARK: - animationController(forDismissed:)
    func test_animationControllerForDismissed_whenOptInSheetPending_returnsItself() {
        isOptInSheetPending = true
        let subject = createSubject()

        XCTAssertTrue(subject.animationController(forDismissed: controller) === subject)
    }

    func test_animationControllerForDismissed_whenOptInSheetNotPending_returnsFallbackAnimator() {
        let subject = createSubject()

        XCTAssertTrue(subject.animationController(forDismissed: controller) === fallback)
    }

    func test_animationControllerForDismissed_whenOptInCompletedAfterPresentation_returnsFallbackAnimator() {
        isOptInSheetPending = true
        let subject = createSubject()
        _ = subject.animationController(forPresented: controller, presenting: controller, source: controller)

        isOptInSheetPending = false

        XCTAssertTrue(subject.animationController(forDismissed: controller) === fallback)
    }

    // MARK: - transitionDuration
    func test_transitionDuration_isInstant() {
        let subject = createSubject()

        XCTAssertEqual(subject.transitionDuration(using: transitionContext), 0.0)
    }

    // MARK: - animateTransition
    func test_animateTransition_whenPresenting_hidesContainerAndCompletes() {
        transitionContext.toViewController = MockPresentedViewController()
        let subject = createSubject()

        subject.animateTransition(using: transitionContext)

        XCTAssertTrue(transitionContext.containerView.isHidden)
        XCTAssertTrue(subject.hiddenContainerView === transitionContext.containerView)
        XCTAssertEqual(transitionContext.completeTransitionCallCount, 1)
        XCTAssertEqual(transitionContext.lastDidComplete, true)
    }

    func test_animateTransition_whenPresenting_addsPresentedControllerViewAtFinalFrame() {
        let presentedController = MockPresentedViewController()
        transitionContext.toViewController = presentedController
        let subject = createSubject()

        subject.animateTransition(using: transitionContext)

        XCTAssertTrue(presentedController.view.superview === transitionContext.containerView)
        XCTAssertEqual(presentedController.view.frame, finalFrame)
    }

    func test_animateTransition_whenPresentingWithWrapperView_addsWrapperViewAtFinalFrame() {
        let wrapperView = UIView()
        transitionContext.toViewController = MockPresentedViewController()
        transitionContext.toView = wrapperView
        let subject = createSubject()

        subject.animateTransition(using: transitionContext)

        XCTAssertTrue(wrapperView.superview === transitionContext.containerView)
        XCTAssertEqual(wrapperView.frame, finalFrame)
    }

    func test_animateTransition_whenDismissing_keepsContainerVisibleAndCompletes() {
        let presentedController = MockPresentedViewController()
        presentedController.isBeingPresentedValue = false
        transitionContext.toViewController = presentedController
        let subject = createSubject()

        subject.animateTransition(using: transitionContext)

        XCTAssertFalse(transitionContext.containerView.isHidden)
        XCTAssertNil(subject.hiddenContainerView)
        XCTAssertTrue(transitionContext.containerView.subviews.isEmpty)
        XCTAssertEqual(transitionContext.completeTransitionCallCount, 1)
        XCTAssertEqual(transitionContext.lastDidComplete, true)
    }

    // MARK: - Helpers
    private func createSubject(
        hasFallback: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OptInTransitionAnimator {
        let subject = OptInTransitionAnimator(
            isOptInSheetPending: { [weak self] in self?.isOptInSheetPending ?? false },
            fallback: hasFallback ? fallback : nil
        )
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
