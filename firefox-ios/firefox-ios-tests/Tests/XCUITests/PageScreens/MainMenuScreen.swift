// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

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
}
