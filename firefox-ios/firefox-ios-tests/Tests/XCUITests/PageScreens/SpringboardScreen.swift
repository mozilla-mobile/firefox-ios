// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

// ⚠️ IMPORTANT: Interacting with springboard causes XCUITest to wait ~60 seconds
// for idle state. This is a known XCUITest limitation when working with system apps.
// Tests using this screen will experience significant delays.
@MainActor
final class SpringboardScreen {
    private let springboard: XCUIApplication
    private let sel: SpringboardSelectorsSet

    init(springboard: XCUIApplication, selectors: SpringboardSelectorsSet = SpringboardSelectors()) {
        self.springboard = springboard
        self.sel = selectors
    }

    init(selectors: SpringboardSelectorsSet = SpringboardSelectors()) {
        self.springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        self.sel = selectors
    }

    // MARK: - Elements

    private var fennecIconsQuery: XCUIElementQuery {
        sel.FENNEC_ICONS.query(in: springboard)
    }

    private var newTabButton: XCUIElement {
        sel.NEW_TAB_BUTTON.element(in: springboard)
    }

    private var newPrivateButton: XCUIElement {
        sel.NEW_PRIVATE_TAB_BUTTON.element(in: springboard)
    }

    private var openLastBookmarkButton: XCUIElement {
        sel.OPEN_LAST_BOOKMARK_BUTTON.element(in: springboard)
    }

    // MARK: - System Actions

    func pressHomeButton() {
        XCUIDevice.shared.press(.home)
    }

    // MARK: - Icon Actions

    func tapFennecIcon(at index: Int = 0) {
        let icon = fennecIconsQuery.element(boundBy: index)
        icon.waitAndTap()
    }

    func longPressFennecIcon(at index: Int = 0, duration: TimeInterval = 1.0) {
        let icon = index == 0 ? fennecIconsQuery.firstMatch : fennecIconsQuery.element(boundBy: index)
        BaseTestCase().mozWaitForElementToExist(icon)
        icon.press(forDuration: duration)
    }

    // MARK: - Context Menu Actions

    func tapNewTabButton() {
        newTabButton.firstMatch.waitAndTap()
    }

    func tapNewPrivateButton() {
        newPrivateButton.waitAndTap()
    }

    func tapOpenLastBookmarkButton() {
        openLastBookmarkButton.waitAndTap()
    }

    // MARK: - Assertions

    func assertFennecIconExists(at index: Int = 0, timeout: TimeInterval = TIMEOUT) {
        let icon = fennecIconsQuery.element(boundBy: index)
        BaseTestCase().mozWaitForElementToExist(icon, timeout: timeout)
    }

    func assertNewTabButtonExists(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(newTabButton, timeout: timeout)
    }

    func assertOpenLastBookmarkButtonExists(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(openLastBookmarkButton, timeout: timeout)
    }

    func assertAllContextMenuOptionsExist(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(newTabButton, timeout: timeout)
        BaseTestCase().mozWaitForElementToExist(newPrivateButton, timeout: timeout)
        BaseTestCase().mozWaitForElementToExist(openLastBookmarkButton, timeout: timeout)
    }

    func fennecIconsCount() -> Int {
        return fennecIconsQuery.count
    }
}
