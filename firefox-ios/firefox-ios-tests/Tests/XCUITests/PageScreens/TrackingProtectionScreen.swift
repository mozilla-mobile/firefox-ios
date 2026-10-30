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
    func assertPanelHeader(domain: String) {
        let subtitle = sel.PANEL_SUBTITLE_LABEL.element(in: app)
        BaseTestCase().waitForElementsToExist(
            [sel.PANEL_TITLE_LABEL.element(in: app), subtitle, sel.PANEL_CLOSE_BUTTON.element(in: app)]
        )
        XCTAssertEqual(subtitle.label, domain, "Expected the panel header to show the website domain")
    }

    @MainActor
    func assertPanelConnectionIs(secure: Bool) {
        let statusButton = sel.SECURITY_STATUS_BUTTON.element(in: app)
        BaseTestCase().mozWaitForElementToExist(statusButton)
        let expectedLabel: String = secure ?
            .Menu.EnhancedTrackingProtection.connectionSecureLabel :
            .Menu.EnhancedTrackingProtection.connectionUnsecureLabel
        XCTAssertEqual(statusButton.label, expectedLabel, "Unexpected connection status in the panel")
    }

    @MainActor
    func assertPanelTrackingProtectionSwitchValue(isOn: Bool) {
        let toggle = sel.PANEL_TRACKING_PROTECTION_SWITCH.element(in: app)
        BaseTestCase().mozWaitForElementToExist(toggle)
        XCTAssertEqual(toggle.value as? String,
                       isOn ? "1" : "0",
                       "Unexpected Enhanced Tracking Protection switch value in the panel")
    }

    @MainActor
    func tapPrivacySettings() {
        sel.PANEL_PRIVACY_SETTINGS_BUTTON.element(in: app).waitAndTap()
    }

    /// Checks the Tracking Protection settings opened from the panel: navigation bar, switch and levels.
    @MainActor
    func assertTrackingProtectionSettingsOpenedFromPanel() {
        let standardCell = sel.SETTINGS_STANDARD_CELL.element(in: app)
        let strictCell = sel.SETTINGS_STRICT_CELL.element(in: app)
        BaseTestCase().waitForElementsToExist(
            [
                sel.SETTINGS_NAVIGATION_BAR.element(in: app),
                sel.SETTINGS_BACK_BUTTON.element(in: app),
                sel.SETTINGS_DONE_BUTTON.element(in: app),
                standardCell,
                strictCell
            ]
        )
        assertTrackingProtectionSwitchValue(isOn: true)
        XCTAssertTrue(standardCell.staticTexts[String.TrackingProtectionOptionBlockListLevelStandard].exists,
                      "Expected the Standard (default) protection level option")
        XCTAssertTrue(strictCell.staticTexts[String.TrackingProtectionOptionBlockListLevelStrict].exists,
                      "Expected the Strict protection level option")
    }

    @MainActor
    func closePanel() {
        sel.PANEL_CLOSE_BUTTON.element(in: app).waitAndTap()
    }

    @MainActor
    func selectStrictProtectionLevel() {
        sel.SETTINGS_STRICT_CELL.element(in: app).waitAndTap()
    }

    @MainActor
    func closeTrackingProtectionSettings() {
        sel.SETTINGS_DONE_BUTTON.element(in: app).waitAndTap()
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
