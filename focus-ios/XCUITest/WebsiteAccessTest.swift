/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class WebsiteAccessTests: BaseTestCase {
    func setUrlAutoCompleteTo(desiredAutoCompleteState: String) {
        let homeViewSettingsButton = app.homeViewSettingsButton
        let settingsButton = app.settingsButton
        let settingsViewControllerAutoCompleteCell = app.tables.cells["SettingsViewController.autocompleteCell"]
        let autoCompleteSwitch = app.switches["toggleAutocompleteSwitch"]
        let settingsBackButton = app.settingsBackButton
        let settingsDoneButton = app.settingsDoneButton
        
        // Navigate to autocomplete settings
        mozTap(homeViewSettingsButton)
        mozTap(settingsButton)
        mozTap(settingsViewControllerAutoCompleteCell)
        
        let topSitesState = autoCompleteSwitch.value as? String == "1" ? "On" : "Off"
        // Toggle switch if desired state is already set
        if desiredAutoCompleteState != topSitesState {
            mozTap(autoCompleteSwitch)
        }
        
        // Navigate back to home page
        mozTap(settingsBackButton)
        mozTap(settingsDoneButton)
    }
    
    // Smoketest
    func testVisitWebsite() {
        dismissURLBarFocused()
        
        // Check initial page
        checkForHomeScreen()

        // Enter 'mozilla' on the search field
        let searchOrEnterAddressTextField = app.textFields["URLBar.urlText"]
        XCTAssertTrue(searchOrEnterAddressTextField.exists)
        XCTAssertTrue(searchOrEnterAddressTextField.isEnabled)

        // Check the text autocompletes to mozilla.org/, and also look for 'Search for mozilla' button below
        let label = app.textFields["URLBar.urlText"]
        searchOrEnterAddressTextField.tap()
        searchOrEnterAddressTextField.typeText("mozilla")
        waitForValueContains(label, value: "mozilla.org/")

        // Providing straight URL to avoid the error - and use internal website
        app.buttons["icon clear"].tap()
        loadWebPage("https://www.example.com")
        waitForValueContains(label, value: "www.example.com")

        // Erase the history
        app.buttons["URLBar.deleteButton"].firstMatch.tap()

        // Check it is on the initial page
        dismissURLBarFocused()
        checkForHomeScreen()
    }

    func testDisableAutocomplete() {
        let urlTextField = app.urlTextField
        let searchSuggestionsOverlay = app.searchSuggestionsOverlay
        
        // Test Setup
        dismissURLBarFocused()
        setUrlAutoCompleteTo(desiredAutoCompleteState: "Off")
        
        // Test Steps
        mozTypeText(urlTextField, text: "mozilla")
        
        // Test Assertion
        waitForExistence(searchSuggestionsOverlay)
        XCTAssertEqual(urlTextField.value as? String, "mozilla")
    }

    func testReEnableAutoComplete() {
        let urlTextField = app.urlTextField
        let searchSuggestionsOverlay = app.searchSuggestionsOverlay
        
        // Test Setup: to ensure autocomplete state is picked up, set to off, navigate out, then toggle back on
        dismissURLBarFocused()
        setUrlAutoCompleteTo(desiredAutoCompleteState: "Off")
        setUrlAutoCompleteTo(desiredAutoCompleteState: "On")
        
        // Test Steps
        mozTypeText(urlTextField, text: "mozilla")
        
        // Test Assertion
        waitForExistence(searchSuggestionsOverlay)
        XCTAssertEqual(urlTextField.value as? String, "mozilla.org/")
    }
    
    func testAutocompleteCustomDomain() {
        dismissURLBarFocused()
        app.buttons["HomeView.settingsButton"].tap()
        let settingsButton = app.settingsButton
        waitForExistence(settingsButton, timeout: 10)
        settingsButton.tap()
        waitForExistence(app.tables.cells["SettingsViewController.autocompleteCell"])
        // Add Custom Domain
        app.tables.cells["SettingsViewController.autocompleteCell"].tap()
        app.tables.cells["customURLS"].tap()
        app.tables.cells["addCustomDomainCell"].tap()

        let urlInput = app.textFields["urlInput"]
        urlInput.tap()
        urlInput.typeText("getfirefox.com")
        app.navigationBars.buttons["saveButton"].tap()
        let manageSitesBackButton = app.navigationBars.buttons["URL Autocomplete"]
        manageSitesBackButton.tap()
        app.navigationBars.buttons["Settings"].tap()
        app.buttons["SettingsViewController.doneButton"].tap()

        // Test auto completing the domain
        let searchOrEnterAddressTextField = app.textFields["URLBar.urlText"]
        searchOrEnterAddressTextField.tap()
        searchOrEnterAddressTextField.typeText("getfire")
        waitForExistence(app.buttons["Search for getfire"])
        waitForValueContains(searchOrEnterAddressTextField, value: "getfirefox.com/")

        // Remove the custom domain
        if !iPad() {
            app.buttons["URLBar.cancelButton"].tap()
        }
        app.buttons["Settings"].tap()
        waitForExistence(settingsButton, timeout: 10)
        settingsButton.tap()
        waitForExistence(app.tables.cells["SettingsViewController.autocompleteCell"])
        app.tables.cells["SettingsViewController.autocompleteCell"].tap()
        app.tables.cells["customURLS"].tap()
        app.navigationBars.buttons["editButton"].tap()
        app.tables.cells["getfirefox.com"].buttons["Delete getfirefox.com"].tap()
        app.tables.cells["getfirefox.com"].buttons["Delete"].tap()

        // Finish Editing
        app.navigationBars.buttons["editButton"].tap()
    }
}
