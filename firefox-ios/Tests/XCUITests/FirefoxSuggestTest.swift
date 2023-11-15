// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class FirefoxSuggestTest: BaseTestCase {
    override func setUp() {
        super.setUp()
        waitForTabsButton()
        enableHiddenFeature(feature: "Firefox Suggest")
        ingestNewSuggestions()
        navigator.goto(NewTabScreen)
    }

    private func ingestNewSuggestions() {
        mozWaitForElementToExist(app.staticTexts["Ingest new suggestions now"])
        app.staticTexts["Ingest new suggestions now"].tap()
        app.navigationBars.buttons["Settings"].tap()
        navigator.nowAt(SettingsScreen)
    }

    func testFirefoxSuggestExists() {
        navigator.goto(URLBarOpen)
        app.textFields["address"].typeText("sho")
        mozWaitForElementToExist(app.tables["SiteTable"])
        mozWaitForElementToExist(app.staticTexts["Firefox Suggest"])
    }
}
