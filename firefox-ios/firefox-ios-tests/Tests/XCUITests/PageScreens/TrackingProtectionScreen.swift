// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
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

    /// Checks the panel body for an insecure site, top to bottom: fox status texts, trackers section,
    /// "Connection is not secure", ETP switch on, Clear cookies and data, and Privacy settings.
    @MainActor
    func assertInsecureConnectionPanelStructure() {
        assertPanelStructure(
            foxTitle: .Menu.EnhancedTrackingProtection.onNotSecureTitle,
            foxStatus: .Menu.EnhancedTrackingProtection.onNotSecureHeader,
            trackers: .shown(label: .Menu.EnhancedTrackingProtection.noTrackersLabel),
            connectionSecure: false,
            protectionOn: true
        )
    }

    /// Checks the panel body for a secure site with protections turned off, top to bottom: fox status texts,
    /// "Secure connection", ETP switch off, Clear cookies and data, and Privacy settings. The trackers section is hidden.
    @MainActor
    func assertProtectionsOffPanelStructure() {
        assertPanelStructure(
            foxTitle: .Menu.EnhancedTrackingProtection.offTitle,
            foxStatus: String(format: .Menu.EnhancedTrackingProtection.offHeader, AppName.shortName.rawValue),
            trackers: .hidden,
            connectionSecure: true,
            protectionOn: false
        )
    }

    /// Checks the panel body for a secure site with protections on, top to bottom: fox status texts,
    /// trackers section, "Secure connection", ETP switch on, Clear cookies and data, and Privacy settings.
    /// The tracker count depends on the live site, so only the trackers section's presence is checked.
    @MainActor
    func assertProtectedPanelStructure() {
        assertPanelStructure(
            foxTitle: String(format: .Menu.EnhancedTrackingProtection.onTitle, AppName.shortName.rawValue),
            foxStatus: .Menu.EnhancedTrackingProtection.onHeader,
            trackers: .shown(label: nil),
            connectionSecure: true,
            protectionOn: true
        )
    }

    private enum PanelTrackersSection {
        case hidden
        /// `label` is the expected section label, or `nil` to only check the section is shown.
        case shown(label: String?)
    }

    @MainActor
    private func assertPanelStructure(
        foxTitle expectedFoxTitle: String,
        foxStatus expectedFoxStatus: String,
        trackers trackersSection: PanelTrackersSection,
        connectionSecure: Bool,
        protectionOn: Bool
    ) {
        let foxTitle = sel.PANEL_CONNECTION_DETAILS_TITLE.element(in: app)
        let foxStatus = sel.PANEL_CONNECTION_DETAILS_STATUS.element(in: app)
        let trackers = sel.PANEL_TRACKERS_BUTTON.element(in: app)
        let clearCookies = sel.PANEL_CLEAR_COOKIES_BUTTON.element(in: app)
        let privacySettings = sel.PANEL_PRIVACY_SETTINGS_BUTTON.element(in: app)
        var sections = [
            sel.PANEL_TITLE_LABEL.element(in: app),
            sel.PANEL_SUBTITLE_LABEL.element(in: app),
            foxTitle,
            foxStatus
        ]
        if case .shown = trackersSection {
            sections.append(trackers)
        }
        sections += [
            sel.SECURITY_STATUS_BUTTON.element(in: app),
            sel.PANEL_TRACKING_PROTECTION_SWITCH.element(in: app),
            clearCookies,
            privacySettings
        ]
        BaseTestCase().waitForElementsToExist(sections)

        XCTAssertEqual(foxTitle.label, expectedFoxTitle, "Unexpected fox title")
        XCTAssertEqual(foxStatus.label, expectedFoxStatus, "Unexpected fox status")
        switch trackersSection {
        case .hidden:
            BaseTestCase().mozWaitForElementToNotExist(trackers)
        case .shown(let label?):
            XCTAssertEqual(trackers.label, label, "Unexpected trackers section")
        case .shown(nil):
            break
        }
        assertPanelConnectionIs(secure: connectionSecure)
        assertPanelTrackingProtectionSwitchValue(isOn: protectionOn)
        XCTAssertEqual(clearCookies.label,
                       String.Menu.EnhancedTrackingProtection.clearDataButtonTitle,
                       "Unexpected Clear cookies button")
        XCTAssertEqual(privacySettings.label,
                       String.Menu.EnhancedTrackingProtection.privacySettingsTitle,
                       "Unexpected Privacy settings link")

        for (upper, lower) in zip(sections, sections.dropFirst()) {
            XCTAssertTrue(upper.isAbove(element: lower), "\(upper.identifier) should be above \(lower.identifier)")
        }
    }

    @MainActor
    func assertSecureConnectionIsBelowTrackers() {
        let trackers = sel.PANEL_TRACKERS_BUTTON.element(in: app)
        let connection = sel.SECURITY_STATUS_BUTTON.element(in: app)
        BaseTestCase().waitForElementsToExist([trackers, connection])
        assertPanelConnectionIs(secure: true)
        XCTAssertTrue(connection.isBelow(element: trackers), "Secure connection should be below the trackers section")
    }

    /// With protections off the fox illustration turns grayscale and the trackers section is hidden,
    /// so "Secure connection" sits right below the illustration.
    @MainActor
    func assertSecureConnectionIsBelowGrayedOutFox() {
        let foxImage = sel.PANEL_FOX_IMAGE.element(in: app)
        let connection = sel.SECURITY_STATUS_BUTTON.element(in: app)
        BaseTestCase().waitForElementsToExist([foxImage, connection])
        BaseTestCase().mozWaitForElementToNotExist(sel.PANEL_TRACKERS_BUTTON.element(in: app))
        let saturatedRatio = foxImage.saturatedPixelRatio()
        XCTAssertLessThan(saturatedRatio, 0.02, "Expected a grayed out fox, \(saturatedRatio) of its pixels are colored")
        assertPanelConnectionIs(secure: true)
        XCTAssertTrue(connection.isBelow(element: foxImage), "Secure connection should be below the fox illustration")
    }

    /// Checks the connection details screen: header (back, website name, close), "Secure connection",
    /// "Verified by" and "View certificate", top to bottom.
    @MainActor
    func assertSecureConnectionDetailsStructure(domain: String) {
        let title = sel.DETAILS_TITLE_LABEL.element(in: app)
        let status = sel.DETAILS_CONNECTION_STATUS_LABEL.element(in: app)
        let verifiedBy = sel.DETAILS_VERIFIED_BY_LABEL.element(in: app)
        let certificates = sel.DETAILS_CERTIFICATES_BUTTON.element(in: app)
        assertDetailsHeader(domain: domain)
        BaseTestCase().waitForElementsToExist([status, verifiedBy, certificates])

        XCTAssertEqual(status.label,
                       String.Menu.EnhancedTrackingProtection.connectionSecureLabel,
                       "Expected the details screen to report a secure connection")
        assertConnectionVerifiedByCertificate()
        XCTAssertEqual(certificates.label,
                       String.Menu.EnhancedTrackingProtection.viewCertificatesButtonTitle,
                       "Unexpected View certificate link")
        for (upper, lower) in zip([title, status, verifiedBy], [status, verifiedBy, certificates]) {
            XCTAssertTrue(upper.isAbove(element: lower), "\(upper.identifier) should be above \(lower.identifier)")
        }
    }

    @MainActor
    func tapViewCertificate() {
        sel.DETAILS_CERTIFICATES_BUTTON.element(in: app).waitAndTap()
    }

    /// Checks the certificate screen: header (back, website name, close), the "Certificate" title and the first
    /// certificate section. Later sections can be off screen in the half-height sheet, so they are not checked.
    @MainActor
    func assertCertificateScreen(domain: String) {
        let title = sel.DETAILS_TITLE_LABEL.element(in: app)
        let certificateTitle = sel.CERTIFICATES_TITLE_LABEL.element(in: app)
        let subjectName = sel.certificateSection(named: .Menu.EnhancedTrackingProtection.certificateSubjectName)
            .element(in: app)
        assertDetailsHeader(domain: domain)
        BaseTestCase().waitForElementsToExist([certificateTitle, sel.CERTIFICATES_TABLE.element(in: app), subjectName])

        XCTAssertEqual(certificateTitle.label,
                       String.Menu.EnhancedTrackingProtection.certificatesTitle,
                       "Unexpected certificate screen title")
        XCTAssertTrue(title.isAbove(element: certificateTitle), "The header should be above the Certificate title")
        XCTAssertTrue(certificateTitle.isAbove(element: subjectName), "The Certificate title should be above the details")
    }

    /// The details and certificate screens share one header: back, website name and close, left to right.
    @MainActor
    private func assertDetailsHeader(domain: String) {
        let back = sel.DETAILS_BACK_BUTTON.element(in: app)
        let title = sel.DETAILS_TITLE_LABEL.element(in: app)
        let close = sel.DETAILS_CLOSE_BUTTON.element(in: app)
        BaseTestCase().waitForElementsToExist([back, title, close])
        XCTAssertEqual(title.label, domain, "Expected the header to show the website domain")
        XCTAssertTrue(back.isLeftOf(rightElement: title), "The back button should be left of the website name")
        XCTAssertTrue(title.isLeftOf(rightElement: close), "The website name should be left of the close button")
    }

    /// Back from the certificate screen lands on the connection details screen.
    @MainActor
    func assertConnectionDetailsDisplayed() {
        BaseTestCase().mozWaitForElementToExist(sel.DETAILS_CERTIFICATES_BUTTON.element(in: app))
        BaseTestCase().mozWaitForElementToNotExist(sel.CERTIFICATES_TITLE_LABEL.element(in: app))
    }

    @MainActor
    func tapConnectionDetailsBack() {
        sel.DETAILS_BACK_BUTTON.element(in: app).waitAndTap()
    }

    /// The panel is back on its main screen and the connection details screen is gone.
    @MainActor
    func assertPanelMainScreenDisplayed() {
        BaseTestCase().waitForElementsToExist(
            [sel.PANEL_TITLE_LABEL.element(in: app), sel.SECURITY_STATUS_BUTTON.element(in: app)]
        )
        BaseTestCase().mozWaitForElementToNotExist(sel.DETAILS_BACK_BUTTON.element(in: app))
    }

    @MainActor
    func assertPanelDismissed() {
        BaseTestCase().mozWaitForElementToNotExist(sel.DETAILS_CLOSE_BUTTON.element(in: app))
        BaseTestCase().mozWaitForElementToNotExist(sel.PANEL_CLOSE_BUTTON.element(in: app))
    }

    @MainActor
    func tapPanelTrackingProtectionSwitch() {
        sel.PANEL_TRACKING_PROTECTION_SWITCH.element(in: app).waitAndTap()
    }

    @MainActor
    func turnOnPanelTrackingProtectionIfNeeded() {
        let toggle = sel.PANEL_TRACKING_PROTECTION_SWITCH.element(in: app)
        BaseTestCase().mozWaitForElementToExist(toggle)
        if toggle.value as? String == "0" {
            toggle.waitAndTap()
        }
        assertPanelTrackingProtectionSwitchValue(isOn: true)
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

    @MainActor
    func assertClearCookiesButtonIsBelowSwitch() {
        let toggle = sel.PANEL_TRACKING_PROTECTION_SWITCH.element(in: app)
        let clearCookies = sel.PANEL_CLEAR_COOKIES_BUTTON.element(in: app)
        BaseTestCase().waitForElementsToExist([toggle, clearCookies])
        XCTAssertEqual(clearCookies.label,
                       String.Menu.EnhancedTrackingProtection.clearDataButtonTitle,
                       "Unexpected Clear cookies button")
        XCTAssertTrue(clearCookies.isBelow(element: toggle), "Clear cookies should be below the ETP switch")
    }

    @MainActor
    func tapClearCookiesAndSiteData() {
        sel.PANEL_CLEAR_COOKIES_BUTTON.element(in: app).waitAndTap()
    }

    /// Checks the confirmation alert: title, the warning naming `domain`, and the Clear and Cancel buttons.
    @MainActor
    func assertClearCookiesAlert(domain: String) {
        let alert = sel.CLEAR_COOKIES_ALERT.element(in: app)
        BaseTestCase().mozWaitForElementToExist(alert)
        let message = String(format: .Menu.EnhancedTrackingProtection.clearDataAlertText, domain)
        BaseTestCase().waitForElementsToExist(
            [
                alert.staticTexts[String.Menu.EnhancedTrackingProtection.clearDataAlertTitle],
                alert.staticTexts[message],
                alert.buttons[String.Menu.EnhancedTrackingProtection.clearDataAlertButton],
                alert.buttons[String.Menu.EnhancedTrackingProtection.clearDataAlertCancelButton]
            ]
        )
    }

    @MainActor
    func confirmClearCookies() {
        let alert = sel.CLEAR_COOKIES_ALERT.element(in: app)
        alert.buttons[String.Menu.EnhancedTrackingProtection.clearDataAlertButton].waitAndTap()
        BaseTestCase().mozWaitForElementToNotExist(alert)
    }

    @MainActor
    func cancelClearCookies() {
        let alert = sel.CLEAR_COOKIES_ALERT.element(in: app)
        alert.buttons[String.Menu.EnhancedTrackingProtection.clearDataAlertCancelButton].waitAndTap()
        BaseTestCase().mozWaitForElementToNotExist(alert)
    }

    @MainActor
    func assertClearCookiesToastDisplayed() {
        BaseTestCase().mozWaitForElementToExist(sel.CLEAR_COOKIES_TOAST.element(in: app))
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
