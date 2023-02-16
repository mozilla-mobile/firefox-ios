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
        subject.setURLBar(urlBarView: urlBar)
    }

    override func tearDown() {
        super.tearDown()
        urlBar = nil
        subject = nil
    }

    // MARK: - Test EnterOverlay for New tab
    func testEnterOverlayMode_ForNewTabWithNilURL() {
        subject.openNewTab(nil, url: nil)

        XCTAssertTrue(subject.inOverlayMode)
    }

    func testEnterOverlayMode_ForNewTabWithHomeURL() {
        subject.openNewTab(nil, url: URL(string: "internal://local/about/home"))

        XCTAssertTrue(subject.inOverlayMode)
        XCTAssertEqual(subject.enterOverlayModeCallCount, 1)
    }

    func testEnterOverlayMode_ForNewTabWithURL() {
        subject.openNewTab(nil, url: URL(string: "https://test.com"))

        XCTAssertFalse(subject.inOverlayMode)
        XCTAssertEqual(subject.enterOverlayModeCallCount, 1)
    }

    // MARK: - Test EnterOverlay for paste action

    func testEnterOverlayMode_ForPasteContent() {
        subject.openSearch(with: "paste")

        XCTAssertTrue(subject.inOverlayMode)
        XCTAssertEqual(subject.enterOverlayModeCallCount, 1)
    }

    // MARK: - Test EnterOverlay for finish edition

    func testLeaveOverlayMode_ForFinishEdition() {
        subject.finishEdition(shouldCancelLoading: true)

        XCTAssertFalse(subject.inOverlayMode)
        XCTAssertEqual(subject.leaveOverlayModeCallCount, 1)
    }

    // MARK: - Test EnterOverlay for Tab change
    func testEnterOverlayMode_ForSwitchTab() {
        subject.switchTab(shouldCancelLoading: true)

        XCTAssertFalse(subject.inOverlayMode)
        XCTAssertEqual(subject.leaveOverlayModeCallCount, 1)
    }
}
