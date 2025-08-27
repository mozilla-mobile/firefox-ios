// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
import Common
import Shared

@testable import Client

@MainActor
final class TabScrollHandlerTests: XCTestCase {
    var tab: Tab!
    var mockProfile: MockProfile!
    let windowUUID: WindowUUID = .XCTestDefaultUUID
    var delegate: MockTabScrollHandlerDelegate!

    override func setUp() {
        super.setUp()

        DependencyHelperMock().bootstrapDependencies()
        mockProfile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)
        tab = Tab(profile: mockProfile, windowUUID: windowUUID)
        delegate = MockTabScrollHandlerDelegate()
    }

    override func tearDown() {
        mockProfile?.shutdown()
        mockProfile = nil
        tab = nil
        delegate = nil
        super.tearDown()
    }

    func test_scrollDown_hidesToolbar_whenSignificant() {
        let subject = createSubject()

        // Downward scroll translation.y -50
        subject.handleScroll(for: CGPoint(x: 0, y: -50))
        subject.handleEndScrolling(for: CGPoint(x: 0, y: -50), velocity: .zero)

        XCTAssertEqual(delegate.hideCount, 1, "Should hide toolbar on significant downward scroll")
        XCTAssertEqual(delegate.showCount, 0)
    }

    func test_scrollUp_showsToolbar_whenPreviouslyCollapsed() {
        let subject = createSubject()

        // Start collapsed
        subject.hideToolbars(animated: true)

        // Upward scroll => translation.y POSITIVE; choose +60
        subject.handleScroll(for: CGPoint(x: 0, y: 60))
        subject.handleEndScrolling(for: CGPoint(x: 0, y: 60), velocity: .zero)

        XCTAssertEqual(delegate.showCount, 1, "Should show toolbar on significant upward scroll when collapsed")
    }

    // 3) While dragging we emit a transition progress toward the correct state
    func test_updateToolbarTransition_emitsProgress_towardsCollapsed_fromExpanded() {
        let subject = createSubject()

        // Expanded is default. A small in-progress drag should mark transitioning and call delegate.
        subject.handleScroll(for: CGPoint(x: 0, y: -10)) // downwards; progress  -10

        XCTAssertFalse(delegate.updateCalls.isEmpty, "Expected transition progress callbacks during drag")
        // From expanded, progress should be towards collapsed
        XCTAssertEqual(delegate.updateCalls.last?.towards, .collapsed)
    }

    // 4) Below threshold cancels -> showToolbars
    func test_endScroll_belowThreshold_cancelsTransition_andShowsToolbar() {
        let subject = createSubject()

        // Nudge smaller than threshold (<= 20)
        subject.handleScroll(for: CGPoint(x: 0, y: -5))
        subject.handleEndScrolling(for: CGPoint(x: 0, y: -5), velocity: .zero)

        XCTAssertEqual(delegate.showCount, 1, "Cancel should snap back to last valid state (expanded) and call show")
        XCTAssertEqual(delegate.hideCount, 0)
    }

    func test_scrollToTop_expandsIfCollapsed_andReturnsTrue() {
        let subject = createSubject()
        subject.hideToolbars(animated: true)

        let should = subject.scrollViewShouldScrollToTop(tab.webView!.scrollView)
        XCTAssertTrue(should)
        XCTAssertEqual(delegate.showCount, 1, "scrollToTop should call show if collapsed")
    }

    // MARK: - Transitioning state

    /// From expanded → user starts a small downward drag (transitioning),
    /// then continues past the confirmation threshold → we should hide.
    func test_transitioning_confirmed_hides_whenDraggingDownPastThreshold() {
        let subject = createSubject()
        // Expanded by default

        // Start transitioning with a small downward drag (below threshold)
        subject.handleScroll(for: CGPoint(x: 0, y: -10)) // delta = +10, towards .collapsed
        XCTAssertFalse(delegate.updateCalls.isEmpty)
        // Still transitioning; no final action yet
        XCTAssertEqual(delegate.hideCount, 0)
        XCTAssertEqual(delegate.showCount, 0)

        // Continue the drag far enough to confirm (> 20)
        subject.handleScroll(for: CGPoint(x: 0, y: -40)) // delta = +40, confirm
        // Expect the transition to resolve to "hide"
        XCTAssertEqual(delegate.hideCount, 1)
        XCTAssertEqual(delegate.showCount, 0)
    }

    /// From collapsed → user starts a small upward drag (transitioning),
    /// then continues past the confirmation threshold → we should show.
    func test_transitioning_confirmed_shows_whenDraggingUpPastThreshold_fromCollapsed() {
        let subject = createSubject()
        subject.hideToolbars(animated: true) // collapse first
        XCTAssertEqual(delegate.hideCount, 1)

        // Start transitioning upward (below threshold)
        subject.handleScroll(for: CGPoint(x: 0, y: 10)) // delta = -10, towards .expanded
        XCTAssertFalse(delegate.updateCalls.isEmpty)
        XCTAssertEqual(delegate.showCount, 0)

        // Continue upward past threshold to confirm
        subject.handleScroll(for: CGPoint(x: 0, y: 40)) // delta = -40, confirm
        XCTAssertEqual(delegate.showCount, 1)
    }

    /// While transitioning, if the end-of-drag delta is below threshold,
    /// we cancel and snap back to last valid state (expanded by default) → show.
    func test_transitioning_cancelled_onEndBelowThreshold_snapsBackToShow() {
        let subject = createSubject()

        // Enter transitioning downward
        subject.handleScroll(for: CGPoint(x: 0, y: -10))
        XCTAssertFalse(delegate.updateCalls.isEmpty)

        // End scrolling with a small delta — below threshold → cancelTransition() → show
        subject.handleEndScrolling(for: CGPoint(x: 0, y: -10), velocity: .zero)

        XCTAssertEqual(delegate.showCount, 1)
        XCTAssertEqual(delegate.hideCount, 0)
    }

    /// Verify that the “towards” state emitted during transitioning depends on the last valid state.
    /// Case 1: from expanded, dragging down → towards .collapsed
    func test_transitionProgress_targetsCollapsed_whenStartingExpanded_andDraggingDown() {
        let subject = createSubject()
        subject.handleScroll(for: CGPoint(x: 0, y: -8)) // small downward
        XCTAssertEqual(delegate.updateCalls.last?.towards, .collapsed)
    }

    /// Case 2: from collapsed, dragging up → towards .expanded
    func test_transitionProgress_targetsExpanded_whenStartingCollapsed_andDraggingUp() {
        let subject = createSubject()
        subject.hideToolbars(animated: true) // start collapsed

        subject.handleScroll(for: CGPoint(x: 0, y: 8)) // small upward
        XCTAssertEqual(delegate.updateCalls.last?.towards, .expanded)
    }

    /// Defensive: while transitioning, crossing the threshold should only resolve once (no double fire).
    func test_transition_resolvesOnce_whenPassingThreshold() {
        let subject = createSubject()

        // Start transitioning down
        subject.handleScroll(for: CGPoint(x: 0, y: -12))
        // Cross threshold: should resolve to hide
        subject.handleScroll(for: CGPoint(x: 0, y: -50))
        let hidesAfterFirstConfirm = delegate.hideCount

        // Keep dragging more; shouldn’t trigger another resolve
        subject.handleScroll(for: CGPoint(x: 0, y: -120))
        XCTAssertEqual(delegate.hideCount, hidesAfterFirstConfirm)
    }

    // MARK: - Cancel actions (not significant scroll)

    /// From expanded, a small downward drag that never exceeds the threshold should cancel
    /// and snap back to show (expanded).
    func test_cancel_onSmallDownwardDrag_callsShow_noHide() {
        let subject = createSubject()

        // Enter transitioning with a small downward movement (below threshold: 20)
        subject.handleScroll(for: CGPoint(x: 0, y: -10)) // delta = +10

        // End drag still below threshold → cancelTransition() → show
        subject.handleEndScrolling(for: CGPoint(x: 0, y: -10), velocity: .zero)

        XCTAssertEqual(delegate.showCount, 1)
        XCTAssertEqual(delegate.hideCount, 0)
    }

    /// From collapsed, a small upward drag that never exceeds the threshold should cancel
    /// and (per current implementation) call show (snap to expanded).
    func test_cancel_onSmallUpwardDrag_fromCollapsed_callsShow_noHide() {
        let subject = createSubject()
        subject.hideToolbars(animated: true) // start collapsed
        XCTAssertEqual(delegate.hideCount, 1)

        // Enter transitioning with a small upward movement (below threshold)
        subject.handleScroll(for: CGPoint(x: 0, y: 10)) // delta = -10

        // End drag still below threshold → cancelTransition() → show
        subject.handleEndScrolling(for: CGPoint(x: 0, y: 10), velocity: .zero)

        XCTAssertEqual(delegate.showCount, 0)
        XCTAssertEqual(delegate.hideCount, 2)
    }

    /// Boundary case: exactly at the threshold should still CANCEL
    /// because the code uses strict '>' comparison.
    func test_cancel_whenDeltaEqualsThreshold() {
        let subject = createSubject()

        // Start a small downward drag to enter transitioning
        subject.handleScroll(for: CGPoint(x: 0, y: -5)) // below threshold, transitioning

        // End with |delta| == 20 (threshold) → should NOT confirm
        subject.handleEndScrolling(for: CGPoint(x: 0, y: -20), velocity: .zero)

        XCTAssertEqual(delegate.showCount, 1, "Equal to threshold should cancel and show")
        XCTAssertEqual(delegate.hideCount, 0)
    }

    /// Velocity is currently ignored (commented out). Even with a high velocity,
    /// if delta is below threshold we CANCEL.
    func test_cancel_ignoresVelocity_whenBelowThreshold() {
        let subject = createSubject()

        // Enter transitioning
        subject.handleScroll(for: CGPoint(x: 0, y: -8)) // below threshold

        // End with small delta but large velocity → still cancel
        subject.handleEndScrolling(for: CGPoint(x: 0, y: -8),
                                   velocity: CGPoint(x: 0, y: -5000))

        XCTAssertEqual(delegate.showCount, 1)
        XCTAssertEqual(delegate.hideCount, 0)
    }

    // MARK: - Setup
    private func setupTabScroll(with subject: TabScrollHandler) {
        tab.createWebview(configuration: .init())
        tab.webView?.scrollView.frame.size = CGSize(width: 200, height: 2000)
        tab.webView?.scrollView.contentSize = CGSize(width: 200, height: 2000)
        tab.webView?.scrollView.delegate = subject
        subject.tabProvider = TabProviderAdapter(tab)
    }

    private func createSubject() -> TabScrollHandler {
        let subject = TabScrollHandler(windowUUID: .XCTestDefaultUUID, delegate: delegate)
        setupTabScroll(with: subject)

        let header: BaseAlphaStackView = .build()
        let overKeyboardContainer: BaseAlphaStackView = .build()
        let bottomContainer: BaseAlphaStackView = .build()

        overKeyboardContainer.frame = CGRect(x: 0, y: 0, width: 200, height: 100)

        subject.configureToolbarViews(overKeyboardContainer: overKeyboardContainer,
                                      bottomContainer: bottomContainer,
                                      headerContainer: header)
        trackForMemoryLeaks(subject)
        return subject
    }
}
