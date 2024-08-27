// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Glean
import XCTest
import Common

class TabsTelemetryTests: XCTestCase {
    var profile: Profile!
    var inactiveTabsManager: MockInactiveTabsManager!

    override func setUp() {
        super.setUp()

        profile = MockProfile()
        inactiveTabsManager = MockInactiveTabsManager()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        Glean.shared.resetGlean(clearStores: true)
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()

        profile = nil
    }

    func testTrackTabsQuantity_withNormalTab_gleanIsCalled() {
        let tabManager = TabManagerImplementation(profile: profile,
                                                  uuid: ReservedWindowUUID(uuid: .XCTestDefaultUUID, isNew: false),
                                                  inactiveTabsManager: inactiveTabsManager)

        let tab = tabManager.addTab()
        inactiveTabsManager.activeTabs = [tab]
        _ = inactiveTabsManager.getInactiveTabs(tabs: [tab])

        TabsTelemetry.trackTabsQuantity(tabManager: tabManager)

        testQuantityMetricSuccess(metric: GleanMetrics.Tabs.privateTabsQuantity,
                                  expectedValue: 0,
                                  failureMessage: "Should have 0 private tabs")

        testQuantityMetricSuccess(metric: GleanMetrics.Tabs.normalTabsQuantity,
                                  expectedValue: 1,
                                  failureMessage: "Should have 1 normal tab")
    }

    func testTrackTabsQuantity_withPrivateTab_gleanIsCalled() {
        let tabManager = TabManagerImplementation(profile: profile,
                                                  uuid: ReservedWindowUUID(uuid: .XCTestDefaultUUID, isNew: false))
        tabManager.addTab(isPrivate: true)

        TabsTelemetry.trackTabsQuantity(tabManager: tabManager)

        testQuantityMetricSuccess(metric: GleanMetrics.Tabs.privateTabsQuantity,
                                  expectedValue: 1,
                                  failureMessage: "Should have 1 private tab")

        testQuantityMetricSuccess(metric: GleanMetrics.Tabs.normalTabsQuantity,
                                  expectedValue: 0,
                                  failureMessage: "Should have 0 normal tabs")
    }

    func testTrackTabsQuantity_ensureNoInactiveTabs_gleanIsCalled() {
        let tabManager = TabManagerImplementation(profile: profile,
                                                  uuid: ReservedWindowUUID(uuid: .XCTestDefaultUUID, isNew: false),
                                                  inactiveTabsManager: inactiveTabsManager)
        let tab = tabManager.addTab()
        inactiveTabsManager.activeTabs = [tab]
        _ = inactiveTabsManager.getInactiveTabs(tabs: [tab])

        TabsTelemetry.trackTabsQuantity(tabManager: tabManager)

        testQuantityMetricSuccess(metric: GleanMetrics.Tabs.privateTabsQuantity,
                                  expectedValue: 0,
                                  failureMessage: "Should have 0 private tabs")

        testQuantityMetricSuccess(metric: GleanMetrics.Tabs.inactiveTabsCount,
                                  expectedValue: 0,
                                  failureMessage: "Should have no inactive tabs, since a new tab was just created.")
    }

    func testTabSwitchMeasurement() throws {
        let subject = TabsTelemetry()

        subject.startTabSwitchMeasurement()
        subject.stopTabSwitchMeasurement()

        let resultValue = try XCTUnwrap(GleanMetrics.Tabs.tabSwitch.testGetValue())
        XCTAssertEqual(1, resultValue.count, "Should have been measured once")
        XCTAssertEqual(0, GleanMetrics.Tabs.tabSwitch.testGetNumRecordedErrors(.invalidValue))
    }
}
