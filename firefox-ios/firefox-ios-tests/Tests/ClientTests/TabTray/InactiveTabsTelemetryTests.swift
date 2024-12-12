// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class InactiveTabsTelemetryTests: XCTestCase {
    var subject: InactiveTabsTelemetry?

    override func setUp() {
        super.setUp()
        // Due to changes allow certain custom pings to implement their own opt-out
        // independent of Glean, custom pings may need to be registered manually in
        // tests in order to puth them in a state in which they can collect data.
        Glean.shared.registerPings(GleanMetrics.Pings.shared)
        Glean.shared.resetGlean(clearStores: true)
        subject = InactiveTabsTelemetry()
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func testRecordInactiveTabWhenSectionShownThenGleanIsCalled() throws {
        subject?.sectionShown()

        testCounterMetricRecordingSuccess(metric: GleanMetrics.InactiveTabsTray.inactiveTabShown)
    }

    func testRecordInactiveTabWhenClosedAllTabsThenGleanIsCalled() throws {
        subject?.closedAllTabs()

        testCounterMetricRecordingSuccess(metric: GleanMetrics.InactiveTabsTray.inactiveTabsCloseAllBtn)
    }

    func testRecordInactiveTabWhenTabOpenedThenGleanIsCalled() throws {
        subject?.tabOpened()

        testCounterMetricRecordingSuccess(metric: GleanMetrics.InactiveTabsTray.openInactiveTab)
    }

    func testRecordInactiveTabWhenTabSwipedClosedThenGleanIsCalled() throws {
        subject?.tabSwipedToClose()

        testCounterMetricRecordingSuccess(metric: GleanMetrics.InactiveTabsTray.inactiveTabSwipeClose)
    }

    func testRecordInactiveTabWhenThenGleanIsCalled() throws {
        subject?.sectionToggled(hasExpanded: true)

        testEventMetricRecordingSuccess(metric: GleanMetrics.InactiveTabsTray.toggleInactiveTabTray)
    }
}
