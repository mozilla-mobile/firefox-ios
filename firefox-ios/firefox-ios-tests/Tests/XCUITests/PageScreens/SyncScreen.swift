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
}
