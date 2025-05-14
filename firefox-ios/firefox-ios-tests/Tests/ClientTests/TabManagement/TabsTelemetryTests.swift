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
        // Due to changes allow certain custom pings to implement their own opt-out
        // independent of Glean, custom pings may need to be registered manually in
        // tests in order to put them in a state in which they can collect data.
        Glean.shared.registerPings(GleanMetrics.Pings.shared)
        Glean.shared.resetGlean(clearStores: true)
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        profile = nil
        DependencyHelperMock().reset()
        super.tearDown()
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
