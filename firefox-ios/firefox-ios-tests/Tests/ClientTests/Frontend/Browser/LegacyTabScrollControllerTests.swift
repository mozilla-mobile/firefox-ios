// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
import Common
import Shared

@testable import Client

@MainActor
final class LegacyTabScrollControllerTests: XCTestCase {
    var tab: Tab!
    var mockProfile: MockProfile!
    var mockGesture: MockUIPanGestureRecognizer!
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    var header: BaseAlphaStackView = .build()
    var overKeyboardContainer: BaseAlphaStackView = .build()
    var bottomContainer: BaseAlphaStackView = .build()

    override func setUp() async throws {
        try await super.setUp()

        DependencyHelperMock().bootstrapDependencies()
        mockProfile = MockProfile()
        tab = Tab(profile: mockProfile, windowUUID: windowUUID)
        mockGesture = MockUIPanGestureRecognizer()
    }

    override func tearDown() async throws {
        mockProfile?.shutdown()
        mockProfile = nil
        tab = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testHandlePan_ScrollingUp() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        mockGesture.gestureTranslation = CGPoint(x: 0, y: 100)
        subject.handlePan(mockGesture)

        XCTAssertTrue(subject.isToolbarStateCollapsed)
    }

    func testHandlePan_ScrollingDown() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        mockGesture.gestureTranslation = CGPoint(x: 0, y: -100)
        subject.handlePan(mockGesture)

