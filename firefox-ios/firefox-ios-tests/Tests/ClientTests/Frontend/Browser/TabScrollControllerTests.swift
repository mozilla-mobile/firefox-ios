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

    var header: BaseAlphaStackView = .build { _ in }

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

        XCTAssertEqual(subject.toolbarState, TabScrollingController.ToolbarState.collapsed)
    }

    func testHandlePan_ScrollingDown() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        mockGesture.gestureTranslation = CGPoint(x: 0, y: -100)
        subject.handlePan(mockGesture)

        XCTAssertEqual(subject.toolbarState, TabScrollingController.ToolbarState.visible)
    }

    func testShowToolbar_AfterHidingWithScroll() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        // Hide toolbar
        mockGesture.gestureTranslation = CGPoint(x: 0, y: 100)
        subject.handlePan(mockGesture)

        // Force call to showToolbars like clicking on top bar area
        subject.showToolbars(animated: true)
        XCTAssertEqual(subject.toolbarState, TabScrollingController.ToolbarState.visible)
        XCTAssertEqual(subject.header?.alpha, 1)
    }

    func testScrollDidEndDragging_ScrollingUp() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        // Hide toolbar
        mockGesture.gestureTranslation = CGPoint(x: 0, y: 100)
        subject.handlePan(mockGesture)
        subject.scrollViewDidEndDragging(tab.webView!.scrollView, willDecelerate: true)

        XCTAssertEqual(subject.toolbarState, TabScrollingController.ToolbarState.visible)
        XCTAssertEqual(subject.header?.alpha, 1)
    }

    func testScrollDidEndDragging_ScrollingDown() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        // Hide toolbar
        mockGesture.gestureTranslation = CGPoint(x: 0, y: -100)
        subject.handlePan(mockGesture)
        subject.scrollViewDidEndDragging(tab.webView!.scrollView, willDecelerate: true)

        XCTAssertEqual(subject.toolbarState, TabScrollingController.ToolbarState.collapsed)
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

        XCTAssertNotNil(tab.onLoading)
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

    private func setupTabScroll(with subject: TabScrollingController) {
        tab.createWebview(configuration: .init())
        tab.webView?.scrollView.contentSize = CGSize(width: 200, height: 2000)
        tab.webView?.scrollView.delegate = subject
        subject.tab = tab
        subject.header = header
    }

    private func createSubject() -> TabScrollingController {
        return TabScrollingController(windowUUID: .XCTestDefaultUUID)
    }
}
