// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import TestKit
import XCTest

@testable import Client

@MainActor
final class TabErrorTelemetryHelperTests: XCTestCase {
    private var mockTabLossTelemetry: MockTabLossTelemetry!
    private var mockDefaults: MockUserDefaults!
    private var mockTabManager: MockTabManager!
    private var mockWindowManager: MockWindowManager!
    private var mockProfile: MockProfile!
    private var profile: MockProfile!

    private let testWindowUUID: WindowUUID = .XCTestDefaultUUID
    private let foregroundDefaultsKey = "TabErrorTelemetryHelper_Data_BackgroundForegroundEvent"

    override func setUp() async throws {
        mockProfile = makeProfile()
        mockTabManager = MockTabManager(windowUUID: testWindowUUID)
        mockWindowManager = MockWindowManager(wrappedManager: WindowManagerImplementation(), tabManager: mockTabManager)
        mockWindowManager.overrideWindows = true

        DependencyHelperMock().bootstrapDependencies(
            injectedProfile: mockProfile,
            injectedWindowManager: mockWindowManager,
            injectedTabManager: mockTabManager
        )

        mockTabLossTelemetry = MockTabLossTelemetry()
        mockDefaults = MockUserDefaults()
    }

    override func tearDown() async throws {
        mockTabLossTelemetry = nil
        mockDefaults = nil
        try await super.tearDown()
    }

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

    // MARK: - Significant Tab Loss

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

    // MARK: Test Telemetry sending

    func testValidateTabCountForForegroundedScene_whenSignificantLoss_sendsTabLossDetectedTelemetry() throws {
        let expectedTabCount = 5
        let currentTabCount = 1

        mockDefaults.set([testWindowUUID.uuidString: expectedTabCount], forKey: foregroundDefaultsKey)
        mockTabManager.normalTabs = (0..<currentTabCount).map { _ in Tab(profile: mockProfile, windowUUID: testWindowUUID) }

        let subject = createSubject()

        subject.validateTabCountForForegroundedScene(testWindowUUID)

        XCTAssertEqual(mockTabLossTelemetry.recordTabLossDetectedCalled, 1)
        XCTAssertEqual(mockTabLossTelemetry.recordTabCountDiscrepancyCalled, 0)

        let details = try XCTUnwrap(mockTabLossTelemetry.savedTabLossDetectedDetails)
        XCTAssertEqual(details.expected, expectedTabCount)
        XCTAssertEqual(details.actual, currentTabCount)
        XCTAssertEqual(details.missing, expectedTabCount - currentTabCount)
        XCTAssertEqual(details.windows, 1)

        XCTAssertNil(savedTabCounts?[testWindowUUID.uuidString])
    }

    func testValidateTabCountForForegroundedScene_whenMinorDiscrepancy_sendsTabCountDiscrepancyTelemetry() throws {
        // Significant tab loss requires both matching tabLossCountThreshold and a significantLossPercentThreshold
        let expectedTabCount = 20
        let currentTabCount = 17

        mockDefaults.set([testWindowUUID.uuidString: expectedTabCount], forKey: foregroundDefaultsKey)
        mockTabManager.normalTabs = (0..<currentTabCount).map { _ in Tab(profile: mockProfile, windowUUID: testWindowUUID) }

        let subject = createSubject()

        subject.validateTabCountForForegroundedScene(testWindowUUID)

        XCTAssertEqual(mockTabLossTelemetry.recordTabCountDiscrepancyCalled, 1)
        XCTAssertEqual(mockTabLossTelemetry.recordTabLossDetectedCalled, 0)

        let details = try XCTUnwrap(mockTabLossTelemetry.savedTabCountDiscrepancyDetails)
        XCTAssertEqual(details.expected, expectedTabCount)
        XCTAssertEqual(details.actual, currentTabCount)
        XCTAssertEqual(details.missing, expectedTabCount - currentTabCount)
        XCTAssertEqual(details.windows, 1)

        XCTAssertNil(savedTabCounts?[testWindowUUID.uuidString])
    }

    // MARK: - Helpers

    private var savedTabCounts: [String: Int]? {
        mockDefaults.object(forKey: foregroundDefaultsKey) as? [String: Int]
    }

    private func createSubject() -> TabErrorTelemetryHelper {
        return TabErrorTelemetryHelper(
            logger: MockLogger(),
            tabLossTelemetry: mockTabLossTelemetry,
            windowManager: mockWindowManager,
            defaults: mockDefaults
        )
    }
}