        XCTAssertFalse(subject.isToolbarStateCollapsed)
    }

    func testShowToolbar_AfterHidingWithScroll() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        // Hide toolbar
        mockGesture.gestureTranslation = CGPoint(x: 0, y: 100)
        subject.handlePan(mockGesture)

        // Force call to showToolbars like clicking on top bar area
        subject.showToolbars(animated: true)
        XCTAssertFalse(subject.isToolbarStateCollapsed)
    }

    func testIsToolbarStateCollapsed_reflectsHideAndShowToolbars() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        XCTAssertFalse(subject.isToolbarStateCollapsed)

        subject.hideToolbars(animated: false)
        XCTAssertTrue(subject.isToolbarStateCollapsed)

        subject.showToolbars(animated: false)
        XCTAssertFalse(subject.isToolbarStateCollapsed)
    }

    func testScrollDidEndDragging_ScrollingUp() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        // Hide toolbar
        mockGesture.gestureTranslation = CGPoint(x: 0, y: 100)
        subject.handlePan(mockGesture)
        subject.scrollViewDidEndDragging(tab.webView!.scrollView, willDecelerate: true)

        XCTAssertFalse(subject.isToolbarStateCollapsed)
    }

    func testScrollDidEndDragging_ScrollingDown() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        // Hide toolbar
        mockGesture.gestureTranslation = CGPoint(x: 0, y: -100)
        subject.handlePan(mockGesture)
        subject.scrollViewDidEndDragging(tab.webView!.scrollView, willDecelerate: true)

        XCTAssertTrue(subject.isToolbarStateCollapsed)
    }

    func testDidSetTab_addsPullRefreshViewToScrollView() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        let pullRefreshView = tab.webView?.scrollView.subviews.first(where: {
            $0 is PullRefreshView
        })

        XCTAssertNotNil(pullRefreshView)
        XCTAssertNil(tab.webView?.scrollView.refreshControl)
    }

    func testDidSetTab_setsTabOnLoadingClosure() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        XCTAssertNotNil(tab.onWebViewLoadingStateChanged)
    }

    func testScrollViewWillBeginZooming_removesPullRefresh() throws {
        let subject = createSubject()
        setupTabScroll(with: subject)

        let scrollView = try XCTUnwrap(tab.webView?.scrollView)
        subject.scrollViewWillBeginZooming(scrollView, with: nil)

        let pullRefresh = scrollView.subviews.first { $0 is PullRefreshView }
        XCTAssertNil(pullRefresh)
    }

    func testScrollViewDidEndZooming_addsPullRefresh() throws {
        let subject = createSubject()
        setupTabScroll(with: subject)

        let scrollView = try XCTUnwrap(tab.webView?.scrollView)
        scrollView.scrollRectToVisible(.zero, animated: true)
        subject.scrollViewDidEndZooming(scrollView, with: nil, atScale: 0)

        let pullRefresh = scrollView.subviews.first { $0 is PullRefreshView }
        XCTAssertNotNil(pullRefresh)
    }

    func testContentSizeChange_WhenCollapsedAndContentBecomesNonScrollable_ShowsToolbar() throws {
        let subject = createSubject()
        setupTabScroll(with: subject)

        let scrollView = try XCTUnwrap(tab.webView?.scrollView)
        // Collapse while the content is still scrollable, as only a scroll gesture can.
        subject.hideToolbars(animated: false)
        XCTAssertTrue(subject.isToolbarStateCollapsed)

        // Simulate an overlay shrinking the document so it can no longer be scrolled.
        scrollView.contentSize = CGSize(width: 200, height: 10)
        subject.observeValue(forKeyPath: "contentSize", of: scrollView, change: nil, context: nil)

        XCTAssertFalse(subject.isToolbarStateCollapsed)
    }

    func testContentSizeChange_WhenCollapsedAndContentStaysScrollable_KeepsToolbarCollapsed() throws {
        let subject = createSubject()
        setupTabScroll(with: subject)

        let scrollView = try XCTUnwrap(tab.webView?.scrollView)
        subject.hideToolbars(animated: false)
        XCTAssertTrue(subject.isToolbarStateCollapsed)

        // Content grows but is still taller than the viewport, so the toolbar must stay collapsed.
        scrollView.contentSize = CGSize(width: 200, height: 3000)
        subject.observeValue(forKeyPath: "contentSize", of: scrollView, change: nil, context: nil)

        XCTAssertTrue(subject.isToolbarStateCollapsed)
    }

    // MARK: - overKeyboardScrollHeight Helper Method Tests
    func testOverKeyboardScrollHeight_minimalEnabledWithHomeIndicator_returnsZero() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        let safeAreaInsets = UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0)
        let result = subject.calculateOverKeyboardScrollHeight(
            with: safeAreaInsets,
            isBottomSearchBar: true
        )

        XCTAssertEqual(result, 0)
    }

    func testOverKeyboardScrollHeight_minimalEnabledWithoutHomeIndicator_returnsAdjustedHeight() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        let containerHeight: CGFloat = 100
        let topInset: CGFloat = 20

        let safeAreaInsets = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
        let result = subject.calculateOverKeyboardScrollHeight(
            with: safeAreaInsets,
            isBottomSearchBar: true
        )

        let expectedResult: CGFloat = if #available(iOS 26.0, *) { .zero } else { containerHeight - topInset }
        XCTAssertEqual(result, expectedResult)
    }

    func testOverKeyboardScrollHeight_nilContainer_returnsZero() {
        let subject = createSubject()
        setupTabScroll(with: subject)
        setupToolbarViews(with: subject, overKeyboardContainer: nil)

        let safeAreaInsets = UIEdgeInsets(top: 44, left: 0, bottom: 0, right: 0)
        let result = subject.calculateOverKeyboardScrollHeight(
            with: safeAreaInsets,
            isBottomSearchBar: true
        )

        XCTAssertEqual(result, 0)
    }

    func testOverKeyboardScrollHeight_nilSafeAreaInsets_returnsContainerHeight() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        let containerHeight: CGFloat = 100

        let result = subject.calculateOverKeyboardScrollHeight(
            with: nil,
            isBottomSearchBar: true
        )

        let expectedResult: CGFloat = if #available(iOS 26.0, *) { .zero } else { containerHeight }
        XCTAssertEqual(result, expectedResult)
    }

    func testOverKeyboardScrollHeight_zeroSafeAreaInsets_returnsContainerHeight() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        let containerHeight: CGFloat = 100
        let result = subject.calculateOverKeyboardScrollHeight(
            with: UIEdgeInsets.zero,
            isBottomSearchBar: true
        )

        let expectedResult: CGFloat = if #available(iOS 26.0, *) { .zero } else { containerHeight }
        XCTAssertEqual(result, expectedResult)
    }

    func testOverKeyboardScrollHeight_minimalEnabledIsNotBottomSearchBar_returnsContainerHeight() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        let containerHeight: CGFloat = 100
        let topInset: CGFloat = 20

        let safeAreaInsets = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
        let result = subject.calculateOverKeyboardScrollHeight(
            with: safeAreaInsets,
            isBottomSearchBar: false
        )

        XCTAssertEqual(result, containerHeight)
    }

    func testOverKeyboardScrollHeight_minimalEnabledIsBottomSearchBarZoomBarIsNotNil_returnsContainerHeight() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        let containerHeight: CGFloat = 100
        let topInset: CGFloat = 20

        overKeyboardContainer.frame = CGRect(x: 0, y: 0, width: 200, height: containerHeight)
        let zoomPageBar = ZoomPageBar(zoomManager: ZoomPageManager(windowUUID: windowUUID))
        subject.zoomPageBar = zoomPageBar

        let safeAreaInsets = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
        let result = subject.calculateOverKeyboardScrollHeight(
            with: safeAreaInsets,
            isBottomSearchBar: true
        )

        XCTAssertEqual(result, containerHeight)
    }

    func testOverKeyboardScrollHeight_minimalEnabledIsBottomSearchBarIsReaderModeActive_returnsContainerHeight() {
        let subject = createSubject()
        setupTabScroll(with: subject)
        tab.url = URL(string: "http://localhost:6571/reader-mode/page?url=https://example.com")!

        let containerHeight: CGFloat = 100
        let safeAreaInsets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)

        let result = subject.calculateOverKeyboardScrollHeight(
            with: safeAreaInsets,
            isBottomSearchBar: true
        )

        XCTAssertEqual(result, containerHeight)
    }

    func testOverKeyboardScrollHeight_minimalEnabledIsBottomSearchBarIsNotReaderModeActive_returnsAdjustedHeight() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        let safeAreaInsets = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)

        let result = subject.calculateOverKeyboardScrollHeight(
            with: safeAreaInsets,
            isBottomSearchBar: true
        )

        XCTAssertEqual(result, .zero)
    }

    func testToolbarTapHandler_WhenMinimalAddressBarEnabledAndCollapsed_ShowsToolbar() {
        let subject = createSubject()
        setupTabScroll(with: subject)
        subject.hideToolbars(animated: false)

        let handler = subject.createToolbarTapHandler()
        handler()

        XCTAssertFalse(subject.isToolbarStateCollapsed)
    }

    func testToolbarTapHandler_WhenToolbarVisible_DoesNothing() {
        let subject = createSubject()
        setupTabScroll(with: subject)
        subject.showToolbars(animated: false)

        let handler = subject.createToolbarTapHandler()
        handler()

        XCTAssertFalse(subject.isToolbarStateCollapsed)
    }

    // MARK: - Setup
    private func setupTabScroll(with subject: LegacyTabScrollController) {
        tab.createWebview(configuration: .init())
        tab.webView?.scrollView.frame.size = CGSize(width: 200, height: 2000)
        tab.webView?.scrollView.contentSize = CGSize(width: 200, height: 2000)
        tab.webView?.scrollView.delegate = subject
        subject.tab = tab
    }

    private func createSubject() -> LegacyTabScrollController {
        let subject = LegacyTabScrollController(windowUUID: .XCTestDefaultUUID)
        setupToolbarViews(with: subject, overKeyboardContainer: overKeyboardContainer)
        trackForMemoryLeaks(subject)
        return subject
    }

    private func setupToolbarViews(with subject: LegacyTabScrollController,
                                   overKeyboardContainer: BaseAlphaStackView?) {
        let containerHeight: CGFloat = 100
        overKeyboardContainer?.frame = CGRect(x: 0, y: 0, width: 200, height: containerHeight)
        subject.configureToolbarViews(overKeyboardContainer: overKeyboardContainer,
                                      bottomContainer: bottomContainer,
                                      headerContainer: header)
    }
}
