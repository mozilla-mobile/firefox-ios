// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Glean
import XCTest

class TabsQuantityTelemetryTests: XCTestCase {

    override func setUp() {
        super.setUp()
        TabsQuantityTelemetry.quantitySent = false
    }

    func testTrackTabsQuantity_withNormalTab_gleanIsCalled() {
        let tabManager = TabManager(profile: MockProfile(), imageStore: nil)
        tabManager.addTab()

        TabsQuantityTelemetry().trackTabsQuantity(tabManager: tabManager)

        testQuantityMetricSuccess(metric: GleanMetrics.Tabs.privateTabsQuantity, expectedValue: 0)
        testQuantityMetricSuccess(metric: GleanMetrics.Tabs.normalTabsQuantity, expectedValue: 1)
    }

    func testTrackTabsQuantity_withPrivateTab_gleanIsCalled() {
        let tabManager = TabManager(profile: MockProfile(), imageStore: nil)
        tabManager.addTab(isPrivate: true)

        TabsQuantityTelemetry().trackTabsQuantity(tabManager: tabManager)

        testQuantityMetricSuccess(metric: GleanMetrics.Tabs.privateTabsQuantity, expectedValue: 1)
        testQuantityMetricSuccess(metric: GleanMetrics.Tabs.normalTabsQuantity, expectedValue: 0)
    }

    func testTrackTabsQuantity_quantityUserDefaultIsSet() {
        let tabManager = TabManager(profile: MockProfile(), imageStore: nil)
        XCTAssertFalse(TabsQuantityTelemetry.quantitySent)

        TabsQuantityTelemetry().trackTabsQuantity(tabManager: tabManager)
        XCTAssertTrue(TabsQuantityTelemetry.quantitySent)
    }

    func testTrackTabsQuantity_notificationResetQuantitySetUserDefault() {
        expectation(forNotification: UIApplication.didFinishLaunchingNotification, object: nil, handler: nil)

        let tabManager = TabManager(profile: MockProfile(), imageStore: nil)
        TabsQuantityTelemetry().trackTabsQuantity(tabManager: tabManager)
        XCTAssertTrue(TabsQuantityTelemetry.quantitySent)

        NotificationCenter.default.post(name: UIApplication.didFinishLaunchingNotification, object: nil)
        waitForExpectations(timeout: 0.1, handler: nil)

        XCTAssertFalse(TabsQuantityTelemetry.quantitySent)
    }
}
