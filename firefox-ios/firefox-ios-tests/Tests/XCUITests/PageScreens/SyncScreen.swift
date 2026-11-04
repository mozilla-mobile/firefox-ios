// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class SyncScreen {
    private let app: XCUIApplication
    private let sel: SyncSelectorsSet

    init(app: XCUIApplication, selectors: SyncSelectorsSet = SyncSelectors()) {
        self.app = app
        self.sel = selectors
    }

    // The Synced Tabs panel's signed-out state: a title and a button to sign in.
    func assertSignInPromptExists(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(sel.FIREFOX_SYNC_TITLE.element(in: app), timeout: timeout)
        BaseTestCase().mozWaitForElementToExist(sel.SYNC_AND_SAVE_DATA_BUTTON.element(in: app), timeout: timeout)
    }

    /// Taps the "Sync and Save Data" button on the Synced Tabs panel's signed-out state, opening the
    /// same "Sync and Save Data" sign-in screen reachable from Settings.
    func tapSyncAndSaveData() {
        sel.SYNC_AND_SAVE_DATA_BUTTON.element(in: app).waitAndTap()
    }

    func openSyncAndSaveDataFromSettings() {
        sel.SETTINGS_SYNC_AND_SAVE_DATA_ROW.element(in: app).waitAndTap()
        BaseTestCase().mozWaitForElementToExist(
            sel.SYNC_AND_SAVE_DATA_NAVIGATION_BAR.element(in: app),
            timeout: TIMEOUT_LONG
        )
    }

    /// Taps "Use email instead" and waits for the Firefox Account web view email field.
    func tapUseEmailInstead() {
        sel.EMAIL_SIGN_IN_BUTTON.element(in: app).waitAndTap()
        BaseTestCase().mozWaitForElementToExist(sel.FXA_EMAIL_FIELD.element(in: app), timeout: TIMEOUT_LONG)
    }

    func assertEmailFieldPlaceholder(_ expected: String = "Enter your email") {
        if #available(iOS 17, *) {
            XCTAssertEqual(sel.FXA_EMAIL_FIELD.element(in: app).label,
                           expected,
                           "The mail placeholder does not show the correct value")
        } else {
            let placeholder = sel.EMAIL_PLACEHOLDER_TEXT.element(in: app)
            BaseTestCase().mozWaitForElementToExist(placeholder)
            if #available(iOS 16, *) {
                XCTAssertEqual(placeholder.value as? String,
                               expected,
                               "The mail placeholder does not show the correct value")
            }
        }
    }

    /// Taps "Close" in the Firefox Account web view, which dismisses the whole presented sheet.
    func closeFxAWebView() {
        sel.FXA_WEBVIEW_CLOSE_BUTTON.element(in: app).waitAndTap()
    }

    func assertFxASheetDismissed(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToNotExist(sel.FXA_WEBVIEW_NAVIGATION_BAR.element(in: app), timeout: timeout)
        BaseTestCase().mozWaitForElementToNotExist(
            sel.SYNC_AND_SAVE_DATA_NAVIGATION_BAR.element(in: app),
            timeout: timeout
        )
    }
}
