// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
import Common
import Shared

@testable import Client

final class TabScrollControllerTests: XCTestCase {
    var tab: Tab!
    var mockProfile: MockProfile!
    var mockGesture: UIPanGestureRecognizerMock!
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    var header: BaseAlphaStackView = .build()
    var overKeyboardContainer: BaseAlphaStackView = .build()

    override func setUp() {
        super.setUp()

        DependencyHelperMock().bootstrapDependencies()
        mockProfile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)
        tab = Tab(profile: mockProfile, windowUUID: windowUUID)
        mockGesture = UIPanGestureRecognizerMock()
    }

    override func tearDown() {
        mockProfile?.shutdown()
        mockProfile = nil
        tab = nil
        super.tearDown()
    }

    func testHandlePan_ScrollingUp() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        mockGesture.gestureTranslation = CGPoint(x: 0, y: 100)
        subject.handlePan(mockGesture)

        XCTAssertEqual(subject.toolbarState, LegacyTabScrollController.ToolbarState.collapsed)
    }

    func testHandlePan_ScrollingDown() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        mockGesture.gestureTranslation = CGPoint(x: 0, y: -100)
        subject.handlePan(mockGesture)

        XCTAssertEqual(subject.toolbarState, LegacyTabScrollController.ToolbarState.visible)
    }

    func testShowToolbar_AfterHidingWithScroll() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        // Hide toolbar
        mockGesture.gestureTranslation = CGPoint(x: 0, y: 100)
        subject.handlePan(mockGesture)

        // Force call to showToolbars like clicking on top bar area
        subject.showToolbars(animated: true)
        XCTAssertEqual(subject.toolbarState, LegacyTabScrollController.ToolbarState.visible)
        XCTAssertEqual(subject.header?.alpha, 1)
    }

    func testScrollDidEndDragging_ScrollingUp() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        // Hide toolbar
        mockGesture.gestureTranslation = CGPoint(x: 0, y: 100)
        subject.handlePan(mockGesture)
        subject.scrollViewDidEndDragging(tab.webView!.scrollView, willDecelerate: true)

        XCTAssertEqual(subject.toolbarState, LegacyTabScrollController.ToolbarState.visible)
        XCTAssertEqual(subject.header?.alpha, 1)
    }

    func testScrollDidEndDragging_ScrollingDown() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        // Hide toolbar
        mockGesture.gestureTranslation = CGPoint(x: 0, y: -100)
        subject.handlePan(mockGesture)
        subject.scrollViewDidEndDragging(tab.webView!.scrollView, willDecelerate: true)

        XCTAssertEqual(subject.toolbarState, LegacyTabScrollController.ToolbarState.collapsed)
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

    // MARK: - overKeyboardScrollHeight Helper Method Tests
    func testOverKeyboardScrollHeight_whenMinimalAddressBarDisabled_returnsContainerHeight() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        let containerHeight: CGFloat = 100
        overKeyboardContainer.frame = CGRect(x: 0, y: 0, width: 200, height: containerHeight)
        subject.overKeyboardContainer = overKeyboardContainer

        let safeAreaInsets = UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0)
        let result = subject.overKeyboardScrollHeight(
            with: safeAreaInsets,
            isMinimalAddressBarEnabled: false,
            isBottomSearchBar: true
        )

        XCTAssertEqual(result, containerHeight)
    }

    func testOverKeyboardScrollHeight_minimalEnabledWithHomeIndicator_returnsZero() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        let containerHeight: CGFloat = 100
        overKeyboardContainer.frame = CGRect(x: 0, y: 0, width: 200, height: containerHeight)
        subject.overKeyboardContainer = overKeyboardContainer

        let safeAreaInsets = UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0)
        let result = subject.overKeyboardScrollHeight(
            with: safeAreaInsets,
            isMinimalAddressBarEnabled: true,
            isBottomSearchBar: true
        )

        XCTAssertEqual(result, 0)
    }

    func testOverKeyboardScrollHeight_minimalEnabledWithoutHomeIndicator_returnsAdjustedHeight() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        let containerHeight: CGFloat = 100
        let topInset: CGFloat = 20
        overKeyboardContainer.frame = CGRect(x: 0, y: 0, width: 200, height: containerHeight)
        subject.overKeyboardContainer = overKeyboardContainer

        let safeAreaInsets = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
        let result = subject.overKeyboardScrollHeight(
            with: safeAreaInsets,
            isMinimalAddressBarEnabled: true,
            isBottomSearchBar: true
        )

        let expectedResult = containerHeight - topInset
        XCTAssertEqual(result, expectedResult)
    }

    func testOverKeyboardScrollHeight_nilContainer_returnsZero() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        subject.overKeyboardContainer = nil

        let safeAreaInsets = UIEdgeInsets(top: 44, left: 0, bottom: 0, right: 0)
        let result = subject.overKeyboardScrollHeight(
            with: safeAreaInsets,
            isMinimalAddressBarEnabled: true,
            isBottomSearchBar: true
        )

        XCTAssertEqual(result, 0)
    }

    func testOverKeyboardScrollHeight_nilSafeAreaInsets_returnsContainerHeight() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        let containerHeight: CGFloat = 100
        overKeyboardContainer.frame = CGRect(x: 0, y: 0, width: 200, height: containerHeight)
        subject.overKeyboardContainer = overKeyboardContainer

        let result = subject.overKeyboardScrollHeight(
            with: nil,
            isMinimalAddressBarEnabled: true,
            isBottomSearchBar: true
        )

        XCTAssertEqual(result, containerHeight)
    }

    func testOverKeyboardScrollHeight_zeroSafeAreaInsets_returnsContainerHeight() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        let containerHeight: CGFloat = 100
        overKeyboardContainer.frame = CGRect(x: 0, y: 0, width: 200, height: containerHeight)
        subject.overKeyboardContainer = overKeyboardContainer

        let result = subject.overKeyboardScrollHeight(
            with: UIEdgeInsets.zero,
            isMinimalAddressBarEnabled: true,
            isBottomSearchBar: true
        )

        XCTAssertEqual(result, containerHeight)
    }

    func testOverKeyboardScrollHeight_minimalEnabledIsNotBottomSearchBar_returnsContainerHeight() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        let containerHeight: CGFloat = 100
        let topInset: CGFloat = 20

        overKeyboardContainer.frame = CGRect(x: 0, y: 0, width: 200, height: containerHeight)
        subject.overKeyboardContainer = overKeyboardContainer

        let safeAreaInsets = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
        let result = subject.overKeyboardScrollHeight(
            with: safeAreaInsets,
            isMinimalAddressBarEnabled: true,
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
        subject.overKeyboardContainer = overKeyboardContainer
        let zoomPageBar = ZoomPageBar(zoomManager: ZoomPageManager(windowUUID: windowUUID))
        subject.zoomPageBar = zoomPageBar

        let safeAreaInsets = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
        let result = subject.overKeyboardScrollHeight(
            with: safeAreaInsets,
            isMinimalAddressBarEnabled: true,
            isBottomSearchBar: true
        )

        XCTAssertEqual(result, containerHeight)
    }

    // MARK: - Setup
    private func setupTabScroll(with subject: LegacyTabScrollController) {
        tab.createWebview(configuration: .init())
        tab.webView?.scrollView.frame.size = CGSize(width: 200, height: 2000)
        tab.webView?.scrollView.contentSize = CGSize(width: 200, height: 2000)
        tab.webView?.scrollView.delegate = subject
        subject.tab = tab
        subject.header = header
    }

    private func createSubject() -> LegacyTabScrollController {
        let subject = TabScrollController(windowUUID: .XCTestDefaultUUID)
        trackForMemoryLeaks(subject)
        return subject
    }
}
