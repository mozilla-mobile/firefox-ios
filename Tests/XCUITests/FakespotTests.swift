// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import XCTest

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
            website.textFields["Search Amazon"].tap()
            website.textFields["Search Amazon"].typeText("Shoe")
            website.buttons["Go"].tap()
            waitUntilPageLoad()
            website.images.firstMatch.tap()

            // Tap shopping cart icon on Awesome bar
            // Note: I can't find the label for the shopping cart icon.
            // Workaround: Tap somewhere left of the "Share" button
            waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.shareButton])
            waitUntilPageLoad()
            app.buttons[AccessibilityIdentifiers.Toolbar.shareButton].tapAtPoint(CGPoint(x: -10, y: 0))
            waitForExistence(app.otherElements["PopoverDismissRegion"])
            waitForExistence(app.staticTexts[AccessibilityIdentifiers.Shopping.sheetHeaderTitle])
            XCTAssertEqual(app.staticTexts[AccessibilityIdentifiers.Shopping.sheetHeaderTitle].label, "Review quality check")

            // Tap outside of the popover to close the popover
            website.textFields["Search Amazon"].tap()
            waitForNoExistence(app.otherElements["PopoverDismissRegion"])
        }
    }
}
