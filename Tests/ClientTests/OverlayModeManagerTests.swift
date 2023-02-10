// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client
class OverlayModeManagerTests: XCTestCase {
    private var urlBar: MockURLBarView!
    private var subject: OverlayModeManager!

    override func setUp() {
        super.setUp()

        urlBar = MockURLBarView()
        subject = MockOverlayModeManager(urlBarView: urlBar)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testEnterOverlayMode_ForNewTabWithNilURL() {
        subject.openNewTab(nil, url: nil)

        XCTAssertTrue(subject.inOverlayMode)
    }

    func testEnterOverlayMode_ForNewTabWithHomeURL() {
        subject.openNewTab(nil, url: URL(string: "internal://local/about/home"))

        XCTAssertTrue(subject.inOverlayMode)
    }

    func testEnterOverlayMode_ForNewTabWithURL() {
        subject.openNewTab(nil, url: URL(string: "https://test.com"))

        XCTAssertFalse(subject.inOverlayMode)
    }
}
