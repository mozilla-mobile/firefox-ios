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

    func testRecordInactiveTab_WhenSectionShown_ThenGleanIsCalled() throws {
        subject?.sectionShown()

        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents?[0] as? CounterMetricType)
        let expectedMetricType = type(of: GleanMetrics.InactiveTabsTray.inactiveTabShown)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(gleanWrapper.incrementCounterCalled, 1)
    }

    func testRecordInactiveTab_WhenClosedAllTabs_ThenGleanIsCalled() throws {
        subject?.closedAllTabs()

        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents?[0] as? CounterMetricType)
        let expectedMetricType = type(of: GleanMetrics.InactiveTabsTray.inactiveTabsCloseAllBtn)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(gleanWrapper.incrementCounterCalled, 1)
    }

    func testRecordInactiveTab_WhenTabOpened_ThenGleanIsCalled() throws {
        subject?.tabOpened()

        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents?[0] as? CounterMetricType)
        let expectedMetricType = type(of: GleanMetrics.InactiveTabsTray.openInactiveTab)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(gleanWrapper.incrementCounterCalled, 1)
    }

    func testRecordInactiveTab_WhenTabSwipedClosed_ThenGleanIsCalled() throws {
        subject?.tabSwipedToClose()

        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents?[0] as? CounterMetricType)
        let expectedMetricType = type(of: GleanMetrics.InactiveTabsTray.inactiveTabSwipeClose)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(gleanWrapper.incrementCounterCalled, 1)
    }

    func testRecordInactiveTab_WhenSectionToggled_ThenGleanIsCalled() throws {
        subject?.sectionToggled(hasExpanded: true)

        let savedMetric = try XCTUnwrap(
            gleanWrapper.savedEvents?[0] as? EventMetricType<GleanMetrics.InactiveTabsTray.ToggleInactiveTabTrayExtra>
        )
        let expectedMetricType = type(of: GleanMetrics.InactiveTabsTray.toggleInactiveTabTray)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
    }
}
