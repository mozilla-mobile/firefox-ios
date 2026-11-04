// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import QuickAnswersKit
import TestKit
import UIKit
import XCTest

@MainActor
final class ReturnToBrowserTransitionAnimatorTests: XCTestCase {
    private var controller: UIViewController!
    private var fallback: SourceRevealTransitionAnimator!
    private var transitionContext: MockTransitionContext!
    private var window: UIView!
    private var browserController: UIViewController!
    private var quickAnswersView: UIView!
    private var isActive = true
    private let finalFrame = CGRect(x: 0, y: 0, width: 320, height: 500)

    override func setUp() async throws {
        try await super.setUp()
        controller = UIViewController()
        fallback = SourceRevealTransitionAnimator(sourceRect: .zero, isOptInVisible: false)
        transitionContext = MockTransitionContext()
        transitionContext.containerView.frame = finalFrame
        transitionContext.finalFrame = finalFrame
        window = UIView(frame: finalFrame)
        browserController = UIViewController()
        browserController.view.frame = finalFrame
        window.addSubview(browserController.view)
        window.addSubview(transitionContext.containerView)
        quickAnswersView = UIView(frame: finalFrame)
        isActive = true
    }

    override func tearDown() async throws {
        controller = nil
        fallback = nil
        transitionContext = nil
        window = nil
        browserController = nil
        quickAnswersView = nil
        try await super.tearDown()
    }

    // MARK: - animationController
    func test_animationController_whenInactive_returnsFallback() {
        isActive = false
        let subject = createSubject()

        let presentation = subject.animationController(
            forPresented: controller,
            presenting: controller,
            source: controller
        )
        let dismissal = subject.animationController(forDismissed: controller)

        XCTAssertTrue(presentation === fallback)
        XCTAssertTrue(dismissal === fallback)
    }

    func test_animationController_whenActive_returnsSelf() {
        let subject = createSubject()

        let presentation = subject.animationController(
            forPresented: controller,
            presenting: controller,
            source: controller
        )
        let dismissal = subject.animationController(forDismissed: controller)

        XCTAssertTrue(presentation === subject)
        XCTAssertTrue(dismissal === subject)
    }

    func test_animationController_whenInactiveWithoutFallback_returnsNil() {
        isActive = false
        let subject = createSubject(hasFallback: false)

        let presentation = subject.animationController(
            forPresented: controller,
            presenting: controller,
            source: controller
        )

        XCTAssertNil(presentation)
        XCTAssertNil(subject.animationController(forDismissed: controller))
    }

    // MARK: - transitionDuration
    func test_transitionDuration_isNotInstant() {
        let subject = createSubject()

        XCTAssertGreaterThan(subject.transitionDuration(using: transitionContext), 0.0)
    }

    // MARK: - animateTransition
    func test_animateTransition_dismissal_completesTransition_andRestoresIdentityTransform() async {
        setUpDismissal()
        let subject = createSubject()

        subject.animateTransition(using: transitionContext)
        await waitForTransitionToComplete()

        XCTAssertEqual(transitionContext.completeTransitionCallCount, 1)
        XCTAssertEqual(transitionContext.lastDidComplete, true)
        XCTAssertEqual(browserController.view.transform, .identity)
        XCTAssertEqual(quickAnswersView.alpha, 1.0)
        XCTAssertTrue(snapshotViews.isEmpty)
    }

    func test_animateTransition_dismissal_hidesQuickAnswersViewWhileAnimating() {
        setUpDismissal()
        let subject = createSubject()

        subject.animateTransition(using: transitionContext)

        XCTAssertEqual(quickAnswersView.alpha, 0.0)
        XCTAssertEqual(snapshotViews.count, 1)
        XCTAssertEqual(transitionContext.completeTransitionCallCount, 0)
    }

    func test_animateTransition_dismissalWithoutAnimation_completesImmediately() {
        setUpDismissal()
        transitionContext.isAnimated = false
        let subject = createSubject()

        subject.animateTransition(using: transitionContext)

        XCTAssertEqual(transitionContext.completeTransitionCallCount, 1)
        XCTAssertEqual(quickAnswersView.alpha, 1.0)
        XCTAssertTrue(snapshotViews.isEmpty)
    }

    func test_animateTransition_presentation_addsToViewToContainer_andCompletes() async {
        setUpPresentation()
        let subject = createSubject()

        subject.animateTransition(using: transitionContext)
        await waitForTransitionToComplete()

        XCTAssertTrue(quickAnswersView.superview === transitionContext.containerView)
        XCTAssertEqual(quickAnswersView.frame, finalFrame)
        XCTAssertEqual(quickAnswersView.alpha, 1.0)
        XCTAssertEqual(browserController.view.transform, .identity)
        XCTAssertTrue(snapshotViews.isEmpty)
        XCTAssertEqual(transitionContext.completeTransitionCallCount, 1)
        XCTAssertEqual(transitionContext.lastDidComplete, true)
    }

    func test_animateTransition_presentationWithoutAnimation_addsToViewAndCompletesImmediately() {
        setUpPresentation()
        transitionContext.isAnimated = false
        let subject = createSubject()

        subject.animateTransition(using: transitionContext)

        XCTAssertTrue(quickAnswersView.superview === transitionContext.containerView)
        XCTAssertEqual(quickAnswersView.alpha, 1.0)
        XCTAssertTrue(snapshotViews.isEmpty)
        XCTAssertEqual(transitionContext.completeTransitionCallCount, 1)
    }

    // MARK: - Helpers
    private func createSubject(
        hasFallback: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> ReturnToBrowserTransitionAnimator {
        let subject = ReturnToBrowserTransitionAnimator(
            isActive: { [weak self] in self?.isActive ?? false },
            fallback: hasFallback ? fallback : nil
        )
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private var snapshotViews: [UIView] {
        return window.subviews.filter {
            $0 !== browserController.view && $0 !== transitionContext.containerView
        }
    }

    private func setUpDismissal() {
        let presentedController = MockPresentedViewController()
        presentedController.isBeingPresentedValue = false
        browserController.view.frame = finalFrame
        transitionContext.toViewController = browserController
        transitionContext.fromViewController = presentedController
        transitionContext.fromView = quickAnswersView
        transitionContext.containerView.addSubview(quickAnswersView)
    }

    private func setUpPresentation() {
        let presentedController = MockPresentedViewController()
        transitionContext.toViewController = presentedController
        transitionContext.toView = quickAnswersView
        transitionContext.fromViewController = browserController
    }

    private func waitForTransitionToComplete() async {
        let completed = expectation(for: NSPredicate { _, _ in
            self.transitionContext.completeTransitionCallCount > 0
        }, evaluatedWith: nil)
        await fulfillment(of: [completed], timeout: 2.0)
    }
}
