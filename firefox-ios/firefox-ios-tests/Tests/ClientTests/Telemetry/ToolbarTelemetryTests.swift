// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class ToolbarTelemetryTests: XCTestCase {
    var subject: ToolbarTelemetry?

    override func setUp() {
        super.setUp()
        // Due to changes allow certain custom pings to implement their own opt-out
        // independent of Glean, custom pings may need to be registered manually in
        // tests in order to put them in a state in which they can collect data.
        Glean.shared.registerPings(GleanMetrics.Pings.shared)
        Glean.shared.resetGlean(clearStores: true)
        subject = ToolbarTelemetry()
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func testRecordToolbarWhenClearSearchTappedThenGleanIsCalled() throws {
        subject?.clearSearchButtonTapped(isPrivate: true)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.clearSearchButtonTapped)

        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.clearSearchButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "true")
    }

    func testRecordToolbarWhenTabTrayTappedThenGleanIsCalled() throws {
        subject?.tabTrayButtonTapped(isPrivate: true)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.tabTrayButtonTapped)

        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.tabTrayButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "true")
    }

    func testRecordToolbarWhenLocationDraggedThenGleanIsCalled() throws {
        subject?.dragInteractionStarted()
        testEventMetricRecordingSuccess(metric: GleanMetrics.Awesomebar.dragLocationBar)
    }
}
