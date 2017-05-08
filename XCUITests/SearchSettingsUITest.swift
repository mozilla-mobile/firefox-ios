/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let defaultSearchEngine1 = "Yahoo"
let defaultSearchEngine2 = "Amazon.com"
let customSearchEngine = ["name": "youtube", "url": "http://youtube.com/search?q=%s"]

class SearchSettingsUITests: BaseTestCase {
    var navigator: Navigator!
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        navigator = createScreenGraph(app).navigator(self)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testDefaultSearchEngine() {
        navigator.goto(SearchSettings)
        // Check the default browser
        let defaultSearchEngine = app.tables.cells.element(boundBy: 0)
        waitforExistence(app.tables.cells.staticTexts[defaultSearchEngine1])

        // Change to another browser and check it is set as default
        defaultSearchEngine.tap()
        let listOfEngines = app.tables
        listOfEngines.staticTexts[defaultSearchEngine2].tap()
        waitforExistence(app.tables.cells.staticTexts[defaultSearchEngine2])
    }

    func testCustomSearchEngineIsEditable() {
        navigator.goto(SearchSettings)
        // Add a custom search engine
        addCustomSearchEngine()
        // Check that the custom search appears on the list
        waitforExistence(app.tables.cells.staticTexts[customSearchEngine["name"]!])

        // Check that it can be edited
        XCTAssertTrue(app.buttons["Edit"].isEnabled)
        app.buttons["Edit"].tap()

        waitforExistence(app.tables.buttons["Delete \(customSearchEngine["name"]!)"])
    }

    private func addCustomSearchEngine() {
        waitforExistence(app.tables.cells["customEngineViewButton"])
        app.tables.cells["customEngineViewButton"].tap()
        waitforExistence(app.tables.cells.staticTexts["Search Engine"])
        app.tables.cells.textViews["customEngineTitle"].tap()
        app.tables.cells.textViews["customEngineTitle"].typeText(customSearchEngine["name"]!)

        app.tables.cells.textViews["customEngineUrl"].tap()
        app.tables.cells.textViews["customEngineUrl"].typeText(customSearchEngine["url"]!)

        app.buttons["Save"].tap()
        // Check that custom engine has been added successfully
        waitforExistence(app.tables.cells.staticTexts[customSearchEngine["name"]!])
    }

    func testCustomSearchEngineAsDefaultIsNotEditable() {
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
        waitforNoExistence(app.buttons["Done"])
    }

    func testDeletingLastCustomEngineExitsEditing() {
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
        tablesQuery.buttons["Delete"].tap()

        XCTAssertFalse(app.buttons["Edit"].isEnabled)
    }
}
