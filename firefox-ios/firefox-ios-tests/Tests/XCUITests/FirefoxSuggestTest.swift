// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class FirefoxSuggestTest: BaseTestCase {
    // https://mozilla.testrail.io/index.php?/cases/view/2360075
    func testFirefoxSuggestExists() {
        navigator.openURL("www.example.com")
        navigator.createNewTab()
        navigator.goto(URLBarOpen)
        urlBarAddress.typeText("ex")
        mozWaitForElementToExist(app.tables["SiteTable"])
        mozWaitForElementToExist(app.tables["SiteTable"].staticTexts["Google Search"])
        mozWaitForElementToExist(app.tables["SiteTable"].staticTexts["Firefox Suggest"])
    }
}
