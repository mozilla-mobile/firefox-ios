// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class TabErrorTelemetryHelperTests: XCTestCase {
    // MARK: - Tab Loss & Discrepancies

    func testtabDiscrepancyDetected_whenTwoTabsAreMissing_returnsTrue() {
        XCTAssertTrue(TabErrorTelemetryHelper.tabDiscrepancyDetected(expectedTabCount: 3, currentTabCount: 1))
    }

    func testtabDiscrepancyDetected_whenManyTabsAreMissing_returnsTrue() {
        XCTAssertTrue(TabErrorTelemetryHelper.tabDiscrepancyDetected(expectedTabCount: 10, currentTabCount: 1))
    }

    func testtabDiscrepancyDetected_whenOnlyOneTabIsMissing_returnsFalse() {
        XCTAssertFalse(TabErrorTelemetryHelper.tabDiscrepancyDetected(expectedTabCount: 5, currentTabCount: 4))
    }

    func testtabDiscrepancyDetected_whenNoTabsAreMissing_returnsFalse() {
        XCTAssertFalse(TabErrorTelemetryHelper.tabDiscrepancyDetected(expectedTabCount: 5, currentTabCount: 5))
    }

    func testtabDiscrepancyDetected_whenExpectedCountIsOne_returnsFalse() {
        XCTAssertFalse(TabErrorTelemetryHelper.tabDiscrepancyDetected(expectedTabCount: 1, currentTabCount: 0))
    }

    func testtabDiscrepancyDetected_whenCurrentCountExceedsExpected_returnsFalse() {
        XCTAssertFalse(TabErrorTelemetryHelper.tabDiscrepancyDetected(expectedTabCount: 3, currentTabCount: 5))
    }

    // MARK: - Signficant Tab Loss

    func testIsSignificantTabLossEvent_whenCountAndPercentThresholdsMet_returnsTrue() {
        XCTAssertTrue(TabErrorTelemetryHelper.isSignificantTabLossEvent(expectedTabCount: 5, currentTabCount: 1))
    }

    func testIsSignificantTabLossEvent_whenPercentExactlyAtThreshold_returnsTrue() {
        XCTAssertTrue(TabErrorTelemetryHelper.isSignificantTabLossEvent(expectedTabCount: 15, currentTabCount: 12))
    }

    func testIsSignificantTabLossEvent_whenCountExactlyAtThresholdWithHighPercent_returnsTrue() {
        XCTAssertTrue(TabErrorTelemetryHelper.isSignificantTabLossEvent(expectedTabCount: 4, currentTabCount: 1))
    }

    func testIsSignificantTabLossEvent_whenMissingCountBelowThreshold_returnsFalse() {
        XCTAssertFalse(TabErrorTelemetryHelper.isSignificantTabLossEvent(expectedTabCount: 3, currentTabCount: 1))
    }

    func testIsSignificantTabLossEvent_whenPercentBelowThreshold_returnsFalse() {
        XCTAssertFalse(TabErrorTelemetryHelper.isSignificantTabLossEvent(expectedTabCount: 20, currentTabCount: 17))
    }

    func testIsSignificantTabLossEvent_whenPercentJustBelowThreshold_returnsFalse() {
        XCTAssertFalse(TabErrorTelemetryHelper.isSignificantTabLossEvent(expectedTabCount: 16, currentTabCount: 13))
    }

    func testIsSignificantTabLossEvent_whenLargeAbsoluteButSmallProportionalLoss_returnsTrue() {
        XCTAssertTrue(TabErrorTelemetryHelper.isSignificantTabLossEvent(expectedTabCount: 100, currentTabCount: 80))
    }
}
