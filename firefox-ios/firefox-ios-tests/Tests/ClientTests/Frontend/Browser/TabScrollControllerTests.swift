// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
import Common

@testable import Client

final class TabScrollControllerTests: XCTestCase {
    var tab: Tab!
    var subject: TabScrollingController!
    var mockProfile: MockProfile!
    var mockGesture: UIPanGestureRecognizerMock!
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    var header: BaseAlphaStackView = .build { _ in }

    override func setUp() {
        super.setUp()

        self.mockProfile = MockProfile()
        self.subject = TabScrollingController(windowUUID: windowUUID)
        self.tab = Tab(profile: mockProfile, windowUUID: windowUUID)
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)
        mockGesture = UIPanGestureRecognizerMock()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        mockProfile?.shutdown()
        self.mockProfile = nil
        self.subject = nil
        self.tab = nil
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

    private func setupTabScroll() {
        tab.createWebview(configuration: .init())
        tab.webView?.scrollView.contentSize = CGSize(width: 200, height: 2000)
        tab.webView?.scrollView.delegate = subject
        subject.tab = tab
        subject.header = header
    }
}
