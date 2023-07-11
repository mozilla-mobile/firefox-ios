// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Glean
import XCTest
import Common

class TabsQuantityTelemetryTests: XCTestCase {
    var profile: Profile!

    override func setUp() {
        super.setUp()

        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        Glean.shared.resetGlean(clearStores: true)
        Glean.shared.enableTestingMode()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()

        profile = nil
    }

    func testTrackTabsQuantity_withNormalTab_gleanIsCalled() {
        let tabManager = LegacyTabManager(profile: profile, imageStore: nil)
        tabManager.addTab()

        TabsQuantityTelemetry.trackTabsQuantity(tabManager: tabManager)

        testQuantityMetricSuccess(metric: GleanMetrics.Tabs.privateTabsQuantity,
                                  expectedValue: 0,
                                  failureMessage: "Should have 0 private tabs")

        testQuantityMetricSuccess(metric: GleanMetrics.Tabs.normalTabsQuantity,
                                  expectedValue: 1,
                                  failureMessage: "Should have 1 normal tab")
    }

    func testTrackTabsQuantity_withPrivateTab_gleanIsCalled() {
        let tabManager = LegacyTabManager(profile: profile, imageStore: nil)
        tabManager.addTab(isPrivate: true)

        TabsQuantityTelemetry.trackTabsQuantity(tabManager: tabManager)

        testQuantityMetricSuccess(metric: GleanMetrics.Tabs.privateTabsQuantity,
                                  expectedValue: 1,
                                  failureMessage: "Should have 1 private tab")

        testQuantityMetricSuccess(metric: GleanMetrics.Tabs.normalTabsQuantity,
                                  expectedValue: 0,
                                  failureMessage: "Should have 0 normal tabs")
    }

    func testTrackTabsQuantity_ensureNoInactiveTabs_gleanIsCalled() {
        let tabManager = LegacyTabManager(profile: profile, imageStore: nil)
        tabManager.addTab()

        TabsQuantityTelemetry.trackTabsQuantity(tabManager: tabManager)

        testQuantityMetricSuccess(metric: GleanMetrics.Tabs.privateTabsQuantity,
                                  expectedValue: 0,
                                  failureMessage: "Should have 0 private tabs")

        testQuantityMetricSuccess(metric: GleanMetrics.Tabs.inactiveTabsCount,
                                  expectedValue: 0,
                                  failureMessage: "Should have no inactive tabs, since a new tab was just created.")
    }
}
