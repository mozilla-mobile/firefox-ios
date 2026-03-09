// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class NewTabsScreen {
    private let app: XCUIApplication
    private let sel: NewTabSelectorSet

    private var iconPlus: XCUIElement { sel.ICON_PLUS.element(in: app) }
    private var iconCross: XCUIElement { sel.ICON_CROSS.element(in: app) }

    init(app: XCUIApplication, selectors: NewTabSelectorSet = NewTabSelectors()) {
        self.app = app
        self.sel = selectors
    }

    func assertLargeAndCrossIconsExist(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(iconPlus, timeout: timeout)
        BaseTestCase().mozWaitForElementToExist(iconCross, timeout: timeout)
    }

    func tapOnPlusIconScreen() {
        iconPlus.waitAndTap()
    }

    func tapOnCrossIconScreen() {
        iconCross.waitAndTap()
    }

    func tapNewPrivateTab() {
        let newPrivateTabButton = sel.NEW_PRIVATE_TAB_BUTTON.element(in: app)
        newPrivateTabButton.waitAndTap()
    }

    func pressOpenNewTabButtonExist(duration: TimeInterval, timeout: TimeInterval = TIMEOUT) {
        let openNewTabButton = sel.OPEN_NEW_TAB_BUTTON.element(in: app)
        BaseTestCase().mozWaitForElementToExist(openNewTabButton, timeout: timeout)
        openNewTabButton.press(forDuration: duration)
    }

    func pressOpenNewPrivateTabButton(duration: TimeInterval, timeout: TimeInterval = TIMEOUT) {
        let openNewTabButton = sel.OPEN_NEW_TAB_BUTTON.element(in: app)
        BaseTestCase().mozWaitForElementToExist(openNewTabButton, timeout: timeout)
        sel.OPEN_NEW_PRIVATE_TAB_BUTTON.element(in: app).press(forDuration: duration)
    }

    func tapOnSwitchButton() {
        sel.SWITCH_BUTTON.element(in: app).waitAndTap()
    }

    func assertIconsExistInCells(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(
            sel.ICON_PLUS_IN_CELLS.element(in: app),
            timeout: timeout
        )
        BaseTestCase().mozWaitForElementToExist(
            sel.ICON_CROSS_IN_CELLS.element(in: app),
            timeout: timeout
        )
    }

    func tapPlusIconInCells() {
        sel.ICON_PLUS_IN_CELLS.element(in: app).waitAndTap()
    }

    func tapCrossIconInTableCells() {
        sel.ICON_CROSS_IN_TABLE_CELLS.element(in: app).waitAndTap()
    }

    func tapNewPrivateTabInTableCells() {
        sel.NEW_PRIVATE_TAB_IN_TABLE_CELLS.element(in: app).waitAndTap()
    }
}
