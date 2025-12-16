// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Glean
import XCTest
import Common

// TODO: FXIOS-13742 - Migrate TabsTelemetryTests to use mock telemetry or GleanWrapper
@MainActor
class TabsTelemetryTests: XCTestCase {
    var gleanWrapper: MockGleanWrapper!

    override func setUp() async throws {
        try await super.setUp()
        gleanWrapper = MockGleanWrapper()
    }

    override func tearDown() async throws {
        gleanWrapper = nil
        try await super.tearDown()
    }

    func testTabSwitchMeasurement() throws {
        let subject = createSubject()

        subject.startTabSwitchMeasurement()
        subject.stopTabSwitchMeasurement()

        let event = GleanMetrics.Tabs.tabSwitch
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.last as? TimingDistributionMetricType)

        XCTAssertEqual(gleanWrapper.stopAndAccumulateCalled, 1)
        XCTAssertEqual(gleanWrapper.savedEvents.count, 2)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testrackConsecutiveCrashTelemetry() throws {
        let subject = createSubject()
        let numberOfCrash: UInt = 2
        typealias EventExtrasType = GleanMetrics.Webview.ProcessDidTerminateExtra
        let event = GleanMetrics.Webview.processDidTerminate

        subject.trackConsecutiveCrashTelemetry(attemptNumber: numberOfCrash)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.consecutiveCrash, Int32(numberOfCrash))
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    private func createSubject() -> TabsTelemetry {
        let subject = TabsTelemetry(gleanWrapper: gleanWrapper)
        trackForMemoryLeaks(subject)
        return subject
    }
}
