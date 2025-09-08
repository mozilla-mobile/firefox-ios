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
    var tabProvider: MockTabProviderProtocol!

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
        tabProvider = nil
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

        // Upward scroll => translation.y POSITIVE
        subject.handleScroll(for: CGPoint(x: 0, y: 60))
        subject.handleEndScrolling(for: CGPoint(x: 0, y: 60), velocity: .zero)

        XCTAssertEqual(delegate.showCount, 1, "Should show toolbar on significant upward scroll when collapsed")
    }

    func test_updateToolbarTransition_emitsProgress_towardsCollapsed_fromExpanded() {
        let subject = createSubject()

        // A small in-progress drag should mark transitioning and call delegate.
        subject.handleScroll(for: CGPoint(x: 0, y: -10)) // downwards; progress  -10

        XCTAssertFalse(delegate.updateCalls.isEmpty, "Expected transition progress callbacks during drag")
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

        // Small downward drag (below threshold) towards .collapsed
        subject.handleScroll(for: CGPoint(x: 0, y: -10))
        XCTAssertFalse(delegate.updateCalls.isEmpty)
        XCTAssertEqual(delegate.hideCount, 0)
        XCTAssertEqual(delegate.showCount, 0)

        // Continue the drag far enough to confirm to pass threshold
        subject.handleScroll(for: CGPoint(x: 0, y: -50))

        // Expect the transition to resolve to "hide"
        XCTAssertEqual(delegate.hideCount, 1)
        XCTAssertEqual(delegate.showCount, 0)
    }

    /// From collapsed → user starts a small upward drag (transitioning),
    /// then continues past the confirmation threshold → we should show.
    func test_transitioning_confirmed_shows_whenDraggingUpPastThreshold_fromCollapsed() {
        let subject = createSubject()
        subject.hideToolbars(animated: true)
        XCTAssertEqual(delegate.hideCount, 1)

        // Small upward (below threshold)
        subject.handleScroll(for: CGPoint(x: 0, y: 10))
        XCTAssertFalse(delegate.updateCalls.isEmpty)
        XCTAssertEqual(delegate.showCount, 0)

        // Continue upward past threshold to confirm
        subject.handleScroll(for: CGPoint(x: 0, y: 40))
        XCTAssertEqual(delegate.showCount, 1)
    }

    /// While transitioning, if the end-of-drag delta is below threshold,
    /// we cancel and snap back to last valid state (expanded by default) → show.
    func test_transitioning_cancelled_onEndBelowThreshold_snapsBackToShow() {
        let subject = createSubject()

        // Enter transitioning downward
        subject.handleScroll(for: CGPoint(x: 0, y: -10))
        XCTAssertFalse(delegate.updateCalls.isEmpty)

        // End scrolling with a small delta below threshold should cancel transition
        subject.handleEndScrolling(for: CGPoint(x: 0, y: -10), velocity: .zero)

        XCTAssertEqual(delegate.showCount, 1)
        XCTAssertEqual(delegate.hideCount, 0)
    }

    func test_transitionProgress_targetsCollapsed_whenStartingExpanded_andDraggingDown() {
        let subject = createSubject()

        // from expanded, dragging down → towards .collapsed
        subject.handleScroll(for: CGPoint(x: 0, y: -8))
        XCTAssertEqual(delegate.updateCalls.last?.towards, .collapsed)
    }

    func test_transitionProgress_targetsExpanded_whenStartingCollapsed_andDraggingUp() {
        let subject = createSubject()
        subject.hideToolbars(animated: true)

        // from collapsed, dragging up → towards .expanded
        subject.handleScroll(for: CGPoint(x: 0, y: 8))
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

    func test_cancel_onSmallDownwardDrag_callsShow_noHide() {
        let subject = createSubject()

        // Enter transitioning with a small downward movement (below threshold: 20)
        subject.handleScroll(for: CGPoint(x: 0, y: -10)) // delta = +10

        // End drag still below threshold → cancelTransition() → show
        subject.handleEndScrolling(for: CGPoint(x: 0, y: -10), velocity: .zero)

        XCTAssertEqual(delegate.showCount, 1)
        XCTAssertEqual(delegate.hideCount, 0)
    }

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

    func test_cancel_whenDeltaEqualsThreshold() {
        let subject = createSubject()

        // Start a small downward drag to enter transitioning
        subject.handleScroll(for: CGPoint(x: 0, y: -5)) // below threshold, transitioning

        subject.handleEndScrolling(for: CGPoint(x: 0, y: -20), velocity: .zero)

        XCTAssertEqual(delegate.showCount, 1, "Equal to threshold should cancel and show")
        XCTAssertEqual(delegate.hideCount, 0)
    }

    func test_cancel_ignoresVelocity_whenBelowThreshold() {
        let subject = createSubject()

        // Enter transitioning
        subject.handleScroll(for: CGPoint(x: 0, y: -8))

        // End with small delta but large velocity → still cancel
        subject.handleEndScrolling(for: CGPoint(x: 0, y: -8),
                                   velocity: CGPoint(x: 0, y: -5000))

        XCTAssertEqual(delegate.showCount, 1)
        XCTAssertEqual(delegate.hideCount, 0)
    }

    func test_noScrollableContent_preventsUIUpdates() {
        let smallContentSize = CGSize(width: 320, height: 500)
        let subject = createSubject(contentSize: smallContentSize)

        subject.handleScroll(for: CGPoint(x: 0, y: -80))
        // Checks that transition state is not trigger even for a significant scroll
        // because there is not enough scrollable content
        XCTAssertTrue(delegate.updateCalls.isEmpty)

        subject.handleEndScrolling(for: CGPoint(x: 0, y: -80), velocity: .zero)
        XCTAssertEqual(delegate.showCount, 0)
        XCTAssertEqual(delegate.hideCount, 0)
    }

    // MARK: - endDrag checks

    func test_endDrag_atBottom_preventsCommit() {
        let contentOffset = CGPoint(x: 0, y: 1980)
        let subject = createSubject()
        tabProvider.scrollView?.contentOffset = contentOffset

        // Simulate end drag; handler checks scrollReachBottom()
        subject.scrollViewDidEndDragging(tabProvider.scrollView!, willDecelerate: false)

        // No show/hide because at bottom
        XCTAssertEqual(delegate.showCount, 0)
        XCTAssertEqual(delegate.hideCount, 0)
    }

    func test_ignoreScroll_tabIsLoading_preventsCommit() {
        let subject = createSubject()

        tabProvider.isLoading = true
        // Simulate end drag; handler checks scrollReachBottom()
        subject.handleScroll(for: CGPoint(x: 0, y: -80))
        subject.scrollViewDidEndDragging(tabProvider.scrollView!, willDecelerate: false)

        // No show/hide because at bottom
        XCTAssertEqual(delegate.showCount, 0)
        XCTAssertEqual(delegate.hideCount, 0)
    }

    // MARK: - Pull to refresh
    func test_addPullToRefresh_isCalled() {
        let subject = createSubject()

        // Initial call when tab is set
        XCTAssertEqual(tabProvider.pullToRefreshAddCount, 1)
        subject.configureRefreshControl()
        XCTAssertEqual(tabProvider.pullToRefreshAddCount, 2)
    }

    func test_addPullToRefresh_isNotCalled_ForHomepage() {
        let subject = createSubject()
        tabProvider.isFxHomeTab = true

        subject.configureRefreshControl()
        XCTAssertEqual(tabProvider.pullToRefreshRemoveCount, 0)
    }

    func test_removePullToRefresh_isCalled() {
        let subject = createSubject()

        subject.removePullRefreshControl()
        XCTAssertEqual(tabProvider.pullToRefreshRemoveCount, 1)
    }

    // MARK: - Setup

    private func createSubject(contentSize: CGSize = CGSize(width: 200, height: 2000)) -> TabScrollHandler {
        let subject = TabScrollHandler(windowUUID: .XCTestDefaultUUID, delegate: delegate)

        // Create tab and scrollView
        tab.createWebview(configuration: .init())
        tab.webView?.scrollView.frame.size = CGSize(width: 200, height: 2000)
        tab.webView?.scrollView.contentSize = contentSize
        tab.webView?.scrollView.delegate = subject
        tabProvider = MockTabProviderProtocol(tab)
        subject.tabProvider = tabProvider

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
