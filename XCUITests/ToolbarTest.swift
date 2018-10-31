/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let website1: [String: String] = ["url": path(forTestPage: "test-mozilla-org.html"), "label": "Internet for people, not profit — Mozilla", "value": "localhost", "longValue": "localhost:6571/test-fixture/test-mozilla-org.html"]
let website2 = path(forTestPage: "test-example.html")

let PDFWebsite = ["url": "http://www.pdf995.com/samples/pdf.pdf"]

class ToolbarTests: BaseTestCase {
    override func setUp() {
        super.setUp()
        XCUIDevice.shared.orientation = UIDeviceOrientation.landscapeLeft
    }

    override func tearDown() {
        XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        super.tearDown()
    }

    /**
     * Tests landscape page navigation enablement with the URL bar with tab switching.
     */
    func testLandscapeNavigationWithTabSwitch() {
        let urlPlaceholder = "Search or enter address"
        XCTAssert(app.textFields["url"].exists)
        let defaultValuePlaceholder = app.textFields["url"].placeholderValue!

        // Check the url placeholder text and that the back and forward buttons are disabled
        XCTAssertTrue(urlPlaceholder == defaultValuePlaceholder, "The placeholder does not show the correct value")
        XCTAssertFalse(app.buttons["URLBarView.backButton"].isEnabled)
        XCTAssertFalse(app.buttons["Forward"].isEnabled)
        XCTAssertFalse(app.buttons["Reload"].isEnabled)

        // Navigate to two pages and press back once so that all buttons are enabled in landscape mode.
        navigator.openURL(website1["url"]!)
        waitUntilPageLoad()
        waitForExistence(app.webViews.links["Mozilla"], timeout: 5)
        let valueMozilla = app.textFields["url"].value as! String
        XCTAssertEqual(valueMozilla, urlValueLong)


        XCTAssertTrue(app.buttons["URLBarView.backButton"].isEnabled)
        XCTAssertFalse(app.buttons["Forward"].isEnabled)
        XCTAssertTrue(app.buttons["Reload"].isEnabled)

        navigator.openURL(website2)
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: "localhost:6571")
        XCTAssertTrue(app.buttons["URLBarView.backButton"].isEnabled)
        XCTAssertFalse(app.buttons["Forward"].isEnabled)

        app.buttons["URLBarView.backButton"].tap()
        XCTAssertEqual(valueMozilla, urlValueLong)

        waitUntilPageLoad()
        XCTAssertTrue(app.buttons["URLBarView.backButton"].isEnabled)
        XCTAssertTrue(app.buttons["Forward"].isEnabled)

        // Open new tab and then go back to previous tab to test navigation buttons.
        navigator.goto(TabTray)
        waitForExistence(app.collectionViews.cells[website1["label"]!])
        app.collectionViews.cells[website1["label"]!].tap()
        XCTAssertEqual(valueMozilla, urlValueLong)

        // Test to see if all the buttons are enabled then close tab.
        waitUntilPageLoad()
        XCTAssertTrue(app.buttons["URLBarView.backButton"].isEnabled)
        XCTAssertTrue(app.buttons["Forward"].isEnabled)

        navigator.nowAt(BrowserTab)
        navigator.goto(TabTray)

        waitForExistence(app.collectionViews.cells[website1["label"]!])
        app.collectionViews.cells[website1["label"]!].swipeRight()

