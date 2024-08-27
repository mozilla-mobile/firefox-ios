// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class HomepageTelemetryTests: XCTestCase {
    override func setUp() {
        super.setUp()
        Glean.shared.resetGlean(clearStores: true)
    }

    func testPrivateModeShortcutToggleTappedInNormalMode() throws {
        let subject = HomepageTelemetry()

        subject.sendHomepageTappedTelemetry(enteringPrivateMode: true)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Homepage.privateModeToggle)

        let resultValue = try XCTUnwrap(GleanMetrics.Homepage.privateModeToggle.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private_mode"], "true")
    }

    func testPrivateModeShortcutToggleTappedInPrivateMode() throws {
        let subject = HomepageTelemetry()

        subject.sendHomepageTappedTelemetry(enteringPrivateMode: false)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Homepage.privateModeToggle)

        let resultValue = try XCTUnwrap(GleanMetrics.Homepage.privateModeToggle.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private_mode"], "false")
    }
}
