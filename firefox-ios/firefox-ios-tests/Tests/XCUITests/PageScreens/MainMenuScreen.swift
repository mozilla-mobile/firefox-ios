// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class MainMenuScreen {
    private let app: XCUIApplication
    private let sel: MainMenuSelectorSet

    init(app: XCUIApplication, selectors: MainMenuSelectorSet = MainMenuSelectors()) {
        self.app = app
        self.sel = selectors
    }

    func assertDesktopSiteExists(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(sel.DESKTOP_SITE.element(in: app), timeout: timeout)
    }

    func waitForMenuOptionsToExist() {
        let elements = [
            sel.BOOKMARKS_BUTTON.element(in: app),
            sel.HISTORY_BUTTON.element(in: app),
            sel.DOWNLOADS_BUTTON.element(in: app),
            sel.PASSWORDS_BUTTON.element(in: app),
            sel.SETTINGS_CELL.element(in: app)
        ]
        BaseTestCase().waitForElementsToExist(elements)
    }

    func assertMainMenuSettingsExist() {
        let settings = sel.SETTINGS_CELL.element(in: app)
        BaseTestCase().mozWaitForElementToExist(settings)
    }
}
