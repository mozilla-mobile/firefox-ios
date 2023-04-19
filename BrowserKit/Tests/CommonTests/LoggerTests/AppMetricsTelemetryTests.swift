// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MetricKit
import Sentry
@testable import Common

class AppMetricsTelemetryTests: XCTestCase {
    private var sentryWrapper: MockSentryWrapper!

    override func setUp() {
        super.setUp()

        sentryWrapper = MockSentryWrapper()
    }

    override func tearDown() {
        super.tearDown()

        sentryWrapper = nil
    }

    func test_didReceivePayloadWithNoData() {
        let subject = AppMetricsManager(sentryWrapper: sentryWrapper)

        // Forcing a didReceive for tests, but this should never be called like this.
        // The system will call this method on its own when payload data is available.
        subject.didReceive([MXMetricPayload()])
        XCTAssert(subject.metrics.isEmpty)
    }
}
