// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class FirefoxSuggestTest: BaseTestCase {
    // https://mozilla.testrail.io/index.php?/cases/view/2360075
    func testFirefoxSuggestExists() {
        navigator.goto(URLBarOpen)
        urlBarAddress.typeText("sho")
        // Workaround for https://github.com/mozilla-mobile/firefox-ios/issues/28166
        // Workaround: Press delete to trigger suggestions
        let suggestCell = app.tables["SiteTable"].staticTexts["Firefox Suggest"]
        if !suggestCell.waitForExistence(timeout: 3) {
            urlBarAddress.typeText(XCUIKeyboardKey.delete.rawValue)
            XCTAssertTrue(suggestCell.waitForExistence(timeout: 1),
                          "Firefox Suggest did not appear even after workaround")
        }
        // End of workaround
        waitForElementsToExist(
            [
            app.tables["SiteTable"],
            app.tables["SiteTable"].staticTexts["Google Search"],
            app.tables["SiteTable"].staticTexts["Firefox Suggest"]
            ]
        )
    }
}
