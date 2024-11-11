/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class SearchSuggestionsPromptTest: BaseTestCase {
    func checkToggle(isOn: Bool) {
        let targetValue = isOn ? "1" : "0"
        XCTAssertEqual(app.tables.switches["BlockerToggle.enableSearchSuggestions"].value as! String, targetValue)
    }

    func checkSuggestions() {
        // Check search cells are displayed correctly
        let firstSuggestion = app.buttons.matching(identifier: "OverlayView.searchButton").element(boundBy: 0)
        waitForExistence(firstSuggestion)
        waitForExistence(app.buttons.matching(identifier: "OverlayView.searchButton").element(boundBy: 1))
        waitForExistence(app.buttons.matching(identifier: "OverlayView.searchButton").element(boundBy: 2))
        waitForExistence(app.buttons.matching(identifier: "OverlayView.searchButton").element(boundBy: 3))

        let predicate = NSPredicate(format: "label BEGINSWITH 'g'")
        let predicateQuery = app.buttons.matching(predicate)

        // Confirm that we have at least four suggestions starting with "g"
        XCTAssert(predicateQuery.count >= 4)

        // Check tapping on first suggestion leads to correct page
        firstSuggestion.tap()
        waitForValueContains(app.textFields["URLBar.urlText"], value: "g")
    }

    func typeInURLBar(text: String) {
        app.textFields["Search or enter address"].tap()
        app.textFields["Search or enter address"].typeText(text)
    }

    func checkToggleStartsOff() {
        dismissURLBarFocused()
        waitForExistence(app.buttons["HomeView.settingsButton"])
        // Set search engine to Google
        app.buttons["HomeView.settingsButton"].tap()
        let settingsButton = app.settingsButton
        waitForExistence(settingsButton)
        settingsButton.tap()
        waitForExistence(app.tables.cells["SettingsViewController.searchCell"])
        checkToggle(isOn: false)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/1707746
    func testEnableThroughPrompt() {
        // Check search suggestions toggle is initially OFF
        checkToggleStartsOff()

        // Activate prompt by typing in URL bar
        app.buttons["SettingsViewController.doneButton"].tap()
        typeInURLBar(text: "g")

        // Prompt should display
        waitForExistence(app.otherElements["SearchSuggestionsPromptView"])

        // Press enable
        app.buttons["SearchSuggestionsPromptView.enableButton"].tap()

        // Ensure prompt disappears
        waitForNoExistence(app.otherElements["SearchSuggestionsPromptView"])

        // Adding a delay in case of slow network
        sleep(4)

        // Ensure search suggestions are shown
        checkSuggestions()

        // Check search suggestions toggle is ON
        waitForHittable(app.buttons["HomeView.settingsButton"])
        app.buttons["HomeView.settingsButton"].tap()
        let settingsButton = app.settingsButton
        waitForExistence(settingsButton)
        settingsButton.tap()
        waitForExistence(app.tables.cells["SettingsViewController.searchCell"])
        checkToggle(isOn: true)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2524590
    func testDisableThroughPrompt() {
        // Check search suggestions toggle is initially OFF
        checkToggleStartsOff()

        // Activate prompt by typing in URL bar
        app.buttons["SettingsViewController.doneButton"].tap()
        typeInURLBar(text: "g")

        // Prompt should display
        waitForExistence(app.otherElements["SearchSuggestionsPromptView"])

        // Press disable
        app.buttons["SearchSuggestionsPromptView.disableButton"].tap()

        // Ensure prompt disappears
        waitForNoExistence(app.otherElements["SearchSuggestionsPromptView"])

        // Ensure only one search cell is shown
        let suggestion = app.buttons.matching(identifier: "OverlayView.searchButton").element(boundBy: 0)
        waitForExistence(suggestion)
        XCTAssert("Search for g" == suggestion.label || "g" == suggestion.label)

        // Check tapping on suggestion leads to correct page
        suggestion.tap()
        waitForValueContains(app.textFields["URLBar.urlText"], value: "g")

        // Check search suggestions toggle is OFF
        waitForHittable(app.buttons["HomeView.settingsButton"])
        app.buttons["HomeView.settingsButton"].tap()
        let settingsButton = app.settingsButton
        waitForExistence(settingsButton)
        settingsButton.tap()
        waitForExistence(app.tables.cells["SettingsViewController.searchCell"])
        checkToggle(isOn: false)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2524591
    func testEnableThroughToggle() {
        // Check search suggestions toggle is initially OFF
        checkToggleStartsOff()

        // Turn toggle ON
        waitForExistence(app.tables.switches["BlockerToggle.enableSearchSuggestions"])

        app.tables.cells.switches["BlockerToggle.enableSearchSuggestions"].tap()

        // Prompt should not display
        app.buttons["SettingsViewController.doneButton"].tap()
        typeInURLBar(text: "g")

        // Adding a delay in case of slow network
        sleep(4)

        waitForNoExistence(app.otherElements["SearchSuggestionsPromptView"])

        // Ensure search suggestions are shown
        checkSuggestions()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2524592
    func testEnableThenDisable() {
        // Check search suggestions toggle is initially OFF
        checkToggleStartsOff()

        // Activate prompt by typing in URL bar
        app.buttons["SettingsViewController.doneButton"].tap()
        typeInURLBar(text: "g")

        // Prompt should display
        waitForExistence(app.otherElements["SearchSuggestionsPromptView"])

        // Press enable
        app.buttons["SearchSuggestionsPromptView.enableButton"].tap()

        // Adding a delay in case of slow network
        sleep(4)

        // Ensure prompt disappears
        waitForNoExistence(app.otherElements["SearchSuggestionsPromptView"])

        // Ensure search suggestions are shown
        checkSuggestions()

        // Disable through settings
        waitForExistence(app.buttons["HomeView.settingsButton"])
        app.buttons["HomeView.settingsButton"].tap()
        let settingsButton = app.settingsButton
        waitForExistence(settingsButton)
        settingsButton.tap()
        waitForExistence(app.tables.cells["SettingsViewController.searchCell"])
        app.tables.switches["BlockerToggle.enableSearchSuggestions"].tap()
        checkToggle(isOn: false)

        // Ensure only one search cell is shown
        app.buttons["SettingsViewController.doneButton"].tap()
        let urlBarTextField = app.textFields["URLBar.urlText"]
        urlBarTextField.tap()
        urlBarTextField.typeText("g")
        let suggestion = app.buttons.matching(identifier: "OverlayView.searchButton").element(boundBy: 0)
        waitForExistence(suggestion)
        XCTAssert("Search for g" == suggestion.label || "g" == suggestion.label)
    }
}
