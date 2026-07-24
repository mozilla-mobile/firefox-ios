// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
import Shared

/// Drives the Firefox iOS "supplicant" side of the FxA device-pairing flow,
/// coordinated by the `pairingFlowiOS.spec.ts` functional test in the FxA repo
/// (which drives the desktop "authority"). Simulators have no camera, so instead
/// of a QR scan these use the debug "Launch pairing from URL" setting, driving
/// the same `.qrCode(url:)` path a real scan would. The functional test injects
/// PAIRING_URL and CUSTOM_FXA_SERVER into the xctestrun environment.
class PairingTests: BaseTestCase {
    override func setUp() async throws {
        // Only runs when the FxA functional test injects a live stack; otherwise
        // skip, since the shared test plans run the whole XCUITests target.
        let env = ProcessInfo.processInfo.environment
        guard let pairingURL = env["PAIRING_URL"], !pairingURL.isEmpty,
              let customFxA = env["CUSTOM_FXA_SERVER"], !customFxA.isEmpty else {
            throw XCTSkip("PairingTests requires PAIRING_URL and CUSTOM_FXA_SERVER (FxA stack)")
        }

        // Forward the pairing inputs to the app process. The debug setting
        // pre-fills its URL field from PAIRING_URL.
        app.launchEnvironment["PAIRING_URL"] = pairingURL
        app.launchEnvironment["CUSTOM_FXA_SERVER"] = customFxA

        launchArguments = [
            LaunchArguments.ClearProfile,
            LaunchArguments.SkipIntro,
            LaunchArguments.SkipWhatsNew,
            LaunchArguments.SkipETPCoverSheet,
            LaunchArguments.SkipDefaultBrowserOnboarding,
            LaunchArguments.SkipTermsOfUse,
            LaunchArguments.SkipContextualHints,
            LaunchArguments.DisableAnimations
        ]
        try await super.setUp()
    }

    /// Open the pairing web flow from the injected PAIRING_URL and drive it to a
    /// completed pairing (the authority approves mid-flow).
    func testPairingWithUrl() {
        launchPairingFromDebugSetting()

        // The supplicant shows "Confirm pairing" once connected to the channel;
        // poll to span the authority's approval window, then tap it.
        guard let confirm = waitForConfirmPairing(timeout: 90) else {
            logSupplicantState()
            XCTFail("Supplicant did not present a 'Confirm pairing' control")
            return
        }
        XCTAssertFalse(
            app.webViews.staticTexts["Invalid pairing configuration"].exists,
            "Supplicant page reported invalid pairing configuration"
        )
        confirm.tap()

        // Let the supplicant complete OAuth; the authority asserts completion.
        sleep(15)
    }

    /// Open the pairing web flow, then cancel before the authority approves;
    /// the device must not get signed in.
    func testPairingCancelledByUser() {
        launchPairingFromDebugSetting()
        // Wait until the pairing web view is up, then close it without confirming.
        _ = waitForConfirmPairing(timeout: TIMEOUT_LONG)
        let close = app.buttons["Close"].firstMatch
        if close.waitForExistence(timeout: TIMEOUT) {
            close.tap()
        } else {
            // Fall back to dismissing via the navigation bar back control.
            app.navigationBars.buttons.firstMatch.tap()
        }
    }

    /// Capture screenshots of the "Launch pairing from URL" debug option: the
    /// Debug settings row, and the URL-entry alert it opens.
    func testCaptureDebugPairingOption() {
        let launchPairing = revealDebugPairingCell()
        mozWaitForElementToExist(launchPairing, timeout: TIMEOUT)
        attachScreenshot(named: "debug-pairing-row")

        launchPairing.tap()
        mozWaitForElementToExist(app.alerts.buttons["Launch"], timeout: TIMEOUT)
        attachScreenshot(named: "debug-pairing-alert")
    }

    private func attachScreenshot(named name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    // MARK: - Helpers

    /// Reveal the hidden Debug settings section and tap "Launch pairing from URL".
    private func launchPairingFromDebugSetting() {
        revealDebugPairingCell().waitAndTap()

        // The debug setting shows an alert with the URL pre-filled; launch it.
        let launchButton = app.alerts.buttons["Launch"]
        mozWaitForElementToExist(launchButton, timeout: TIMEOUT)
        launchButton.tap()
    }

    /// Navigate to Settings, reveal the hidden Debug section (tap the version
    /// cell 5 times), and scroll the "Launch pairing from URL" cell into view.
    private func revealDebugPairingCell() -> XCUIElement {
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)

        let versionCell = app.cells[AccessibilityIdentifiers.Settings.Version.title]
        mozWaitForElementToExist(versionCell, timeout: TIMEOUT_LONG)
        for _ in 0..<5 {
            versionCell.tap()
        }

        let launchPairing = app.cells["LaunchPairingFromURL.Setting"]
        scrollToElement(launchPairing)
        return launchPairing
    }

    /// Poll for the supplicant's "Confirm pairing" control across the element
    /// types it may surface as (web button, plain button, or static text's
    /// containing button). Returns the tappable element, or nil on timeout.
    private func waitForConfirmPairing(timeout: TimeInterval) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)
        let queries = [
            app.webViews.buttons["Confirm pairing"],
            app.buttons["Confirm pairing"],
            app.webViews.staticTexts["Confirm pairing"]
        ]
        while Date() < deadline {
            for element in queries where element.firstMatch.exists {
                return element.firstMatch
            }
            usleep(500_000)
        }
        return nil
    }

    /// Dump the current element hierarchy + a screenshot to help diagnose a
    /// missing supplicant control.
    private func logSupplicantState() {
        NSLog("[PairingTests] supplicant hierarchy:\n\(app.debugDescription)")
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.lifetime = .keepAlways
        add(shot)
    }
}
