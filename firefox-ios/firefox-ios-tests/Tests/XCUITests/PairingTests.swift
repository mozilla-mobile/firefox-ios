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

    /// Drive the v2 supplicant flow. The FxA functional test opens the pairing URL with
    /// `simctl openurl` once the app is up; the deep link routes into the dedicated FxA
    /// pairing web view, so this waits for the card that renders there.
    ///
    /// v2 inverts v1: the page asks the browser for OAuth parameters over the WebChannel, so
    /// there is no native pairing screen to tap through, only the web card.
    func testPairingV2() {
        guard let connect = waitForElement(labelled: "Connect", timeout: 120) else {
            attachScreenshot(named: "v2-no-connect-card")
            XCTFail("No v2 Connect card. App still running: \(app.exists)")
            return
        }
        // A "Connect" button also renders if the pairing URL merely opened as an ordinary tab, so
        // check the modal is up before treating its dismissal as the success signal.
        guard assertPairingModalIsOpen() else { return }
        XCTAssertFalse(
            app.webViews.staticTexts["Invalid pairing configuration"].exists,
            "Supplicant page reported invalid pairing configuration"
        )
        connect.tap()

        // FXIOS-16685: a successful pairing signs the user in, starts Sync and CLOSES the
        // pairing modal, so success is the modal going away, not a card rendering in it.
        // The functional test asserts the account side (device registered, Connected Services).
        guard waitForModalToClose(timeout: 120) else {
            attachScreenshot(named: "v2-modal-did-not-close")
            XCTFail("Pairing modal stayed open after Connect")
            return
        }
        attachScreenshot(named: "v2-pairing-modal-closed")
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
        // A dead app makes `app.screenshot()` throw, which turns an ordinary test failure into
        // a runner crash and loses the diagnosis. Fall back to the whole screen.
        let screenshot = app.exists ? app.screenshot() : XCUIScreen.main.screenshot()
        let shot = XCTAttachment(screenshot: screenshot)
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

    /// Accept the "Open in ..." springboard confirmation if one is showing.
    ///
    /// `simctl openurl` only raises this prompt when the app is not frontmost. Under XCUITest
    /// it usually is, and the URL arrives with no prompt at all, so this must never block.
    @discardableResult
    private func acceptOpenInAppPromptIfPresent() -> Bool {
        let open = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Open"]
        guard open.exists else { return false }
        open.tap()
        return true
    }

    /// The pairing modal dismisses itself once `oauth_login` completes, so its disappearance
    /// is the supplicant-side success signal.
    ///
    /// Waits on the modal's own Close button, not on page content: the supplicant card re-renders
    /// after Connect, so the Connect button going away would report success before pairing runs,
    /// and would report success for a failure card too.
    /// Uses `waitForExistence` rather than a tight poll for the same reason `waitForElement` does:
    /// repeatedly walking the accessibility tree floods os_log and gets the app quarantined.
    /// A dead app is a failure, not a success, so liveness is checked before reporting closure.
    ///
    /// The caller must have already established that the modal is open, otherwise a URL that never
    /// reached the pairing route would report success: no modal and a dismissed modal both leave no
    /// Close button. `assertPairingModalIsOpen` is what establishes that.
    private func waitForModalToClose(timeout: TimeInterval) -> Bool {
        let close = app.navigationBars.buttons["Close"].firstMatch
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let remaining = deadline.timeIntervalSinceNow
            guard remaining > 0 else { break }
            // Each call yields to the runner instead of spinning the accessibility tree.
            if !close.waitForExistence(timeout: min(2, remaining)) {
                return app.state == .runningForeground
            }
        }
        return !close.exists && app.state == .runningForeground
    }

    /// Confirm the pairing modal is actually presented, so the disappearance of its Close button
    /// later means "pairing completed" rather than "the URL never opened the modal at all".
    @discardableResult
    private func assertPairingModalIsOpen() -> Bool {
        let close = app.navigationBars.buttons["Close"].firstMatch
        guard close.waitForExistence(timeout: TIMEOUT_LONG) else {
            attachScreenshot(named: "v2-modal-never-opened")
            XCTFail("The pairing modal never opened, so the pairing route was not taken")
            return false
        }
        return true
    }

    /// Wait for a web card control by label, across the element types WebKit may surface it as.
    ///
    /// Uses `waitForExistence` rather than a tight poll: repeatedly walking the accessibility
    /// tree floods os_log, and the app gets quarantined for logging volume, which segfaults
    /// XCTAutomationSupport before the test can report anything useful.
    ///
    /// Also clears the springboard "Open in ..." prompt each round, since whether it appears
    /// depends on which app is frontmost when the URL is delivered.
    private func waitForElement(labelled label: String, timeout: TimeInterval) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)
        let queries = [
            app.webViews.buttons[label],
            app.buttons[label],
            app.webViews.staticTexts[label]
        ]
        var promptCleared = false
        while Date() < deadline {
            if !promptCleared {
                promptCleared = acceptOpenInAppPromptIfPresent()
            }
            for element in queries {
                // Derive each wait from the time left, so three back-to-back 2s waits cannot
                // overshoot the caller's budget.
                let remaining = deadline.timeIntervalSinceNow
                guard remaining > 0 else { return nil }
                if element.firstMatch.waitForExistence(timeout: min(2, remaining)) {
                    return element.firstMatch
                }
            }
        }
        return nil
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
}
