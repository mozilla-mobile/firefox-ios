// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class SettingsHomepageScreen {
    private let app: XCUIApplication
    private let sel: SettingsHomepageSelectorsSet

    init(app: XCUIApplication, selectors: SettingsHomepageSelectorsSet = SettingsHomepageSelectors()) {
        self.app = app
        self.sel = selectors
    }

    func assertDefaultOptionsVisible() {
        BaseTestCase().waitForElementsToExist([
            sel.NAVBAR.element(in: app),
            sel.START_AT_HOME_ALWAYS.element(in: app),
            sel.START_AT_HOME_DISABLED.element(in: app)
        ])
        BaseTestCase().mozWaitForElementToExist(sel.START_AT_HOME_AFTER_4H.element(in: app))
    }

    func assertStoriesSwitch(isOn expected: Bool) {
        let sw = sel.STORIES_SWITCH.element(in: app)
        BaseTestCase().mozWaitForElementToExist(sw)
        let value = (sw.value as? String) ?? ""
        XCTAssertEqual(value, expected ? "1" : "0", "Stories switch expected to be \(expected ? "ON" : "OFF")")
    }
}
