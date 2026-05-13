// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

class UrlBarTests: BaseTestCase {
    private var browserScreen: BrowserScreen!
    private var toolbarScreen: ToolbarScreen!
    private var mainMenuScreen: MainMenuScreen!
    private var tabTrayScreen: TabTrayScreen!
    private var settingScreen: SettingScreen!

    override func setUp() async throws {
        try await super.setUp()
        browserScreen = BrowserScreen(app: app)
        toolbarScreen = ToolbarScreen(app: app)
        mainMenuScreen = MainMenuScreen(app: app)
        tabTrayScreen = TabTrayScreen(app: app)
        settingScreen = SettingScreen(app: app)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306888
    func testNewTabUrlBar() {
        // Visit any website and select the URL bar
        browserScreen.navigateToURL("http://localhost:\(serverPort)/test-fixture/find-in-page-test.html")
        waitUntilPageLoad()
        browserScreen.tapOnAddressBar()
        // The keyboard is brought up.
        browserScreen.assertAddressBarHasKeyboardFocus()
        // Tap cancel button
        browserScreen.tapCancelButtonOnUrlBarExist()
        // The keyboard is dismissed
        XCTAssertFalse(urlBarAddress.value(forKey: "hasKeyboardFocus") as? Bool ?? true)
        // Select the tab tray and add a new tab
        waitForTabsButton()
        toolbarScreen.tapOnTabsButton()
        tabTrayScreen.tapOnNewTabButton()
        // The URL bar is empty on the new tab
        browserScreen.assertAddressBarContains(value: "Search or enter address")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306887
    func testSearchEngineLogo() {
        tapUrlBarValidateKeyboardAndIcon()
        // Type a search term and hit "go"
        typeSearchTermAndHitGo(searchTerm: "Firefox")
        // The search is conducted correctly through the default search engine
        browserScreen.assertAddressBarContains(value: "google.com")
        // Navigate to SearchSettings
        toolbarScreen.tapSettingsMenuButton()
        mainMenuScreen.tapSettings()
        settingScreen.navigateToSearchSettings()
        // Change default search engine
        let defaultSearchEngine = app.tables.cells.element(boundBy: 0)
        mozWaitForElementToExist(app.tables.cells.staticTexts[defaultSearchEngine1])
        defaultSearchEngine.waitAndTap()
        app.tables.staticTexts[defaultSearchEngine2].waitAndTap()
        mozWaitForElementToExist(app.tables.cells.staticTexts[defaultSearchEngine2])
		// Close settings and add a new tab
        settingScreen.tapBackToSettings()
        settingScreen.closeSettingsWithDoneButton()
        toolbarScreen.tapOnNewTabButton()
        tapUrlBarValidateKeyboardAndIcon()
        // Type a search term and hit "go"
        typeSearchTermAndHitGo(searchTerm: "Firefox")
        // The search is conducted correctly through the default search engine
        browserScreen.assertAddressBarContains(value: "bing.com")
    }

    private func tapUrlBarValidateKeyboardAndIcon() {
        // Tap on the URL bar
        waitForTabsButton()
        browserScreen.tapOnAddressBar()
        // The keyboard pops up and the default search icon is correctly displayed in the URL bar
        browserScreen.assertAddressBarHasKeyboardFocus()
        browserScreen.assertSearchEngineLogoExists()
    }

    private func typeSearchTermAndHitGo(searchTerm: String) {
		browserScreen.typeOnSearchBar(text: searchTerm)
        app.buttons["Go"].waitAndTap()
    }
}
