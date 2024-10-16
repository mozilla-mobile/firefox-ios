// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

let website1: [String: String] = [
    "url": path(forTestPage: "test-mozilla-org.html"),
    "label": "Internet for people, not profit — Mozilla",
    "value": "localhost",
    "longValue": "localhost:\(serverPort)/test-fixture/test-mozilla-org.html"
]
let website2 = path(forTestPage: "test-example.html")

class ToolbarTests: BaseTestCase {
    override func setUp() {
        super.setUp()
        XCUIDevice.shared.orientation = UIDeviceOrientation.landscapeLeft
    }

    override func tearDown() {
        XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        super.tearDown()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2344428
    /**
     * Tests landscape page navigation enablement with the URL bar with tab switching.
     */
    func testLandscapeNavigationWithTabSwitch() {
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        let urlPlaceholder = "Search or enter address"
        XCTAssert(app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url].exists)
        let defaultValuePlaceholder = app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url].placeholderValue!

        // Check the url placeholder text and that the back and forward buttons are disabled
        XCTAssertTrue(urlPlaceholder == defaultValuePlaceholder, "The placeholder does not show the correct value")
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.Toolbar.backButton].isEnabled)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.Toolbar.forwardButton].isEnabled)

        // Navigate to two pages and press back once so that all buttons are enabled in landscape mode.
        navigator.openURL(website1["url"]!)
        waitUntilPageLoad()
        mozWaitForElementToExist(app.webViews.links["Mozilla"], timeout: 10)
        let valueMozilla = app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url].value as! String
        XCTAssertEqual(valueMozilla, urlValueLong)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.Toolbar.backButton].isEnabled)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.Toolbar.forwardButton].isEnabled)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.Toolbar.reloadButton].isEnabled)
        navigator.openURL(website2)
        waitUntilPageLoad()
        let url = app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url]
        mozWaitForValueContains(url, value: "localhost:\(serverPort)")
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.Toolbar.backButton].isEnabled)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.Toolbar.forwardButton].isEnabled)

        app.buttons[AccessibilityIdentifiers.Toolbar.backButton].tap()
        XCTAssertEqual(valueMozilla, urlValueLong)

        waitUntilPageLoad()
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.Toolbar.backButton].isEnabled)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.Toolbar.forwardButton].isEnabled)

        // Open new tab and then go back to previous tab to test navigation buttons.
        waitForTabsButton()
        navigator.goto(TabTray)
        mozWaitForElementToExist(app.cells.staticTexts[website1["label"]!])
        app.cells.element(boundBy: 0).tap()
        XCTAssertEqual(valueMozilla, urlValueLong)

        // Test to see if all the buttons are enabled.
        waitUntilPageLoad()
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.Toolbar.backButton].isEnabled)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.Toolbar.forwardButton].isEnabled)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2344430
    func testClearURLTextUsingBackspace() {
        navigator.openURL(website1["url"]!)
        waitUntilPageLoad()
        waitForTabsButton()
        mozWaitForElementToExist(app.webViews.links["Mozilla"], timeout: 10)
        let valueMozilla = app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url].value as! String
        XCTAssertEqual(valueMozilla, urlValueLong)

        // Simulate pressing on backspace key should remove the text
        app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url].tap()
        urlBarAddress.typeText("\u{8}")

        let value = urlBarAddress.value
        XCTAssertEqual(value as? String, "", "The url has not been removed correctly")
    }

    // Check that after scrolling on a page, the URL bar is hidden. Tapping one on the status bar will reveal
    // the URL bar, tapping again on the status will scroll to the top
    // Skipping for iPad for now, not sure how to implement it there
    // https://mozilla.testrail.io/index.php?/cases/view/2344431
    func testRevealToolbarWhenTappingOnStatusbar() {
        if !iPad() {
            // Workaround when testing on iPhone. If the orientation is in landscape on iPhone the tests will fail.

            XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
            mozWaitForElementToExist(app.otherElements["Navigation Toolbar"])

            navigator.openURL(website1["url"]!, waitForLoading: true)
            // Adding the waiter right after navigating to the webpage in order to make the test more stable
            waitUntilPageLoad()
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], timeout: 10)
            let PageOptionsMenu = app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton]
            let statusbarElement: XCUIElement = XCUIApplication(
                bundleIdentifier: "com.apple.springboard"
            ).statusBars.element(boundBy: 1)
            app.swipeUp()
            XCTAssertFalse(PageOptionsMenu.isHittable)
            statusbarElement.tap(force: true)
            XCTAssertTrue(PageOptionsMenu.isHittable)
            statusbarElement.tap(force: true)
            let topElement = app.webViews
                .otherElements["Internet for people, not profit — Mozilla"]
                .children(matching: .other)
                .matching(identifier: "navigation")
                .element(boundBy: 0)
                .staticTexts["Mozilla"]
            mozWaitForElementToExist(topElement, timeout: 10)
            XCTAssertTrue(topElement.isHittable)
        }
   }

    // https://mozilla.testrail.io/index.php?/cases/view/2306870
    func testOpenNewTabButtonOnToolbar() throws {
        if iPad() {
            throw XCTSkip("iPhone only test")
        } else {
            // Launch Firefox iOS
            // A magnifying glass icon is displayed. A "+" icon is displayed
            validateAddNewTabButtonOnToolbar(isPrivate: false)
            // Repeat steps on private mode
            // validateAddNewTabButtonOnToolbar() does not work on iOS 15
            if #available(iOS 16, *) {
                navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
                navigator.performAction(Action.OpenNewTabFromTabTray)
                app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].tap()
                validateAddNewTabButtonOnToolbar(isPrivate: true)
            }
        }
    }

    private func validateAddNewTabButtonOnToolbar(isPrivate: Bool) {
        if isPrivate {
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.fireButton])
        } else {
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.searchButton])
        }
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton])
        restartInBackground()
        if isPrivate {
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.fireButton])
        } else {
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.searchButton])
        }
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton])
        // Swipe up to close the app does not work on iOS 15.
        if #available(iOS 16, *) {
            closeFromAppSwitcherAndRelaunch()
            if isPrivate {
                mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.fireButton])
            } else {
                mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.searchButton])
            }
            let addNewTabButton = app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton]
            mozWaitForElementToExist(addNewTabButton)
            addNewTabButton.tapOnApp()
            if !app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].exists {
                addNewTabButton.tap()
            }
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton])
            app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].tap()
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton])
            XCTAssertEqual(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].value as! String, "2")
        }
    }
}
