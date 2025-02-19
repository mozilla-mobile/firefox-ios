// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client
class OverlayModeManagerTests: XCTestCase {
    private var urlBar: MockURLBarView!
    private var subject: MockOverlayModeManager!

    override func setUp() {
        super.setUp()
        urlBar = MockURLBarView()
        subject = MockOverlayModeManager()
    }

    override func tearDown() {
        urlBar = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - Test URLBarView nil
    func testOverlayMode_ForNilURLBar() {
        urlBar = nil
        subject.openSearch(with: "search")
        XCTAssertFalse(subject.inOverlayMode)
    }

    // MARK: - Test EnterOverlay for New tab
    func testEnterOverlayMode_ForNewTabHome_WithNilURL() {
        subject.setURLBar(urlBarView: urlBar)
        subject.openNewTab(url: nil, newTabSettings: .topSites)

        XCTAssertTrue(subject.inOverlayMode)
        XCTAssertEqual(subject.enterOverlayModeCallCount, 1)
    }

    func testEnterOverlayMode_ForNewTabHome_WithHomeURL() {
        subject.setURLBar(urlBarView: urlBar)
        subject.openNewTab(url: URL(string: "internal://local/about/home"),
                           newTabSettings: .topSites)

        XCTAssertTrue(subject.inOverlayMode)
        XCTAssertEqual(subject.enterOverlayModeCallCount, 1)
    }

    func testEnterOverlayMode_ForNewTabHome_WithURL() {
        subject.setURLBar(urlBarView: urlBar)
        subject.openNewTab(url: URL(string: "https://test.com"),
                           newTabSettings: .topSites)

        XCTAssertFalse(subject.inOverlayMode)
        XCTAssertEqual(subject.enterOverlayModeCallCount, 1)
    }

    func testEnterOverlayMode_ForBlankPage_WithNilURL() {
        subject.setURLBar(urlBarView: urlBar)
        subject.openNewTab(url: nil, newTabSettings: .blankPage)

        XCTAssertTrue(subject.inOverlayMode)
        XCTAssertEqual(subject.enterOverlayModeCallCount, 1)
    }

    func testEnterOverlayMode_ForBlankPage_WithURL() {
        subject.setURLBar(urlBarView: urlBar)
        subject.openNewTab(url: URL(string: "https://test.com"),
                           newTabSettings: .blankPage)

        XCTAssertTrue(subject.inOverlayMode)
        XCTAssertEqual(subject.enterOverlayModeCallCount, 1)
    }

    func testNotEnterOverlayMode_ForCustomUrl() {
        subject.setURLBar(urlBarView: urlBar)
        subject.openNewTab(url: URL(string: "https://test.com"),
                           newTabSettings: .homePage)

        XCTAssertFalse(subject.inOverlayMode)
    }

    func testNotEnterOverlayMode_ForCustomUrl_WithNilURL() {
        subject.setURLBar(urlBarView: urlBar)
        subject.openNewTab(url: nil,
                           newTabSettings: .homePage)

        XCTAssertFalse(subject.inOverlayMode)
    }

    // MARK: - Test EnterOverlay for paste action

    func testEnterOverlayMode_ForPasteContent() {
        subject.setURLBar(urlBarView: urlBar)
        subject.openSearch(with: "paste")

        XCTAssertTrue(subject.inOverlayMode)
        XCTAssertEqual(subject.enterOverlayModeCallCount, 1)
    }

    // MARK: - Test EnterOverlay for finish editing

    func testLeaveOverlayMode_ForFinishEditing() {
        subject.setURLBar(urlBarView: urlBar)
        subject.finishEditing(shouldCancelLoading: true)

        XCTAssertFalse(subject.inOverlayMode)
        XCTAssertEqual(subject.leaveOverlayModeCallCount, 1)
    }

    // MARK: - Test EnterOverlay for Tab change
    func testLeaveOverlayMode_ForSwitchTab() {
        subject.setURLBar(urlBarView: urlBar)
        subject.switchTab(shouldCancelLoading: true)

        XCTAssertFalse(subject.inOverlayMode)
        XCTAssertEqual(subject.leaveOverlayModeCallCount, 1)
    }

    func testLeaveOverlayMode_ForSwitchTabInOverlayMode() {
        subject.setURLBar(urlBarView: urlBar)
        subject.openSearch(with: "")
        subject.switchTab(shouldCancelLoading: true)

        XCTAssertFalse(subject.inOverlayMode)
        XCTAssertEqual(subject.leaveOverlayModeCallCount, 1)
    }
}
