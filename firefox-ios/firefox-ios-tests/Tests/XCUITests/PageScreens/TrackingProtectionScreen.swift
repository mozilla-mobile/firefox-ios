// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class TrackingProtectionScreen {
    private let app: XCUIApplication
    private let sel: TrackingProtectionSelectorsSet

    init(app: XCUIApplication, selectors: TrackingProtectionSelectorsSet = TrackingProtectionSelectors()) {
        self.app = app
        self.sel = selectors
    }

    @MainActor
    func assertTrackingProtectionSwitchIsEnabled() {
        let toggle = sel.TRACKING_PROTECTION_SWITCH.element(in: app)
        BaseTestCase().mozWaitForElementToExist(toggle)
        XCTAssertTrue(toggle.isEnabled, "Expected Tracking Protection switch to be enabled")
    }

    @MainActor
    func assertTrackingProtectionSwitchIsDisabled() {
        let toggle = sel.TRACKING_PROTECTION_SWITCH.element(in: app)
        BaseTestCase().mozWaitForElementToExist(toggle)
        XCTAssertFalse(toggle.isEnabled, "Expected Tracking Protection switch to be disabled")
    }
}
