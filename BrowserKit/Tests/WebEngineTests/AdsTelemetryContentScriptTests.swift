// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class AdsTelemetryContentScriptTests: XCTestCase {
    private var adsTelemetryDelegate: MockAdsTelemetryDelegate!

    override func setUp() {
        super.setUp()
        adsTelemetryDelegate = MockAdsTelemetryDelegate()
    }

    override func tearDown() {
        super.tearDown()
        adsTelemetryDelegate = nil
    }

    func testDidReceiveMessageGivenEmptyMessageThenNoDelegateCalled() {
        let subject = AdsTelemetryContentScript(delegate: adsTelemetryDelegate)

        subject.userContentController(didReceiveMessage: [])

        XCTAssertEqual(adsTelemetryDelegate.trackAdsFoundOnPageCalled, 0)
        XCTAssertEqual(adsTelemetryDelegate.trackAdsClickedOnPageCalled, 0)
    }
}
