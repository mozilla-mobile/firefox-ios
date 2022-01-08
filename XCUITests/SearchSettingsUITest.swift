// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest

let defaultSearchEngine1 = "Google"
let defaultSearchEngine2 = "Amazon.com"
let customSearchEngine = ["name": "youtube", "url": "https://youtube.com/search?q=%s"]

class SearchSettingsUITests: BaseTestCase {
    func testDefaultSearchEngine() {
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(SearchSettings)
        // Check the default browser
        let defaultSearchEngine = app.tables.cells.element(boundBy: 0)
        waitForExistence(app.tables.cells.staticTexts[defaultSearchEngine1])

        // Change to another browser and check it is set as default
        defaultSearchEngine.tap()
        let listOfEngines = app.tables
        listOfEngines.staticTexts[defaultSearchEngine2].tap()
        waitForExistence(app.tables.cells.staticTexts[defaultSearchEngine2])
    }

    func testCustomSearchEngineIsEditable() {
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(SearchSettings)
        // Add a custom search engine
        addCustomSearchEngine()
        // Check that the custom search appears on the list
        waitForExistence(app.tables.cells.staticTexts[customSearchEngine["name"]!])

        // Check that it can be edited
        XCTAssertTrue(app.buttons["Edit"].isEnabled)
        app.buttons["Edit"].tap()

        waitForExistence(app.tables.buttons["Delete \(customSearchEngine["name"]!)"])
    }

    private func addCustomSearchEngine() {
        waitForExistence(app.tables.cells[AccessibilityIdentifiers.Settings.Search.customEngineViewButton])
        app.tables.cells[AccessibilityIdentifiers.Settings.Search.customEngineViewButton].tap()
        waitForExistence(app.tables.cells.staticTexts["Search Engine"])
        app.tables.cells.textViews["customEngineTitle"].tap()
        app.tables.cells.textViews["customEngineTitle"].typeText(customSearchEngine["name"]!)

        app.tables.cells.textViews["customEngineUrl"].tap()
        app.tables.cells.textViews["customEngineUrl"].typeText(customSearchEngine["url"]!)

        app.buttons["Save"].tap()
        // Check that custom engine has been added successfully
        waitForExistence(app.tables.cells.staticTexts[customSearchEngine["name"]!])
    }

    func testCustomSearchEngineAsDefaultIsNotEditable() {
        navigator.performAction(Action.CloseURLBarOpen)
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

    func testNavigateToSearchPickerTurnsOffEditing() {
        navigator.performAction(Action.CloseURLBarOpen)
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
        waitForNoExistence(app.buttons["Done"])

        //Make sure switches are there
        XCTAssertEqual(app.tables.cells.switches.count, app.tables.cells.count - 2)
    }

    func testDeletingLastCustomEngineExitsEditing() {
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(SearchSettings)
        // Edit is disabled
        XCTAssertFalse(app.buttons["Edit"].isEnabled)
        // Add a custom search engine
        addCustomSearchEngine()
        XCTAssertTrue(app.buttons["Edit"].isEnabled)

        app.buttons["Edit"].tap()
        XCTAssertTrue(app.buttons["Done"].isEnabled)
        // Remove the custom search engine and check that edit is disabled
        let tablesQuery = app.tables
        tablesQuery.buttons["Delete \(customSearchEngine["name"]!)"].tap()
        tablesQuery.buttons[AccessibilityIdentifiers.Settings.Search.deleteButton].tap()

        XCTAssertFalse(app.buttons["Edit"].isEnabled)
    }
}
