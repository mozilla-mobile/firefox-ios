// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

let defaultSearchEngine1 = "Google"
let defaultSearchEngine2 = "Amazon.com"
let customSearchEngine = ["name": "youtube", "url": "https://youtube.com/search?q=%s"]

class SearchSettingsUITests: BaseTestCase {
    // https://testrail.stage.mozaws.net/index.php?/cases/view/2435664
    func testDefaultSearchEngine() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(SearchSettings)
        // Check the default browser
        let defaultSearchEngine = app.tables.cells.element(boundBy: 0)
        mozWaitForElementToExist(app.tables.cells.staticTexts[defaultSearchEngine1])

        // Change to another browser and check it is set as default
        defaultSearchEngine.tap()
        let listOfEngines = app.tables
        listOfEngines.staticTexts[defaultSearchEngine2].tap()
        mozWaitForElementToExist(app.tables.cells.staticTexts[defaultSearchEngine2])
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2353247
    func testCustomSearchEngineIsEditable() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(SearchSettings)
        // Add a custom search engine
        addCustomSearchEngine()
        // Check that the custom search appears on the list
        mozWaitForElementToExist(app.tables.cells.staticTexts[customSearchEngine["name"]!])

        // Check that it can be edited
        XCTAssertTrue(app.buttons["Edit"].isEnabled)
        app.buttons["Edit"].tap()
        XCTAssertTrue(app.buttons["Done"].isEnabled)
        app.buttons["Done"].tap()
        mozWaitForElementToExist(app.buttons["Edit"])
        XCTAssertTrue(app.buttons["Edit"].isEnabled)
        app.buttons["Edit"].tap()
        // Workaround for https://github.com/mozilla-mobile/firefox-ios/issues/18278
        // Remove if/else after fix
        if !iPad() {
            mozWaitForElementToExist(app.tables.buttons["Remove \(customSearchEngine["name"]!)"])
        } else {
            navigator.goto(SettingsScreen)
            navigator.goto(SearchSettings)
            mozWaitForElementToExist(app.buttons["Edit"])
            app.buttons["Edit"].tap()
            mozWaitForElementToExist(app.tables.buttons["Remove \(customSearchEngine["name"]!)"])
        }
    }

    private func addCustomSearchEngine() {
        mozWaitForElementToExist(app.tables.cells[AccessibilityIdentifiers.Settings.Search.customEngineViewButton])
        app.tables.cells[AccessibilityIdentifiers.Settings.Search.customEngineViewButton].tap()
        mozWaitForElementToExist(app.tables.cells.staticTexts["Search Engine"])
        app.tables.cells.textViews["customEngineTitle"].tap()
        app.tables.cells.textViews["customEngineTitle"].typeText(customSearchEngine["name"]!)

        app.tables.cells.textViews["customEngineUrl"].tap()
        app.tables.cells.textViews["customEngineUrl"].typeText(customSearchEngine["url"]!)
        mozWaitForElementToExist(app.buttons["Save"], timeout: 5)
        app.buttons["Save"].tap()
        // Check that custom engine has been added successfully
        mozWaitForElementToExist(app.tables.cells.staticTexts[customSearchEngine["name"]!])
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2353248
    func testCustomSearchEngineAsDefaultIsNotEditable() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(SearchSettings)
        // Edit is disabled
        XCTAssertFalse(app.buttons["Edit"].isEnabled)

        addCustomSearchEngine()
        // Edit is enabled
        XCTAssertTrue(app.buttons["Edit"].isEnabled)

        // Select the custom engine as the default one
        let defaultSearchEngine = app.tables.cells.element(boundBy: 0)
        defaultSearchEngine.tap()
        let listOfEngines = app.tables
        listOfEngines.staticTexts[customSearchEngine["name"]!].tap()
        // Edit is disabled
        XCTAssertFalse(app.buttons["Edit"].isEnabled)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2353249
    func testNavigateToSearchPickerTurnsOffEditing() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(SearchSettings)
        // Edit is disabled
        XCTAssertFalse(app.buttons["Edit"].isEnabled)

        addCustomSearchEngine()
        // Edit is enabled
        XCTAssertTrue(app.buttons["Edit"].isEnabled)
        app.buttons["Edit"].tap()
        XCTAssertTrue(app.buttons["Done"].isEnabled)

        // Navigate to the search engine picker and back
        let defaultSearchEngine = app.tables.cells.element(boundBy: 0)
        defaultSearchEngine.tap()
        app.buttons["Cancel"].tap()

        // Check to see we're not in editing state, edit is enable and done does not appear
        XCTAssertTrue(app.buttons["Edit"].isEnabled)
        mozWaitForElementToNotExist(app.buttons["Done"])

        // Make sure switches are there
        XCTAssertEqual(app.tables.cells.switches.count, app.tables.cells.count - 3)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2353250
    func testDeletingLastCustomEngineExitsEditing() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(SearchSettings)
        // Edit is disabled
        XCTAssertFalse(app.buttons["Edit"].isEnabled)
        // Add a custom search engine
        addCustomSearchEngine()
        XCTAssertTrue(app.buttons["Edit"].isEnabled)

        app.buttons["Edit"].tap()
        XCTAssertTrue(app.buttons["Done"].isEnabled)
        app.buttons["Done"].tap()
        mozWaitForElementToExist(app.buttons["Edit"])
        XCTAssertTrue(app.buttons["Edit"].isEnabled)
        app.buttons["Edit"].tap()
        // Remove the custom search engine and check that edit is disabled
        let tablesQuery = app.tables
        // Workaround for https://github.com/mozilla-mobile/firefox-ios/issues/18278
        // Remove if/else after fix
        if !iPad() {
            tablesQuery.buttons["Remove \(customSearchEngine["name"]!)"].tap()
        } else {
            navigator.goto(SettingsScreen)
            navigator.goto(SearchSettings)
            mozWaitForElementToExist(app.buttons["Edit"])
            app.buttons["Edit"].tap()
            mozWaitForElementToExist(tablesQuery.buttons["Remove \(customSearchEngine["name"]!)"])
            tablesQuery.buttons["Remove \(customSearchEngine["name"]!)"].tap()
        }
        tablesQuery.buttons[AccessibilityIdentifiers.Settings.Search.deleteButton].tap()
        XCTAssertFalse(app.buttons["Edit"].isEnabled)
    }
}
