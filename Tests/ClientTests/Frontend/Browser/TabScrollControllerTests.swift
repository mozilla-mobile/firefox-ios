// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit

@testable import Client

final class TabScrollControllerTests: XCTestCase {
    var tab: Tab!
    var subject: TabScrollingController!
    var mockProfile: MockProfile!
    var mockGesture: UIPanGestureRecognizerMock!

    override func setUp() {
        super.setUp()

        self.mockProfile = MockProfile()
        self.subject = TabScrollingController()
        self.tab = Tab(profile: mockProfile, configuration: WKWebViewConfiguration())
        FeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)
        mockGesture = UIPanGestureRecognizerMock()
    }

    override func tearDown() {
        super.tearDown()

        mockProfile?.shutdown()
        self.mockProfile = nil
        self.subject = nil
        self.tab = nil
    }

    func testHandlePan_ScrollingUp() {
        tab.createWebview()
        subject.tab = tab
        subject.contentSize = CGSize(width: 200, height: 2000)

        mockGesture.gestureTranslation = CGPoint(x: 0, y: 100)
        subject.handlePan(mockGesture)

        XCTAssertEqual(subject.toolbarState, TabScrollingController.ToolbarState.collapsed)
    }

    func testHandlePan_ScrollingDown() {
        tab.createWebview()
        subject.tab = tab
        subject.contentSize = CGSize(width: 200, height: 2000)

        mockGesture.gestureTranslation = CGPoint(x: 0, y: -100)
        subject.handlePan(mockGesture)

        XCTAssertEqual(subject.toolbarState, TabScrollingController.ToolbarState.visible)
    }
}
