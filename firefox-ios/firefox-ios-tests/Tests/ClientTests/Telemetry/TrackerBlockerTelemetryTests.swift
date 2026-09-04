// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class TrackerBlockerTelemetryTests: XCTestCase {
    var subject: TrackerBlockerTelemetry?
    var gleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        gleanWrapper = MockGleanWrapper()
        subject = TrackerBlockerTelemetry(gleanWrapper: gleanWrapper)
    }

    override func tearDown() {
        subject = nil
        gleanWrapper = nil
        super.tearDown()
    }

    func testRecordEvent_WhenLifetimeThresholdReached_ThenGleanIsCalled() throws {
        let event = GleanMetrics.TrackerBlocker.lifetimeThresholdReached
        typealias EventExtrasType = GleanMetrics.TrackerBlocker.LifetimeThresholdReachedExtra
        let expectedFigures: Int32 = 5

        subject?.lifetimeThresholdReached(figures: 5)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.figures, expectedFigures)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    // MARK: - Dashboard viewed

    func testRecordEvent_WhenDashboardViewed_ThenGleanIsCalled() throws {
        let event = GleanMetrics.TrackerBlocker.dashboardViewed

        subject?.dashboardViewed(presentation: .filled, lifetimeCount: 12_345)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? DashboardViewedExtras)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<DashboardViewedExtras>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.dashboardState, "populated")
        XCTAssertEqual(savedExtras.figures, 5)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testDashboardViewed_WhenSheetIsEmpty_ThenRecordsEmptyState() throws {
        subject?.dashboardViewed(presentation: .empty, lifetimeCount: 0)

        XCTAssertEqual(try savedDashboardExtras().dashboardState, "empty")
    }

    func testDashboardViewed_WhenWeeklyCountIsZero_ThenRecordsWeeklyReset() throws {
        subject?.dashboardViewed(presentation: .weeklyReset, lifetimeCount: 5305)

        XCTAssertEqual(try savedDashboardExtras().dashboardState, "weekly_reset")
    }

    // MARK: - Dashboard viewed: lifetime bands

    func testDashboardViewed_WhenLifetimeIsBelowTheLowestBand_ThenOmitsFigures() throws {
        subject?.dashboardViewed(presentation: .filled, lifetimeCount: 999)

        let savedExtras = try savedDashboardExtras()
        XCTAssertNil(savedExtras.figures)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1, "The open is still recorded without a band")
        XCTAssertNil(savedExtras.toExtraRecord()["figures"])
    }

    func testDashboardViewed_WhenNothingHasBeenBlocked_ThenOmitsFigures() throws {
        subject?.dashboardViewed(presentation: .empty, lifetimeCount: 0)

        XCTAssertNil(try savedDashboardExtras().figures)
    }

    func testDashboardViewed_WhenLifetimeIsInABand_ThenRecordsItsFigures() throws {
        let bands: [(lifetimeCount: Int, figures: Int32)] = [
            (1_000, 4),
            (9_999, 4),
            (10_000, 5),
            (100_000, 6),
            (1_000_000, 7),
            (10_000_000, 8)
        ]

        for band in bands {
            gleanWrapper = MockGleanWrapper()
            subject = TrackerBlockerTelemetry(gleanWrapper: gleanWrapper)

            subject?.dashboardViewed(presentation: .filled, lifetimeCount: band.lifetimeCount)

            XCTAssertEqual(try savedDashboardExtras().figures,
                           band.figures,
                           "Expected \(band.lifetimeCount) to band as \(band.figures) figures")
        }
    }

    func testDashboardViewed_WhenLifetimeIsAboveTheHighestBand_ThenCapsFigures() throws {
        subject?.dashboardViewed(presentation: .filled, lifetimeCount: 1_500_000_000)

        XCTAssertEqual(try savedDashboardExtras().figures, 8)
    }

    // MARK: - Helpers

    private typealias DashboardViewedExtras = GleanMetrics.TrackerBlocker.DashboardViewedExtra

    private func savedDashboardExtras() throws -> DashboardViewedExtras {
        return try XCTUnwrap(gleanWrapper.savedExtras.first as? DashboardViewedExtras)
    }
}
