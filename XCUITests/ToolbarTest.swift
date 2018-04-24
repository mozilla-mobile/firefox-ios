/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let website1: [String: String] = ["url": "www.mozilla.org", "label": "Internet for people, not profit — Mozilla", "value": "mozilla.org"]
let website2 = "example.com"

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
        waitForValueContains(app.textFields["url"], value: website1["value"]!)

        XCTAssertTrue(app.buttons["URLBarView.backButton"].isEnabled)
        XCTAssertFalse(app.buttons["Forward"].isEnabled)
        XCTAssertTrue(app.buttons["Reload"].isEnabled)

        navigator.openURL(website2)
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: website2)
        XCTAssertTrue(app.buttons["URLBarView.backButton"].isEnabled)
        XCTAssertFalse(app.buttons["Forward"].isEnabled)

        app.buttons["URLBarView.backButton"].tap()
        waitForValueContains(app.textFields["url"], value: website1["value"]!)
        waitUntilPageLoad()
        XCTAssertTrue(app.buttons["URLBarView.backButton"].isEnabled)
        XCTAssertTrue(app.buttons["Forward"].isEnabled)

        // Open new tab and then go back to previous tab to test navigation buttons.
        navigator.goto(TabTray)
        waitforExistence(app.collectionViews.cells[website1["label"]!])
        app.collectionViews.cells[website1["label"]!].tap()
        waitForValueContains(app.textFields["url"], value: website1["value"]!)

        // Test to see if all the buttons are enabled then close tab.
        waitUntilPageLoad()
        XCTAssertTrue(app.buttons["URLBarView.backButton"].isEnabled)
        XCTAssertTrue(app.buttons["Forward"].isEnabled)

        navigator.nowAt(BrowserTab)
        navigator.goto(TabTray)

        waitforExistence(app.collectionViews.cells[website1["label"]!])
        app.collectionViews.cells[website1["label"]!].swipeRight()

        // Go Back to other tab to see if all buttons are disabled.
        navigator.nowAt(BrowserTab)
        XCTAssertFalse(app.buttons["URLBarView.backButton"].isEnabled)
        XCTAssertFalse(app.buttons["Forward"].isEnabled)
    }

    func testClearURLTextUsingBackspace() {
        navigator.openURL(website1["url"]!)
        waitForValueContains(app.textFields["url"], value: website1["value"]!)

        // Simulate pressing on backspace key should remove the text
        app.textFields["url"].tap()
        app.textFields["address"].typeText("\u{8}")

        let value = app.textFields["address"].value
        XCTAssertEqual(value as? String, "", "The url has not been removed correctly")
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
        let element = app/*@START_MENU_TOKEN@*/.webViews/*[[".otherElements[\"Web content\"].webViews",".otherElements[\"contentView\"].webViews",".webViews"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.children(matching: .other).element.children(matching: .other).element(boundBy: 0)
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
        let element = app/*@START_MENU_TOKEN@*/.webViews/*[[".otherElements[\"Web content\"].webViews",".otherElements[\"contentView\"].webViews",".webViews"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.children(matching: .other).element.children(matching: .other).element(boundBy: 0)
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
