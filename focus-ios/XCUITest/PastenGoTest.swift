/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class PastenGoTest: BaseTestCase {
    // Test the clipboard contents are displayed/updated properly
    func testClipboard() throws {
        throw XCTSkip("This test needs to be updated or removed: Select menu not shown")
        let app = XCUIApplication()

        // Inject a string into clipboard
        let clipboardString = "Hello world"
        UIPasteboard.general.string = clipboardString

        // Enter 'mozilla' on the search field
        let searchOrEnterAddressTextField = app.textFields["URLBar.urlText"]
        searchOrEnterAddressTextField.typeText("mozilla")

        // Check clipboard suggestion is shown
        waitForValueContains(searchOrEnterAddressTextField, value: "mozilla.org/")
        waitForExistence(app.buttons["Search for mozilla"])
        app.typeText("\n")

        // Check the correct site is reached
        waitForValueContains(searchOrEnterAddressTextField, value: "www.mozilla")

        // Tap URL field, check for paste & go menu
        searchOrEnterAddressTextField.tap()
        sleep(1)
        searchOrEnterAddressTextField.tap()
        searchOrEnterAddressTextField.press(forDuration: 1.5)

        waitForExistence(app.menuItems["Select"])
        XCTAssertTrue(app.menuItems["Select All"].isEnabled)
        XCTAssertTrue(app.menuItems["Paste"].isEnabled)
        XCTAssertTrue(app.menuItems["Paste & Go"].isEnabled)

        // Copy URL into clipboard
        app.menuItems["Select All"].tap()
        waitForExistence(app.menuItems["Cut"])
        XCTAssertTrue(app.menuItems["Copy"].isEnabled)
        XCTAssertTrue(app.menuItems["Paste"].isEnabled)
        XCTAssertTrue(app.menuItems["Look Up"].isEnabled)
        app.menuItems["Copy"].tap()

        // Clear and start typing on the URL field again, verify the clipboard suggestion changes
        // If it's a URL, do not prefix "Search For"app.buttons["icon clear"].tap()
        searchOrEnterAddressTextField.typeText("mozilla")
        waitForExistence(app.buttons["Search for mozilla"])
        XCTAssertTrue(app.buttons[UIPasteboard.general.string!].isEnabled)
    }

    // Smoketest
    // Test Paste & Go feature
    func testPastenGo() throws {
        if #available(iOS 16, *) {
            throw XCTSkip("This test needs to be updated or removed: Select menu not shown")
        } else {
            // Inject a string into clipboard
            var clipboard = "https://www.mozilla.org/en-US/"
            UIPasteboard.general.string = clipboard

            // Tap url bar to show context menu
            let searchOrEnterAddressTextField = app.textFields["URLBar.urlText"]
            waitForExistence(searchOrEnterAddressTextField, timeout: 30)
            searchOrEnterAddressTextField.tap()
            waitForExistence(app.menuItems["Paste"], timeout: 10)
            XCTAssertTrue(app.menuItems["Paste & Go"].isEnabled)

            // Select paste and go, and verify it goes to the correct place
            app.menuItems["Paste & Go"].tap()

            waitForExistence(app.textFields["URLBar.urlText"], timeout: 10)
            waitForWebPageLoad()
            // Check the correct site is reached
            waitForValueContains(searchOrEnterAddressTextField, value: "mozilla.org")
            app.buttons["URLBar.deleteButton"].firstMatch.tap()
            waitForExistence(app.staticTexts["Browsing history cleared"])

            clipboard = "1(*&)(*%@@$^%^12345)"
            UIPasteboard.general.string = clipboard
            waitForExistence(searchOrEnterAddressTextField, timeout: 3)
            searchOrEnterAddressTextField.tap()
            waitForExistence(app.menuItems["Paste"], timeout: 5)
            app.menuItems["Paste"].tap()
            waitForValueContains(app.textFields["URLBar.urlText"], value: "1(*&)(*%@@$^%^12345)")
        }
    }
}
