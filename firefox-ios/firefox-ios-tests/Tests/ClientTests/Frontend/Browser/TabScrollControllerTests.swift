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
    var subject: TabScrollingController!
    var mockProfile: MockProfile!
    var mockGesture: UIPanGestureRecognizerMock!
    let featureFlagManager = MockFeatureFlagManager()
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    var header: BaseAlphaStackView = .build { _ in }

    override func setUp() {
        super.setUp()

        DependencyHelperMock().bootstrapDependencies()
        mockProfile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)
        subject = TabScrollingController(windowUUID: windowUUID, featureFlagManager: featureFlagManager)
        tab = Tab(profile: mockProfile, windowUUID: windowUUID)
        mockGesture = UIPanGestureRecognizerMock()
    }

    override func tearDown() {
        mockProfile?.shutdown()
        mockProfile = nil
        subject = nil
        tab = nil
        featureFlagManager.clearOverriddenFeatures()
        super.tearDown()
    }

    func testHandlePan_ScrollingUp() {
        setupTabScroll()

        mockGesture.gestureTranslation = CGPoint(x: 0, y: 100)
        subject.handlePan(mockGesture)

        XCTAssertEqual(subject.toolbarState, TabScrollingController.ToolbarState.collapsed)
    }

    func testHandlePan_ScrollingDown() {
        setupTabScroll()

        mockGesture.gestureTranslation = CGPoint(x: 0, y: -100)
        subject.handlePan(mockGesture)

        XCTAssertEqual(subject.toolbarState, TabScrollingController.ToolbarState.visible)
    }

    func testShowToolbar_AfterHidingWithScroll() {
        setupTabScroll()

        // Hide toolbar
        mockGesture.gestureTranslation = CGPoint(x: 0, y: 100)
        subject.handlePan(mockGesture)

        // Force call to showToolbars like clicking on top bar area
        subject.showToolbars(animated: true)
        XCTAssertEqual(subject.toolbarState, TabScrollingController.ToolbarState.visible)
        XCTAssertEqual(subject.header?.alpha, 1)
    }

    func testScrollDidEndDragging_ScrollingUp() {
        setupTabScroll()

        // Hide toolbar
        mockGesture.gestureTranslation = CGPoint(x: 0, y: 100)
        subject.handlePan(mockGesture)
        subject.scrollViewDidEndDragging(tab.webView!.scrollView, willDecelerate: true)

        XCTAssertEqual(subject.toolbarState, TabScrollingController.ToolbarState.visible)
        XCTAssertEqual(subject.header?.alpha, 1)
    }

    func testScrollDidEndDragging_ScrollingDown() {
        setupTabScroll()

        // Hide toolbar
        mockGesture.gestureTranslation = CGPoint(x: 0, y: -100)
        subject.handlePan(mockGesture)
        subject.scrollViewDidEndDragging(tab.webView!.scrollView, willDecelerate: true)

        XCTAssertEqual(subject.toolbarState, TabScrollingController.ToolbarState.collapsed)
    }

    func testDidSetTab_setsLoadingObserverOnTab() {
        setupTabScroll()
    }

    func testDidSetTab_addsPullRefreshViewToScrollView() {
        featureFlagManager.overrideFeature(.pullToRefreshRefactor, value: true)
        setupTabScroll()

        let pullRefreshView = tab.webView?.scrollView.subviews.first(where: {
            $0 is PullRefreshView
        })

        XCTAssertNotNil(pullRefreshView)
        XCTAssertNil(tab.webView?.scrollView.refreshControl)
    }

    func testDidSetTab_addsUIRefreshControllToScrollView() {
        featureFlagManager.overrideFeature(.pullToRefreshRefactor, value: false)
        setupTabScroll()

        let pullRefreshView = tab.webView?.scrollView.subviews.first(where: {
            $0 is PullRefreshView
        })

        XCTAssertNotNil(tab.webView?.scrollView.refreshControl)
        XCTAssertNil(pullRefreshView)
    }

    func testDidSetTab_setsTabOnLoadingClosure_whenPullRefreshFeatureEnabled() {
        featureFlagManager.overrideFeature(.pullToRefreshRefactor, value: true)
        setupTabScroll()

        XCTAssertNotNil(tab.onLoading)
    }

    func testDidSetTab_tabHasNilOnLoadingClosure_whenPullRefreshFeatureDisabled() {
        featureFlagManager.overrideFeature(.pullToRefreshRefactor, value: false)
        setupTabScroll()

        XCTAssertNil(tab.onLoading)
    }

    func testScrollViewWillBeginZooming_removesPullRefresh_whenPullRefreshFeatureEnabled() throws {
        featureFlagManager.overrideFeature(.pullToRefreshRefactor, value: true)
        setupTabScroll()

        let scrollView = try XCTUnwrap(tab.webView?.scrollView)
        subject.scrollViewWillBeginZooming(scrollView, with: nil)

        let pullRefresh = scrollView.subviews.first { $0 is PullRefreshView }
        XCTAssertNil(pullRefresh)
    }

    func testScrollViewWillBeginZooming_removesUIRefreshControll_whenPullRefreshFeatureDisabled() throws {
        featureFlagManager.overrideFeature(.pullToRefreshRefactor, value: false)
        setupTabScroll()

        let scrollView = try XCTUnwrap(tab.webView?.scrollView)
        subject.scrollViewWillBeginZooming(scrollView, with: nil)

        XCTAssertNil(scrollView.refreshControl)
    }

    func testScrollViewDidEndZooming_addsPullRefresh_whenPullRefreshFeatureEnabled() throws {
        featureFlagManager.overrideFeature(.pullToRefreshRefactor, value: true)
        setupTabScroll()

        let scrollView = try XCTUnwrap(tab.webView?.scrollView)
        scrollView.scrollRectToVisible(.zero, animated: true)
        subject.scrollViewDidEndZooming(scrollView, with: nil, atScale: 0)

        let pullRefresh = scrollView.subviews.first { $0 is PullRefreshView }
        XCTAssertNotNil(pullRefresh)
    }

    func testScrollViewDidEndZooming_addsUIRefreshControll_whenPullRefreshFeatureDisabled() throws {
        featureFlagManager.overrideFeature(.pullToRefreshRefactor, value: false)
        setupTabScroll()

        let scrollView = try XCTUnwrap(tab.webView?.scrollView)
        subject.scrollViewDidEndZooming(scrollView, with: nil, atScale: 0)

        XCTAssertNotNil(scrollView.refreshControl)
    }

    private func setupTabScroll() {
        tab.createWebview(configuration: .init())
        tab.webView?.scrollView.contentSize = CGSize(width: 200, height: 2000)
        tab.webView?.scrollView.delegate = subject
        subject.tab = tab
        subject.header = header
    }
}
