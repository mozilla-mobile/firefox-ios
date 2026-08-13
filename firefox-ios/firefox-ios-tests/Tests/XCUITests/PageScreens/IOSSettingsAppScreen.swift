// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

// ⚠️ Drives the iOS Settings app (com.apple.Preferences): expect system-app idle delays, English-only
// labels, and device-wide default-browser state that persists beyond the test (callers reset it).
@MainActor
final class IOSSettingsAppScreen {
    private let firefoxApp: XCUIApplication
    private let settingsApp: XCUIApplication

    init(firefoxApp: XCUIApplication,
         settingsApp: XCUIApplication = XCUIApplication(bundleIdentifier: "com.apple.Preferences")) {
        self.firefoxApp = firefoxApp
        self.settingsApp = settingsApp
    }

    // MARK: - Elements

    /// The Firefox option in the default-browser picker. Options are buttons whose label is the app's
    /// display name; match either scheme (Fennec "Fennec (user)" or the Firefox release "Firefox").
    private var firefoxBrowserOption: XCUIElement {
        settingsApp.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@ OR label CONTAINS[c] %@", "Fennec", "Firefox")
        ).firstMatch
    }

    // MARK: - Assertions

    /// Waits for the iOS Settings app to reach the foreground after tapping Go to Settings.
    func assertSettingsAppOpened() {
        XCTAssertTrue(
            settingsApp.wait(for: .runningForeground, timeout: TIMEOUT_LONG),
            "iOS Settings app did not reach the foreground after tapping Go to Settings"
        )
    }

    // MARK: - Actions

    /// Selects Firefox in the "Default Browser App" picker, then re-opens the picker from the root to
    /// confirm the choice was saved (still checked) — not merely registered on the initial tap.
    func setFirefoxAsDefaultBrowser() {
        openDefaultBrowserPicker()
        let option = firefoxBrowserOption
        BaseTestCase().mozWaitForElementToExist(option, timeout: TIMEOUT_LONG)
        option.waitAndTap()
        XCTAssertTrue(option.isSelected, "The Firefox option should be selected after tapping it")

        openDefaultBrowserPicker()
        let persisted = firefoxBrowserOption
        BaseTestCase().mozWaitForElementToExist(persisted, timeout: TIMEOUT_LONG)
        XCTAssertTrue(persisted.isSelected, "Firefox should still be the default browser after reopening the picker")
    }

    /// The Settings deep link lands on the root page on Simulator, and iOS 26 nests the default-browser
    /// choice under Settings > Apps > Default Apps, so navigate there explicitly.
    private func openDefaultBrowserPicker() {
        // Settings resumes where a prior run left it, so pop any pushed screen back to root first (on iPad
        // this pops the detail pane's own nav stack, since its back button survives sidebar re-selection).
        popToSettingsRoot()

        // Split-view Settings (iPad) shows "Apps" in a sidebar collection view, ambiguous with the same-named
        // detail-pane title; single-column Settings (iPhone) shows a plain row. Prefer the sidebar when present.
        let sidebarApps = settingsApp.collectionViews.staticTexts["Apps"]
        tapSettingsRow(sidebarApps.exists ? sidebarApps : settingsApp.staticTexts["Apps"])

        tapSettingsRow(settingsApp.staticTexts["Default Apps"])

        // The browser entry is labelled "Browser App" / "Default Browser App" across iOS versions; match
        // on the shared "Browser" fragment. Tapping it presents the browser picker.
        let browserSetting = settingsApp.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Browser")
        ).firstMatch
        tapSettingsRow(browserSetting)
    }

    /// Taps the navigation back button until the root of Settings is reached (no back button left).
    private func popToSettingsRoot() {
        let backButton = settingsApp.navigationBars.buttons["BackButton"]
        var attempts = 0
        while backButton.exists && attempts < 8 {
            backButton.tap()
            attempts += 1
        }
    }

    /// Taps a Settings row, first waiting for it to render (so a fast scroll can't race a transition and
    /// overshoot a top row), then searching up (recovers overshoot) and finally down for below-fold rows.
    private func tapSettingsRow(_ element: XCUIElement) {
        _ = element.mozWaitForElementToExist(timeout: TIMEOUT, failOnTimeout: false)

        var swipes = 0
        while !element.isHittable && swipes < 6 {
            settingsApp.partialSwipeDown()
            swipes += 1
        }
        swipes = 0
        while !element.isHittable && swipes < 8 {
            settingsApp.partialSwipeUp()
            swipes += 1
        }

        element.waitAndTap()
    }

    /// Brings Firefox back to the foreground after leaving for the Settings app.
    func returnToFirefox() {
        firefoxApp.activate()
        XCTAssertTrue(
            firefoxApp.wait(for: .runningForeground, timeout: TIMEOUT_LONG),
            "Firefox did not return to the foreground after setting the default browser"
        )
    }
}
