/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class SnapshotTests: BaseTestCaseL10n {

    func test01FirstRunScreens() {
        snapshot("00FirstRun")
        app.swipeLeft()
        snapshot("01FirstRun")
        app.swipeLeft()
        snapshot("02FirstRun")
        waitForExistence(app.buttons["IntroViewController.button"], timeout: 15)
        app.buttons["IntroViewController.button"].tap()
        snapshot("03Home")
    }

    func test02Settings() {
        dismissURLBarFocused()
        app.buttons["HomeView.settingsButton"].tap()
        app.tables.cells["icon_settings"].tap()
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
        app.buttons["HomeView.settingsButton"].tap()
        app.tables.cells["icon_settings"].tap()
        waitForExistence(app.cells["settingsViewController.about"])
        app.cells["settingsViewController.about"].tap()
        snapshot("13About")
    }

    func test04ShareMenu() {
        app.textFields["URLBar.urlText"].tap()
        app.textFields["URLBar.urlText"].typeText("bugzilla.mozilla.org\n")
        waitForValueContains(app.textFields["URLBar.urlText"], value: "bugzilla.mozilla.org")
        app.buttons["HomeView.settingsButton"].tap()
        snapshot("WebsiteSettingsMenu")
        waitForExistence(app.cells["icon_shortcuts_add"])
        app.tables.cells["icon_shortcuts_add"].tap()
        waitForExistence(app.buttons["HomeView.settingsButton"])
        app.buttons["HomeView.settingsButton"].tap()
        waitForExistence(app.tables["Context Menu"].cells["icon_openwith_active"])
        snapshot("WebsiteSettingsMenu-RemovePin")
        app.tables["Context Menu"].cells["icon_openwith_active"].tap()
        snapshot("14ShareMenu")
    }

    func test05SafariIntegration() {
        dismissURLBarFocused()
        app.buttons["HomeView.settingsButton"].tap()
        app.tables.cells["icon_settings"].tap()
        waitForExistence(app.tables.switches["BlockerToggle.Safari"])
        app.tables.switches["BlockerToggle.Safari"].tap()
        snapshot("15SafariIntegrationInstructions")
    }

    func test06OpenMaps() {
        app.textFields["URLBar.urlText"].tap()
        app.textFields["URLBar.urlText"].typeText("maps.apple.com\n")
        waitForValueContains(app.textFields["URLBar.urlText"], value: "maps.apple.com")
        snapshot("16OpenMaps")
    }

    func test07OpenAppStore() {
        app.textFields["URLBar.urlText"].tap()
        app.textFields["URLBar.urlText"].typeText("itunes.apple.com\n")
        waitForValueContains(app.textFields["URLBar.urlText"], value: "itunes.apple.com")
        snapshot("17OpenAppStore")
    }

    func test08PasteAndGo() {
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
        app.tables.cells["icon_settings"].tap()
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
        app.textFields.firstMatch.typeText("bugzilla.mozilla.org")
        snapshot("04SearchFor")

        app.typeText("\n")
        waitForValueContains(app.textFields["URLBar.urlText"], value: "bugzilla.mozilla.org")
        app.buttons["URLBar.deleteButton"].tap()
        snapshot("07YourBrowsingHistoryHasBeenErased")
    }

//    func testPinUnpinMenus() {
//        app.textFields["URLBar.urlText"].tap()
//        app.textFields["URLBar.urlText"].typeText("example.com\n")
//        waitForExistence(app.buttons["HomeView.settingsButton"])
//        app.buttons["HomeView.settingsButton"].tap()
//        waitForExistence(app.cells["icon_shortcuts_add"])
//        app.tables.cells["icon_shortcuts_add"].tap()
//        snapshot("Pin-site-menu")
//        app.buttons["HomeView.settingsButton"].tap()
//        waitForExistence(app.cells["icon_shortcuts_remove"])
//        snapshot("Unpin-site-menu")
//    }

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
