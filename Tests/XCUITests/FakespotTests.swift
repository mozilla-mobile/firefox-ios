// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import XCTest
import Shared

class FakespotTests: BaseTestCase {
    // https://testrail.stage.mozaws.net/index.php?/cases/view/2288332
    func testFakespotAvailable() throws {
        if iPad() {
            throw XCTSkip("Fakespot is not enabled in iPad")
        } else {
            navigator.openURL("https://www.amazon.com")
            waitUntilPageLoad()

            // Search for and open a shoe listing
            let website = app.webViews["contentView"].firstMatch
            mozWaitForElementToExist(website.textFields["Search Amazon"])
            XCTAssert(website.textFields["Search Amazon"].isEnabled)
            website.textFields["Search Amazon"].tap()
            website.textFields["Search Amazon"].typeText("Shoe")
            website.buttons["Go"].tap()
            waitUntilPageLoad()
            website.images.firstMatch.tap()

            // Tap the shopping cart icon
            waitUntilPageLoad()
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.shoppingButton])
            app.buttons[AccessibilityIdentifiers.Toolbar.shoppingButton].tap()
            mozWaitForElementToExist(app.staticTexts[AccessibilityIdentifiers.Shopping.sheetHeaderTitle])
            XCTAssertEqual(app.staticTexts[AccessibilityIdentifiers.Shopping.sheetHeaderTitle].label, .Shopping.SheetHeaderTitle)

            // Close the popover
            app.otherElements.buttons[AccessibilityIdentifiers.Shopping.sheetCloseButton].tap()
            mozWaitForElementToNotExist(app.otherElements[AccessibilityIdentifiers.Shopping.sheetHeaderTitle])
        }
    }
}
