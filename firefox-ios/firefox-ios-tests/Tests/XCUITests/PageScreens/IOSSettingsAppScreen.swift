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
    /// iOS 16/17 expose the picker options as table cells labelled with the app name, iOS 18+ as buttons.
    /// Cells are tried first: they also rule out the back button, labelled with the app name on iOS 16/17.
    private var firefoxBrowserOption: XCUIElement {
        let predicate = NSPredicate(
            format: "label CONTAINS[c] %@ OR label CONTAINS[c] %@",
            "Fennec",
            "Firefox"
        )
        let optionCell = settingsApp.cells.matching(predicate).firstMatch
        return optionCell.exists ? optionCell : settingsApp.buttons.matching(predicate).firstMatch
    }

    /// The default-browser row in the app's own Settings pane, matched on its accessibility identifier so
    /// the lookup survives localization and cannot hit the picker's identically named title.
    private var appPaneDefaultBrowserRow: XCUIElement {
        settingsApp.buttons["DEFAULT_BROWSER_APP"]
    }

    /// Back button in the Settings navigation bar. Only some iOS versions expose the "BackButton"
    /// identifier; elsewhere it is labelled with the previous screen's title, so fall back to position.
    /// Never in split view (iPad): there a leading button can be a sidebar control, and popping is not
    /// needed anyway since re-selecting a sidebar row resets the detail pane.
    private var settingsBackButton: XCUIElement {
        let identified = settingsApp.navigationBars.buttons["BackButton"]
        guard !identified.exists, settingsApp.navigationBars.count == 1 else { return identified }
        return settingsApp.navigationBars.buttons.firstMatch
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

    /// Selects Firefox in the "Default Browser App" picker, then leaves and re-opens the picker to confirm
    /// the choice was saved (still checked) — not merely registered on the initial tap.
    func setFirefoxAsDefaultBrowser() {
        openDefaultBrowserPicker()
        let option = firefoxBrowserOption
        BaseTestCase().mozWaitForElementToExist(option, timeout: TIMEOUT_LONG)
        option.waitAndTap()
        XCTAssertTrue(option.isSelected, "The Firefox option should be selected after tapping it")

        leaveDefaultBrowserPicker()
        openDefaultBrowserPicker()
        let persisted = firefoxBrowserOption
        BaseTestCase().mozWaitForElementToExist(persisted, timeout: TIMEOUT_LONG)
        XCTAssertTrue(persisted.isSelected, "Firefox should still be the default browser after reopening the picker")
    }

    /// Up to iOS 18.1 the choice lives in the app's own pane, which is where the Settings deep link lands.
    /// iOS 18.2+ nests it under Settings > Apps > Default Apps, reached from the root the deep link opens.
    private func openDefaultBrowserPicker() {
        if appPaneDefaultBrowserRow.mozWaitForElementToExist(
            timeout: TIMEOUT_PICKER_PROBE,
            failOnTimeout: false
        ) {
            tapSettingsRow(appPaneDefaultBrowserRow)
            // Settle on the picker before the option is looked up, so a mid-push snapshot cannot decide
            // between the cell and button shapes on the pane still being dismissed.
            _ = settingsApp.navigationBars["Default Browser App"].mozWaitForElementToExist(
                timeout: TIMEOUT,
                failOnTimeout: false
            )
            return
        }

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

    /// Leaves the open picker so that reopening it is a real round trip rather than a re-read of the
    /// screen the selection was made on.
    private func leaveDefaultBrowserPicker() {
        let backButton = settingsBackButton
        if backButton.exists {
            backButton.tap()
        }
    }

    /// Taps the navigation back button until the root of Settings is reached (no back button left).
    private func popToSettingsRoot() {
        var attempts = 0
        while settingsBackButton.exists && attempts < 8 {
            settingsBackButton.tap()
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