        // Go Back to other tab to see if all buttons are disabled.
        navigator.nowAt(BrowserTab)
        XCTAssertFalse(app.buttons["URLBarView.backButton"].isEnabled)
        XCTAssertFalse(app.buttons["Forward"].isEnabled)
    }

    func testClearURLTextUsingBackspace() {
        navigator.openURL(website1["url"]!)
        waitUntilPageLoad()
        waitForExistence(app.webViews.links["Mozilla"], timeout: 5)
        waitForValueContains(app.textFields["url"], value: website1["value"]!)

        // Simulate pressing on backspace key should remove the text
        app.textFields["url"].tap()
        app.textFields["address"].typeText("\u{8}")

        let value = app.textFields["address"].value
        XCTAssertEqual(value as? String, "", "The url has not been removed correctly")
    }

    //Check that after scrolling on a page, the URL bar is hidden. Tapping one on the status bar will reveal the URL bar, tapping again on the status will scroll to the top
    func testRevealToolbarWhenTappingOnStatusbar(){
        //Workaround when testing on iPhone. If the orientation is in landscape on iPhone the tests will fail.
        if !iPad() {
            XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
            waitForExistence(app.otherElements["Navigation Toolbar"])
        }
        navigator.openURL(website1["url"]!, waitForLoading: true)
        let pageActionMenuButton = app.buttons["TabLocationView.pageOptionsButton"]
        waitForExistence(pageActionMenuButton, timeout: 5)
        let statusbarElement = app.statusBars.children(matching: .other).element.children(matching: .other).element(boundBy: 0)
        XCTAssertTrue(statusbarElement.isHittable)
        app.swipeUp()
        let hiddenStatusbarElement = app.statusBars.children(matching: .other).element.children(matching: .other).element(boundBy: 0)
        XCTAssertFalse(pageActionMenuButton.exists)
        hiddenStatusbarElement.tap()
        XCTAssertTrue(hiddenStatusbarElement.isHittable)
        hiddenStatusbarElement.tap()
        let topElement = app.webViews.otherElements["Internet for people, not profit — Mozilla"].children(matching: .other).matching(identifier: "navigation").element(boundBy: 0).staticTexts["Mozilla"]
        waitForExistence(topElement)
        XCTAssertTrue(topElement.isHittable)
    }

    func testShowToolbarWhenScrollingDefaultOption() {
        navigator.goto(SettingsScreen)
        // Check that the setting is off by default
        XCTAssertFalse(app.cells.switches["AlwaysShowToolbar"].isSelected)
    }

    func testShowDoNotShowToolbarWhenScrollingPortrait() {
        XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        // The toolbar should dissapear when scrolling up
        navigator.openURL(PDFWebsite["url"]!)
        waitUntilPageLoad()

        // Swipe Up and check that the toolbar is not available and Down and it is available again
        let toolbarElement = app.buttons["TopTabsViewController.tabsButton"]
        let element = app.webViews.children(matching: .other).element.children(matching: .other).element(boundBy: 0)
        element.swipeUp()
        XCTAssertFalse(toolbarElement.isHittable)

        element.swipeDown()
        XCTAssertTrue(toolbarElement.isHittable)

        // Change the setting
        navigator.goto(SettingsScreen)
        navigator.performAction(Action.ToggleShowToolbarWhenScrolling)
        XCTAssertTrue(toolbarElement.isHittable)

        // The toolbar should not dissapear when scrolling up
        element.swipeUp()
        XCTAssertTrue(toolbarElement.isHittable)
        element.swipeDown()
        XCTAssertTrue(toolbarElement.isHittable)
    }

    func testShowDoNotShowToolbarWhenScrollingLandscape() {
        // The toolbar should dissapear when scrolling up
        navigator.openURL(PDFWebsite["url"]!)
        waitUntilPageLoad()

        // Swipe Up and check that the toolbar is not available and Down and it is available again
        let toolbarElement = app.buttons["TopTabsViewController.tabsButton"]
        let element = app.webViews.children(matching: .other).element.children(matching: .other).element(boundBy: 0)
        element.swipeUp()
        XCTAssertFalse(toolbarElement.isHittable)

        element.swipeDown()
        XCTAssertTrue(toolbarElement.isHittable)

        // Change the setting
        navigator.goto(SettingsScreen)
        navigator.performAction(Action.ToggleShowToolbarWhenScrolling)
        XCTAssertTrue(toolbarElement.isHittable)
        XCTAssertTrue(toolbarElement.isHittable)

        // The toolbar should not dissapear when scrolling up
        element.swipeUp()
        XCTAssertTrue(toolbarElement.isHittable)
        element.swipeDown()
        XCTAssertTrue(toolbarElement.isHittable)
    }
}
