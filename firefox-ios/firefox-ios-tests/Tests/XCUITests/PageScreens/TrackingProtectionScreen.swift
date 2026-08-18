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

    @MainActor
    func tapConnectionSecurityStatus() {
        sel.SECURITY_STATUS_BUTTON.element(in: app).waitAndTap()
    }

    @MainActor
    func assertConnectionIsSecure() {
        let statusLabel = sel.DETAILS_CONNECTION_STATUS_LABEL.element(in: app)
        BaseTestCase().mozWaitForElementToExist(statusLabel)
        XCTAssertEqual(statusLabel.label,
                       "Secure connection",
                       "Expected the connection details screen to report a secure connection")
    }

    @MainActor
    func assertConnectionVerifiedByCertificate() {
        let verifiedByLabel = sel.DETAILS_VERIFIED_BY_LABEL.element(in: app)
        BaseTestCase().mozWaitForElementToExist(verifiedByLabel)
        XCTAssertTrue(verifiedByLabel.label.hasPrefix("Verified by"),
                      "Expected a certificate verifier, got \"\(verifiedByLabel.label)\"")
    }

    @MainActor
    func closeConnectionDetails() {
        sel.DETAILS_CLOSE_BUTTON.element(in: app).waitAndTap()
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
