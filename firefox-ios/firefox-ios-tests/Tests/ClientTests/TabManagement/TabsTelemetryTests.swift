// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Glean
import XCTest
import Common

// TODO: FXIOS-TODO Laurie - Migrate TabsTelemetryTests to use mock telemetry or GleanWrapper
class TabsTelemetryTests: XCTestCase {
    var profile: Profile!
    var inactiveTabsManager: MockInactiveTabsManager!

    override func setUp() {
        super.setUp()

        profile = MockProfile()
        inactiveTabsManager = MockInactiveTabsManager()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        setupTelemetry(with: profile)
    }

    override func tearDown() {
        profile = nil
        tearDownTelemetry()
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
