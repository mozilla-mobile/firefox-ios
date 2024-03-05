/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class SnapshotTests: BaseTestCaseL10n {

    func test01FirstRunScreens() {
        waitForExistence(app.collectionViews.cells.images["icon_background"], timeout: 10)
        snapshot("00FirstRun")
        app.collectionViews.cells.images["icon_background"].swipeLeft()
        waitForExistence(app.collectionViews.cells.images["icon_hugging_focus"], timeout: 3)
        snapshot("01FirstRun")
    }

    func test02Settings() {
        dismissURLBarFocused()
        openSettings()
        snapshot("08Settings")
        app.swipeUp()
        snapshot("9Settings")

        // Siri menu
        waitForExistence(app.cells["settingsViewController.siriOpenURLCell"])
        app.cells["settingsViewController.siriOpenURLCell"].tap()
        snapshot("SiriMenu")
        app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap()
        waitForExistence(app.cells["settingsViewController.siriOpenURLCell"])
        app.swipeDown()

        // Tracking Protection menu
        waitForExistence(app.cells["settingsViewController.trackingCell"])
        app.cells["settingsViewController.trackingCell"].tap()
        snapshot("10SettingsBlockOtherContentTrackers")
        app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap()

        // AutoCompleteURL menus
        waitForExistence(app.cells["SettingsViewController.autocompleteCell"], timeout: 5)
        app.cells["SettingsViewController.autocompleteCell"].tap()
        snapshot("12AutocompleteCell")

        app.cells["customURLS"].tap()
        snapshot("AddCustomURL")
        app.cells["addCustomDomainCell"].tap()
        snapshot("AddCustomURLFields")
        app.textFields["urlInput"].typeText("mozilla\n")
        snapshot("AddedCustomURL")
    }
    
    func test03About() {
        dismissURLBarFocused()
        openSettings()
        waitForExistence(app.cells["settingsViewController.about"])
        app.cells["settingsViewController.about"].tap()
        snapshot("13About")
    }

    func test05SafariIntegration() {
        dismissURLBarFocused()
        openSettings()
        waitForExistence(app.tables.switches["BlockerToggle.Safari"])
        app.tables.switches["BlockerToggle.Safari"].tap()
        snapshot("15SafariIntegrationInstructions")
    }

    func test06Theme() {
        dismissURLBarFocused()
        openSettings()
        waitForExistence(app.cells["settingsViewController.themeCell"])
        app.cells["settingsViewController.themeCell"].tap()
        // Toggle the switch on-off to see the different menus
        waitForExistence(app.cells["themeViewController.themetoogleCell"])
        app.cells["themeViewController.themetoogleCell"].switches.element(boundBy: 0).tap()
        snapshot("Settings-theme1")
        app.cells["themeViewController.themetoogleCell"].switches.element(boundBy: 0).tap()
        snapshot("Settings-theme2")
    }

    func test07PasteAndGo() {
        // Inject a string into clipboard
        let clipboardString = "Hello world"
        UIPasteboard.general.string = clipboardString

        // Enter 'bugzilla.mozilla.org' on the search field as its URL does not change for locale.
        let searchOrEnterAddressTextField = app.textFields["URLBar.urlText"]
        searchOrEnterAddressTextField.tap()
        searchOrEnterAddressTextField.typeText("bugzilla.mozilla.org\n")

        // Check the correct site is reached
        waitForValueContains(searchOrEnterAddressTextField, value: "bugzilla.mozilla.org")

        // Tap URL field, check for paste & go menu
        searchOrEnterAddressTextField.press(forDuration: 2)
        snapshot("18PasteAndGo")
    }

    func test10CustomSearchEngines() {
        dismissURLBarFocused()
        app.buttons["HomeView.settingsButton"].tap()
        snapshot("20HomeViewSettings")
        app.collectionViews.buttons.element(boundBy: 1).tap()
        waitForExistence(app.cells["SettingsViewController.searchCell"])
        app.cells["SettingsViewController.searchCell"].tap()
        snapshot("SettingsSearchEngine")
        app.cells["addSearchEngine"].tap()
        snapshot("AddSearchEngine")
        app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap()
        waitForExistence(app.cells["addSearchEngine"])
        app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap()
    }

    func test11WebsiteView() {
        app.textFields.firstMatch.tap()
        app.textFields.firstMatch.typeText("example.com")
        snapshot("04SearchFor")

        app.typeText("\n")
        waitForValueContains(app.textFields["URLBar.urlText"], value: "example")
        waitForExistence(app.buttons["URLBar.deleteButton"], timeout: 10)
        app.buttons["URLBar.deleteButton"].tap()
        snapshot("07YourBrowsingHistoryHasBeenErased")
    }

    func test12RemoveShortcut() {
        loadWebPage("mozilla.org")
        waitForWebPageLoad()

        // Tap on shortcuts settings menu option
        waitForExistence(app.buttons["HomeView.settingsButton"], timeout: 10)
        app.buttons["HomeView.settingsButton"].tap()
        waitForExistence(app.collectionViews.cells.buttons.element(boundBy: 6), timeout: 10)
        snapshot("WebsiteBrowserMenu")
        app.collectionViews.cells.buttons.element(boundBy: 6).tap()

        // Tap on erase button to go to homepage and check the shortcut created
        waitForExistence(app.buttons["URLBar.deleteButton"])
        app.buttons["URLBar.deleteButton"].firstMatch.tap()
        // Verify the shortcut is created
        waitForExistence(app.otherElements.staticTexts["Mozilla"], timeout: 5)

        // Open shortcut to check the tab menu label for shortcut option
        app.otherElements.staticTexts["Mozilla"].tap()
        waitForExistence(app.buttons["HomeView.settingsButton"])
        app.buttons["HomeView.settingsButton"].tap()
        waitForExistence(app.collectionViews.cells.buttons.element(boundBy: 6), timeout: 5)
        snapshot("1-RemoveShortcutTabMenu")

        // Go back to homescreen
        app.collectionViews.cells.buttons.element(boundBy: 0).tap()
        waitForExistence(app.navigationBars.buttons["SettingsViewController.doneButton"])
        app.navigationBars.buttons["SettingsViewController.doneButton"].tap()
        waitForExistence(app.buttons["URLBar.deleteButton"].firstMatch)
        app.buttons["URLBar.deleteButton"].firstMatch.tap()
        waitForExistence(app.otherElements.staticTexts["Mozilla"], timeout: 5)

        // Remove created shortcut
        let icon = app.otherElements.containing(.staticText, identifier: "Mozilla")
        icon.otherElements["outerView"].press(forDuration: 2)
        waitForExistence(app.collectionViews.cells.buttons.firstMatch)
        snapshot("2-RemoveShortcutLongPressOnIt")
    }

//    Run it only for EN locales for now
//    func test13HomePageTipsCarrousel() {
//        dismissURLBarFocused()
//        snapshot("1stTip")
//        app.staticTexts["Select Add to Shortcuts from the Focus menu"].swipeLeft()
//        snapshot("2ndTip")
//        app.staticTexts["Site missing content or acting strange?"].swipeLeft()
//        snapshot("3rdTip")
//        app.staticTexts["Page Actions > Request Desktop Site"].swipeLeft()
//        snapshot("4thTip")
//        app.staticTexts["“Siri, open my favorite site.”"].swipeLeft()
//        snapshot("5thTip")
//        app.staticTexts["“Siri, erase my Firefox Focus session.”"].swipeLeft()
//        snapshot("6thTip")
//    }
}
