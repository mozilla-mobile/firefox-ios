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

    // assertTrackingProtectionSwitchIsEnabled/Disabled above check whether the switch control
    // itself is interactable, not its on/off value. Use this to check the actual toggle state.
    @MainActor
    func assertTrackingProtectionSwitchValue(isOn: Bool) {
        let toggle = sel.TRACKING_PROTECTION_SWITCH.element(in: app)
        BaseTestCase().mozWaitForElementToExist(toggle)
        let expectedValue = isOn ? "1" : "0"
        XCTAssertEqual(
            toggle.value as? String,
            expectedValue,
            "Expected Tracking Protection switch value to be \(expectedValue)"
        )
    }
}
