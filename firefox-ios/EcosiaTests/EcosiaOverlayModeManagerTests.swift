// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class EcosiaOverlayModeManagerTests: XCTestCase {

    private var urlBar: MockURLBarView!
    private var subject: MockOverlayModeManager!

    override func setUp() {
        super.setUp()
        urlBar = MockURLBarView()
        subject = MockOverlayModeManager()
    }

    override func tearDown() {
        super.tearDown()
        urlBar = nil
        subject = nil
    }

    // MARK: - Test URLBarView Overlay override nil
    func testOverridesToEnterOverlayMode_EntersOverlayMode_ForNewTabHome_WithNilURL() {
        subject.setURLBar(urlBarView: urlBar)
        subject.openNewTab(url: nil, newTabSettings: .topSites)
        XCTAssertFalse(subject.inOverlayMode)
        subject.overrideShouldEnterOverlayMode = true
        subject.openNewTab(url: nil, newTabSettings: .topSites)
        XCTAssertTrue(subject.inOverlayMode)
        XCTAssertEqual(subject.enterOverlayModeCallCount, 2)
    }

    func testOverridesToEnterOverlayMode_EntersOverlayMode_ForNewTabHome_WithHomeURL() {
        subject.setURLBar(urlBarView: urlBar)
        subject.openNewTab(url: URL(string: "internal://local/about/home"),
                           newTabSettings: .topSites)
        XCTAssertFalse(subject.inOverlayMode)
        subject.overrideShouldEnterOverlayMode = true
        subject.openNewTab(url: nil, newTabSettings: .topSites)
        XCTAssertTrue(subject.inOverlayMode)
        XCTAssertEqual(subject.enterOverlayModeCallCount, 2)
    }
}
