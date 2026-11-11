// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class TabLossTelemetryTests: XCTestCase {
    var subject: TabLossTelemetry!
    var gleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        gleanWrapper = MockGleanWrapper()
        subject = TabLossTelemetry(gleanWrapper: gleanWrapper)
    }

    override func tearDown() {
        subject = nil
        gleanWrapper = nil
        super.tearDown()
    }

    func testRecordTabLossDetected_includesExtras() throws {
        let event = GleanMetrics.AppErrors.tabLossDetected
        typealias EventExtrasType = GleanMetrics.AppErrors.TabLossDetectedExtra
        let expectedTabDiagnostic = TabLossTelemetry.TabLossDiagnostic(
            actual: 3,
            expected: 3,
            missing: 0,
            windows: 1
        )

        subject.recordTabLossDetected(withDetails: expectedTabDiagnostic)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        let actualCount = try XCTUnwrap(savedExtras.actual)
        let expectedCount = try XCTUnwrap(savedExtras.expected)
        let missingCount = try XCTUnwrap(savedExtras.missing)
        let windowsCount = try XCTUnwrap(savedExtras.windows)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertTrue(savedMetric === event, "Received \(savedMetric) instead of \(event)")

        XCTAssertTrue(actualCount == expectedTabDiagnostic.actual)
        XCTAssertTrue(expectedCount == expectedTabDiagnostic.expected)
        XCTAssertTrue(missingCount == expectedTabDiagnostic.missing)
        XCTAssertTrue(windowsCount == expectedTabDiagnostic.windows)
    }

    func testRecordTabCountDiscrepancy_includesExtras() throws {
        let event = GleanMetrics.AppErrors.tabCountDiscrepancy
        typealias EventExtrasType = GleanMetrics.AppErrors.TabCountDiscrepancyExtra
        let expectedTabDiagnostic = TabLossTelemetry.TabLossDiagnostic(
            actual: 3,
            expected: 3,
            missing: 0,
            windows: 1
        )

        subject.recordTabCountDiscrepancy(withDetails: expectedTabDiagnostic)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        let actualCount = try XCTUnwrap(savedExtras.actual)
        let expectedCount = try XCTUnwrap(savedExtras.expected)
        let missingCount = try XCTUnwrap(savedExtras.missing)
        let windowsCount = try XCTUnwrap(savedExtras.windows)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertTrue(savedMetric === event, "Received \(savedMetric) instead of \(event)")

        XCTAssertTrue(actualCount == expectedTabDiagnostic.actual)
        XCTAssertTrue(expectedCount == expectedTabDiagnostic.expected)
        XCTAssertTrue(missingCount == expectedTabDiagnostic.missing)
        XCTAssertTrue(windowsCount == expectedTabDiagnostic.windows)
    }

    func testRecordTabLossDetected_doesNotOverflowInt32Extra() throws {
        // Glean is using Int32 under the hood so we want to make sure no crashes due to type coercion from Int
        let expectedTabDiagnostic = TabLossTelemetry.TabLossDiagnostic(
            actual: Int.max,
            expected: Int.max,
            missing: Int.max,
            windows: Int.max
        )

        subject.recordTabCountDiscrepancy(withDetails: expectedTabDiagnostic)
        subject.recordTabLossDetected(withDetails: expectedTabDiagnostic)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 2)
    }
}
