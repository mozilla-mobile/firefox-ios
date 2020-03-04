/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let website1: [String: String] = ["url": Base.helper.path(forTestPage: "test-mozilla-org.html"), "label": "Internet for people, not profit — Mozilla", "value": "localhost", "longValue": "localhost:\(serverPort)/test-fixture/test-mozilla-org.html"]
let website2 = Base.helper.path(forTestPage: "test-example.html")

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
        XCTAssert(Base.app.textFields["url"].exists)
        let defaultValuePlaceholder = Base.app.textFields["url"].placeholderValue!

        // Check the url placeholder text and that the back and forward buttons are disabled
        XCTAssertTrue(urlPlaceholder == defaultValuePlaceholder, "The placeholder does not show the correct value")
        XCTAssertFalse(Base.app.buttons["URLBarView.backButton"].isEnabled)
        XCTAssertFalse(Base.app.buttons["Forward"].isEnabled)
        XCTAssertFalse(Base.app.buttons["Reload"].isEnabled)

        // Navigate to two pages and press back once so that all buttons are enabled in landscape mode.
        navigator.openURL(website1["url"]!)
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForExistence(Base.app.webViews.links["Mozilla"], timeout: 10)
        let valueMozilla = Base.app.textFields["url"].value as! String
        XCTAssertEqual(valueMozilla, urlValueLong)
        XCTAssertTrue(Base.app.buttons["URLBarView.backButton"].isEnabled)
        XCTAssertFalse(Base.app.buttons["Forward"].isEnabled)
        XCTAssertTrue(Base.app.buttons["Reload"].isEnabled)

        navigator.openURL(website2)
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForValueContains(Base.app.textFields["url"], value: "localhost:\(serverPort)")
        XCTAssertTrue(Base.app.buttons["URLBarView.backButton"].isEnabled)
        XCTAssertFalse(Base.app.buttons["Forward"].isEnabled)

        Base.app.buttons["URLBarView.backButton"].tap()
        XCTAssertEqual(valueMozilla, urlValueLong)

        Base.helper.waitUntilPageLoad()
        XCTAssertTrue(Base.app.buttons["URLBarView.backButton"].isEnabled)
        XCTAssertTrue(Base.app.buttons["Forward"].isEnabled)

        // Open new tab and then go back to previous tab to test navigation buttons.
        Base.helper.waitForTabsButton()
        navigator.goto(TabTray)
        Base.helper.waitForExistence(Base.app.collectionViews.cells[website1["label"]!])
        Base.app.collectionViews.cells[website1["label"]!].tap()
        XCTAssertEqual(valueMozilla, urlValueLong)

        // Test to see if all the buttons are enabled then close tab.
        Base.helper.waitUntilPageLoad()
        XCTAssertTrue(Base.app.buttons["URLBarView.backButton"].isEnabled)
        XCTAssertTrue(Base.app.buttons["Forward"].isEnabled)

        navigator.nowAt(BrowserTab)
        Base.helper.waitForTabsButton()
        navigator.goto(TabTray)

        Base.helper.waitForExistence(Base.app.collectionViews.cells[website1["label"]!])
        Base.app.collectionViews.cells[website1["label"]!].swipeRight()

        // Go Back to other tab to see if all buttons are disabled.
        navigator.nowAt(BrowserTab)
        XCTAssertFalse(Base.app.buttons["URLBarView.backButton"].isEnabled)
        XCTAssertFalse(Base.app.buttons["Forward"].isEnabled)
    }

    func testClearURLTextUsingBackspace() {
        navigator.openURL(website1["url"]!)
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForTabsButton()
        Base.helper.waitForExistence(Base.app.webViews.links["Mozilla"], timeout: 10)
        let valueMozilla = Base.app.textFields["url"].value as! String
        XCTAssertEqual(valueMozilla, urlValueLong)

        // Simulate pressing on backspace key should remove the text
        Base.app.textFields["url"].tap()
        Base.app.textFields["address"].typeText("\u{8}")

        let value = Base.app.textFields["address"].value
        XCTAssertEqual(value as? String, "", "The url has not been removed correctly")
    }

    // Check that after scrolling on a page, the URL bar is hidden. Tapping one on the status bar will reveal the URL bar, tapping again on the status will scroll to the top
    func testRevealToolbarWhenTappingOnStatusbar() {
        // Workaround when testing on iPhone. If the orientation is in landscape on iPhone the tests will fail.
        if !Base.helper.iPad() {
            XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
            Base.helper.waitForExistence(Base.app.otherElements["Navigation Toolbar"])
        }
        navigator.openURL(website1["url"]!, waitForLoading: true)
        // Adding the waiter right after navigating to the webpage in order to make the test more stable
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForExistence(Base.app.buttons["TabLocationView.pageOptionsButton"], timeout: 10)
        let pageActionMenuButton = Base.app.buttons["TabLocationView.pageOptionsButton"]
        let statusbarElement: XCUIElement = {
            if #available(iOS 13, *) {
                return XCUIApplication(bundleIdentifier: "com.apple.springboard").statusBars.firstMatch
            } else {
                return Base.app.statusBars.children(matching: .other).element.children(matching: .other).element(boundBy: 0)
            }
        }()
        Base.app.swipeUp()
        XCTAssertFalse(pageActionMenuButton.exists)
        statusbarElement.tap(force: true)
        XCTAssertTrue(pageActionMenuButton.isHittable)
        statusbarElement.tap(force: true)
        let topElement = Base.app.webViews.otherElements["Internet for people, not profit — Mozilla"].children(matching: .other).matching(identifier: "navigation").element(boundBy: 0).staticTexts["Mozilla"]
        Base.helper.waitForExistence(topElement, timeout: 10)
        XCTAssertTrue(topElement.isHittable)
    }
}
