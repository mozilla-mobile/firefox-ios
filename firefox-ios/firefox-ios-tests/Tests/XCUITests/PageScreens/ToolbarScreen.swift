// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class ToolbarScreen {
    private let app: XCUIApplication
    private let sel: ToolbarSelectorsSet

    init(app: XCUIApplication, selectors: ToolbarSelectorsSet = ToolbarSelectors()) {
        self.app = app
        self.sel = selectors
    }

    private var tabsButton: XCUIElement { sel.TABS_BUTTON.element(in: app) }
    private var newTabButton: XCUIElement { sel.NEW_TAB_BUTTON.element(in: app)}
    private var backButton: XCUIElement { sel.BACK_BUTTON.element(in: app)}
    private var tabToolbarMenuButton: XCUIElement { sel.TABTOOLBAR_MENUBUTTON.element(in: app) }
    private var shareButton: XCUIElement { sel.SHARE_BUTTON.element(in: app) }

    func assertSettingsButtonExists(timeout: TimeInterval = TIMEOUT) {
        let settingsButton = sel.SETTINGS_MENU_BUTTON.element(in: app)
        BaseTestCase().mozWaitForElementToExist(settingsButton, timeout: timeout)
    }

    func assertTabsButtonExists(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(tabsButton)
    }

    func pressTabsButton(duration: TimeInterval) {
        tabsButton.press(forDuration: duration)
    }

    func assertTabsOpened(expectedCount: Int) {
        BaseTestCase().mozWaitForElementToExist(tabsButton)

        guard let tabsOpen = tabsButton.value as? String, tabsOpen == "\(expectedCount)" else {
            XCTFail("Tabs button counter is not showing the correct count. Expected: \(expectedCount)")
            return
        }
    }

    func tapOnTabsButton() {
        tabsButton.waitAndTap()
    }

    func assertNewTabButtonExists() {
        BaseTestCase().mozWaitForElementToExist(newTabButton)
    }

    func assertTabsButtonValue(expectedCount: String) {
        let tabsButtonValue = tabsButton.value as? String
        XCTAssertEqual(expectedCount, tabsButtonValue, "Expected \(expectedCount) open tabs after switching")
    }

    func pressBackButton(duration: TimeInterval) {
        BaseTestCase().mozWaitForElementToExist(backButton)
        backButton.press(forDuration: duration)
    }

    func pressForwardButton(duration: TimeInterval) {
        let forward = sel.FORWARD_BUTTON.element(in: app)
        BaseTestCase().mozWaitForElementToExist(forward)
        forward.press(forDuration: duration)
    }

    func waitUntilBackButtonHittable(timeout: TimeInterval = 2.0) {
        BaseTestCase().mozWaitElementHittable(element: backButton, timeout: timeout)
    }

    func assertBackButtonExists() {
        BaseTestCase().mozWaitForElementToExist(backButton)
    }

    func tapBackButton() {
        backButton.waitAndTap()
    }

    func assertBackButtonIsDisabled() {
        XCTAssertFalse(backButton.isEnabled, "Expected Back button to be disabled")
    }

    func assertTabToolbarMenuButtonExists(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(tabToolbarMenuButton, timeout: timeout)
    }

    func assertMultipleTabsOpen() {
        BaseTestCase().mozWaitForElementToExist(tabsButton)
        let value = tabsButton.value as? String
        XCTAssertNotEqual(
            value,
            "1",
            "Expected several tabs to be open, but found only one."
        )
    }

    func openBrowserMenu() {
        tabToolbarMenuButton.waitAndTap()
    }

    func assertTabToolbarMenuExists() {
        BaseTestCase().mozWaitForElementToExist(tabToolbarMenuButton)
    }

    func tapReloadButton() {
        sel.RELOAD_BUTTON.element(in: app).waitAndTap()
    }

    func getToolbarSettingsMenuButtonElement() -> XCUIElement {
        let settingMenuButton = sel.SETTINGS_MENU_BUTTON.element(in: app)
        BaseTestCase().mozWaitForElementToExist(settingMenuButton, timeout: TIMEOUT)
        return settingMenuButton
    }

    func tapShareButton() {
        shareButton.waitAndTap()
    }

    func tapOnNewTabButton() {
        newTabButton.waitAndTap()
    }
}
