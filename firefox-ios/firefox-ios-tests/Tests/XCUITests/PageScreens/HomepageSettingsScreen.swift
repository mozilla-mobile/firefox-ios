// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class HomepageSettingsScreen {
    private let app: XCUIApplication
    private let sel: HomepageSettingsSelectorSet

    init(app: XCUIApplication, selectors: HomepageSettingsSelectorSet = HomepageSettingsSelectors()) {
        self.app = app
        self.sel = selectors
    }

    private var bookmarkToggle: XCUIElement { sel.BOOKMARK_TOGGLE.element(in: app) }

    // helper to centralize the duplicated lookup
    private var bookmarkSwitch: XCUIElement {
        let settingTable = sel.HOMEPAGE_SETTINGS_TABLE.element(in: app)
        let toggle = sel.BOOKMARK_TOGGLE.value
        return settingTable.cells.switches[toggle]
    }

    func assertBookmarkToggleExists(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(bookmarkSwitch)
    }

    func disableBookmarkToggle() {
        let switchElement = bookmarkSwitch
        if switchElement.value as? String == "1" {
            switchElement.waitAndTap()
        }
    }

    func enableBookmarkToggle() {
        let switchElement = bookmarkSwitch
        if switchElement.value as? String == "0" {
            switchElement.waitAndTap()
        }
    }

    func assertBookmarkToggleIsEnabled() {
        let switchElement = bookmarkSwitch
        XCTAssertEqual(switchElement.value as? String, "1", "Bookmark toggle is not enabled")
    }

    func assertBookmarkToggleIsDisabled() {
        let switchElement = bookmarkSwitch
        XCTAssertEqual(switchElement.value as? String, "0", "Bookmark toggle is not disabled")
    }
}
