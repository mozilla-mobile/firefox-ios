/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class SearchSuggestionsPromptTest: BaseTestCase {

    override func setUp() {
        super.setUp()
        dismissFirstRunUI()
    }

    override func tearDown() {
        app.terminate()
        super.tearDown()
    }

    func checkToggle(isOn: Bool) {
        let targetValue = isOn ? "1" : "0"
        XCTAssertEqual(app.tables.switches["BlockerToggle.enableSearchSuggestions"].value as! String, targetValue)
    }

    func checkSuggestions() {
        // Check search cells are displayed correctly
        let firstSuggestion = app.buttons.matching(identifier: "OverlayView.searchButton").element(boundBy: 0)
        waitforExistence(element: firstSuggestion)
        waitforExistence(element: app.buttons.matching(identifier: "OverlayView.searchButton").element(boundBy: 1))
        waitforExistence(element: app.buttons.matching(identifier: "OverlayView.searchButton").element(boundBy: 2))
        waitforExistence(element: app.buttons.matching(identifier: "OverlayView.searchButton").element(boundBy: 3))

        let predicate = NSPredicate(format: "label BEGINSWITH 'g'")
        let predicateQuery = app.buttons.matching(predicate)

        // Confirm that we have at least four suggestions starting with "g"
        XCTAssert(predicateQuery.count >= 4)

        // Check tapping on first suggestion leads to correct page
        firstSuggestion.tap()
        waitForValueContains(element: app.textFields["URLBar.urlText"], value: "g")
    }

    func typeInURLBar(text: String) {
        app.textFields["Search or enter address"].tap()
        app.textFields["Search or enter address"].typeText(text)
    }

    func checkToggleStartsOff() {
        waitforHittable(element: app.buttons["Settings"])
        app.buttons["Settings"].tap()
        checkToggle(isOn: false)
    }

    func testEnableThroughPrompt() {
        // Check search suggestions toggle is initially OFF
        checkToggleStartsOff()

        // Activate prompt by typing in URL bar
        app.buttons["SettingsViewController.doneButton"].tap()
        typeInURLBar(text: "g")

        // Prompt should display
        waitforExistence(element: app.otherElements["SearchSuggestionsPromptView"])

        // Press enable
        app.buttons["SearchSuggestionsPromptView.enableButton"].tap()

        // Ensure prompt disappears
        waitforNoExistence(element: app.otherElements["SearchSuggestionsPromptView"])

        // Ensure search suggestions are shown
        checkSuggestions()

        // Check search suggestions toggle is ON
        waitforHittable(element: app.buttons["HomeView.settingsButton"])
        app.buttons["HomeView.settingsButton"].tap()
        checkToggle(isOn: true)
    }

    func testDisableThroughPrompt() {
        // Check search suggestions toggle is initially OFF
        checkToggleStartsOff()

        // Activate prompt by typing in URL bar
        app.buttons["SettingsViewController.doneButton"].tap()
        typeInURLBar(text: "g")

        // Prompt should display
        waitforExistence(element: app.otherElements["SearchSuggestionsPromptView"])

        // Press disable
        app.buttons["SearchSuggestionsPromptView.disableButton"].tap()

        // Ensure prompt disappears
        waitforNoExistence(element: app.otherElements["SearchSuggestionsPromptView"])

        // Ensure only one search cell is shown
        let suggestion = app.buttons.matching(identifier: "OverlayView.searchButton").element(boundBy: 0)
        waitforExistence(element: suggestion)
        XCTAssertEqual("Search for g", suggestion.label)

        // Check tapping on suggestion leads to correct page
        suggestion.tap()
        waitForValueContains(element: app.textFields["URLBar.urlText"], value: "g")

        // Check search suggestions toggle is OFF
        waitforHittable(element: app.buttons["HomeView.settingsButton"])
        app.buttons["HomeView.settingsButton"].tap()
        checkToggle(isOn: false)
    }

    func testEnableThroughToggle() {
        // Check search suggestions toggle is initially OFF
        checkToggleStartsOff()

        // Turn toggle ON
        app.tables.switches["BlockerToggle.enableSearchSuggestions"].tap()

        // Prompt should not display
        app.buttons["SettingsViewController.doneButton"].tap()
        typeInURLBar(text: "g")
        waitforNoExistence(element: app.otherElements["SearchSuggestionsPromptView"])

        // Ensure search suggestions are shown
        checkSuggestions()
    }

    func testEnableThenDisable() {
        // Check search suggestions toggle is initially OFF
        checkToggleStartsOff()

        // Activate prompt by typing in URL bar
        app.buttons["SettingsViewController.doneButton"].tap()
        typeInURLBar(text: "g")

        // Prompt should display
        waitforExistence(element: app.otherElements["SearchSuggestionsPromptView"])

        // Press enable
        app.buttons["SearchSuggestionsPromptView.enableButton"].tap()

        // Ensure prompt disappears
        waitforNoExistence(element: app.otherElements["SearchSuggestionsPromptView"])

        // Ensure search suggestions are shown
        checkSuggestions()

        // Disable through settings
        waitforHittable(element: app.buttons["HomeView.settingsButton"])
        app.buttons["HomeView.settingsButton"].tap()
        app.tables.switches["BlockerToggle.enableSearchSuggestions"].tap()
        checkToggle(isOn: false)

        // Ensure only one search cell is shown
        app.buttons["SettingsViewController.doneButton"].tap()
        typeInURLBar(text: "g")
        let suggestion = app.buttons.matching(identifier: "OverlayView.searchButton").element(boundBy: 0)
        waitforExistence(element: suggestion)
        XCTAssertEqual("Search for g", suggestion.label)
    }
}
