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

    private var firefoxIconQuery: XCUIElementQuery {
        sel.FIREFOX_ICON.query(in: springboard)
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

    private var appIconButton: XCUIElement {
        sel.APP_ICON_BUTTON.element(in: springboard)
    }

    private var firefoxWidget: XCUIElement {
        sel.FIREFOX_WIDGET.element(in: springboard)
    }

    private var screenTimeIcon: XCUIElement {
        sel.SCREEN_TIME_ICON.element(in: springboard)
    }

    private var searchWidgetsField: XCUIElement {
        sel.SEARCH_WIDGETS_FIELD.element(in: springboard)
    }

    private var notificationsPermissionAlert: XCUIElement {
        sel.NOTIFICATIONS_PERMISSION_ALERT.element(in: springboard)
    }

    private var allowNotificationsButton: XCUIElement {
        sel.ALLOW_NOTIFICATIONS_BUTTON.element(in: springboard)
    }

    private var dontAllowNotificationsButton: XCUIElement {
        sel.DONT_ALLOW_NOTIFICATIONS_BUTTON.element(in: springboard)
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

    func longPressFirefoxIcon(at index: Int = 0, duration: TimeInterval = 1.0) {
        let icon = index == 0 ? firefoxIconQuery.firstMatch : firefoxIconQuery.element(boundBy: index)
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

    func tapAppIconButton() {
        appIconButton.waitAndTap()
    }

    // MARK: - Widget Actions

    /// Swipes to the page that holds the widgets, left of the first home screen page.
    func goToWidgetPage() {
        if #available(iOS 26, *) {
            springboard.swipeRight()
            springboard.swipeRight()
        } else {
            while !screenTimeIcon.exists {
                springboard.swipeRight()
            }
        }
    }

    func isFirefoxWidgetPresent(maxSwipes: Int = 3) -> Bool {
        var numberOfSwipes = 0
        while !firefoxWidget.exists && numberOfSwipes < maxSwipes {
            springboard.swipeUp()
            numberOfSwipes += 1
        }
        return firefoxWidget.exists
    }

    /// Adds the Firefox Quick Actions widget, the first one the gallery offers for the app.
    func addFirefoxQuickActionsWidget(named widgetName: String) {
        if BaseTestCase().iPad() {
            springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).press(forDuration: 3)
        } else {
            screenTimeIcon.press(forDuration: 3)
            sel.EDIT_HOME_SCREEN_BUTTON.element(in: springboard).tapIfExists()
            sel.EDIT_BUTTON.element(in: springboard).tapIfExists()
        }
        sel.ADD_WIDGET_BUTTON.element(in: springboard).waitAndTap()
        searchWidgetsField.mozWaitElementHittable(timeout: TIMEOUT)
        searchWidgetsField.waitAndTap()
        searchWidgetsField.typeText(widgetName)
        springboard.cells
            .matching(NSPredicate(format: "label CONTAINS[c] %@", widgetName + " ("))
            .element
            .waitAndTap()
        BaseTestCase().mozWaitForElementToExist(sel.QUICK_ACTIONS_LABEL.element(in: springboard))
        sel.CONFIRM_ADD_WIDGET_BUTTON.element(in: springboard).waitAndTap()
        springboard.swipeDown()
        sel.DONE_BUTTON.element(in: springboard).waitAndTap()
    }

    func tapFirefoxWidget() {
        guard isFirefoxWidgetPresent() else {
            let labels = springboard.buttons.allElementsBoundByIndex.map { $0.label }
            XCTFail("Firefox widget not found on the home screen. Springboard buttons: \(labels)")
            return
        }
        firefoxWidget.mozWaitElementHittable(timeout: TIMEOUT)
        firefoxWidget.waitAndTap()
    }

    // MARK: - Notifications Permission Actions

    func tapAllowNotifications() {
        allowNotificationsButton.waitAndTap()
    }

    func tapDontAllowNotifications() {
        dontAllowNotificationsButton.waitAndTap()
    }

    // MARK: - Assertions

    func assertNotificationsPermissionAlertExists(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(notificationsPermissionAlert, timeout: timeout)
    }

    func assertFennecIconExists(at index: Int = 0, timeout: TimeInterval = TIMEOUT) {
        let icon = fennecIconsQuery.element(boundBy: index)
        BaseTestCase().mozWaitForElementToExist(icon, timeout: timeout)
    }

    func assertFirefoxIconExists(at index: Int = 0, timeout: TimeInterval = TIMEOUT) {
        let icon = firefoxIconQuery.element(boundBy: index)
        BaseTestCase().mozWaitForElementToExist(icon, timeout: timeout)
    }

    func assertNewTabButtonExists(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(newTabButton, timeout: timeout)
    }

    func assertOpenLastBookmarkButtonExists(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(openLastBookmarkButton, timeout: timeout)
    }

    func assertAppIconButtonExists(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(appIconButton, timeout: timeout)
    }

    func assertAllContextMenuOptionsExist(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(appIconButton, timeout: timeout)
        BaseTestCase().mozWaitForElementToExist(newTabButton, timeout: timeout)
        BaseTestCase().mozWaitForElementToExist(newPrivateButton, timeout: timeout)
        BaseTestCase().mozWaitForElementToExist(openLastBookmarkButton, timeout: timeout)
    }

    func fennecIconsCount() -> Int {
        return fennecIconsQuery.count
    }
}
