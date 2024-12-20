// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class InactiveTabsTelemetryTests: XCTestCase {
    var subject: InactiveTabsTelemetry?
    var gleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        gleanWrapper = MockGleanWrapper()
        subject = InactiveTabsTelemetry(gleanWrapper: gleanWrapper)
    }

    override func tearDown() {
        subject = nil
        gleanWrapper = nil
        super.tearDown()
    }

    func testRecordInactiveTabWhenSectionShownThenGleanIsCalled() throws {
        subject?.sectionShown()

        XCTAssertEqual(gleanWrapper.submitCounterMetricTypeCalled, 1)
        let savedMetric = gleanWrapper.savedEvent as! CounterMetricType
        XCTAssert(type(of: savedMetric) == type(of: GleanMetrics.InactiveTabsTray.inactiveTabShown))
    }

    func testRecordInactiveTabWhenClosedAllTabsThenGleanIsCalled() throws {
        subject?.closedAllTabs()

        XCTAssertEqual(gleanWrapper.submitCounterMetricTypeCalled, 1)
        let savedMetric = gleanWrapper.savedEvent as! CounterMetricType
        XCTAssert(type(of: savedMetric) == type(of: GleanMetrics.InactiveTabsTray.inactiveTabsCloseAllBtn))
    }

    func testRecordInactiveTabWhenTabOpenedThenGleanIsCalled() throws {
        subject?.tabOpened()

        XCTAssertEqual(gleanWrapper.submitCounterMetricTypeCalled, 1)
        let savedMetric = gleanWrapper.savedEvent as! CounterMetricType
        XCTAssert(type(of: savedMetric) == type(of: GleanMetrics.InactiveTabsTray.openInactiveTab))
    }

    func testRecordInactiveTabWhenTabSwipedClosedThenGleanIsCalled() throws {
        subject?.tabSwipedToClose()

        XCTAssertEqual(gleanWrapper.submitCounterMetricTypeCalled, 1)
        let savedMetric = gleanWrapper.savedEvent as! CounterMetricType
        XCTAssert(type(of: savedMetric) == type(of: GleanMetrics.InactiveTabsTray.inactiveTabSwipeClose))
    }

    func testRecordInactiveTabWhenThenGleanIsCalled() throws {
        subject?.sectionToggled(hasExpanded: true)

        XCTAssertEqual(gleanWrapper.submitEventMetricTypeCalled, 1)
        let savedMetric = gleanWrapper.savedEvent as! EventMetricType<GleanMetrics.InactiveTabsTray.ToggleInactiveTabTrayExtra>
        XCTAssert(type(of: savedMetric) == type(of: GleanMetrics.InactiveTabsTray.toggleInactiveTabTray))
    }
}
