/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let defaultSearchEngine1 = "Google"
let defaultSearchEngine2 = "Amazon.com"
let customSearchEngine = ["name": "youtube", "url": "https://youtube.com/search?q=%s"]

class SearchSettingsUITests: BaseTestCase {
    func testDefaultSearchEngine() {
        navigator.goto(SearchSettings)
        // Check the default browser
        let defaultSearchEngine = Base.app.tables.cells.element(boundBy: 0)
        Base.helper.waitForExistence(Base.app.tables.cells.staticTexts[defaultSearchEngine1])

        // Change to another browser and check it is set as default
        defaultSearchEngine.tap()
        let listOfEngines = Base.app.tables
        listOfEngines.staticTexts[defaultSearchEngine2].tap()
        Base.helper.waitForExistence(Base.app.tables.cells.staticTexts[defaultSearchEngine2])
    }

    func testCustomSearchEngineIsEditable() {
        navigator.goto(SearchSettings)
        // Add a custom search engine
        addCustomSearchEngine()
        // Check that the custom search appears on the list
        Base.helper.waitForExistence(Base.app.tables.cells.staticTexts[customSearchEngine["name"]!])

        // Check that it can be edited
        XCTAssertTrue(Base.app.buttons["Edit"].isEnabled)
        Base.app.buttons["Edit"].tap()

        Base.helper.waitForExistence(Base.app.tables.buttons["Delete \(customSearchEngine["name"]!)"])
    }

    private func addCustomSearchEngine() {
        Base.helper.waitForExistence(Base.app.tables.cells["customEngineViewButton"])
        Base.app.tables.cells["customEngineViewButton"].tap()
        Base.helper.waitForExistence(Base.app.tables.cells.staticTexts["Search Engine"])
        Base.app.tables.cells.textViews["customEngineTitle"].tap()
        Base.app.tables.cells.textViews["customEngineTitle"].typeText(customSearchEngine["name"]!)

        Base.app.tables.cells.textViews["customEngineUrl"].tap()
        Base.app.tables.cells.textViews["customEngineUrl"].typeText(customSearchEngine["url"]!)

        Base.app.buttons["Save"].tap()
        // Check that custom engine has been added successfully
        Base.helper.waitForExistence(Base.app.tables.cells.staticTexts[customSearchEngine["name"]!])
    }

    func testCustomSearchEngineAsDefaultIsNotEditable() {
        navigator.goto(SearchSettings)
        // Edit is disabled
        XCTAssertFalse(Base.app.buttons["Edit"].isEnabled)

        addCustomSearchEngine()
        // Edit is enabled
        XCTAssertTrue(Base.app.buttons["Edit"].isEnabled)

        // Select the custom engine as the default one
        let defaultSearchEngine = Base.app.tables.cells.element(boundBy: 0)
        defaultSearchEngine.tap()
        let listOfEngines = Base.app.tables
        listOfEngines.staticTexts[customSearchEngine["name"]!].tap()
        // Edit is disabled
        XCTAssertFalse(Base.app.buttons["Edit"].isEnabled)
    }

    func testNavigateToSearchPickerTurnsOffEditing() {
        navigator.goto(SearchSettings)
        // Edit is disabled
        XCTAssertFalse(Base.app.buttons["Edit"].isEnabled)

        addCustomSearchEngine()
        // Edit is enabled
        XCTAssertTrue(Base.app.buttons["Edit"].isEnabled)
        Base.app.buttons["Edit"].tap()
        XCTAssertTrue(Base.app.buttons["Done"].isEnabled)

        // Navigate to the search engine picker and back
        let defaultSearchEngine = Base.app.tables.cells.element(boundBy: 0)
        defaultSearchEngine.tap()
        Base.app.buttons["Cancel"].tap()

        // Check to see we're not in editing state, edit is enable and done does not appear
        XCTAssertTrue(Base.app.buttons["Edit"].isEnabled)
        Base.helper.waitForNoExistence(Base.app.buttons["Done"])

        //Make sure switches are there
        XCTAssertEqual(Base.app.tables.cells.switches.count, Base.app.tables.cells.count - 2)
    }

    func testDeletingLastCustomEngineExitsEditing() {
        navigator.goto(SearchSettings)
        // Edit is disabled
        XCTAssertFalse(Base.app.buttons["Edit"].isEnabled)
        // Add a custom search engine
        addCustomSearchEngine()
        XCTAssertTrue(Base.app.buttons["Edit"].isEnabled)

        Base.app.buttons["Edit"].tap()
        XCTAssertTrue(Base.app.buttons["Done"].isEnabled)
        // Remove the custom search engine and check that edit is disabled
        let tablesQuery = Base.app.tables
        tablesQuery.buttons["Delete \(customSearchEngine["name"]!)"].tap()
        tablesQuery.buttons["Delete"].tap()

        XCTAssertFalse(Base.app.buttons["Edit"].isEnabled)
    }
}
