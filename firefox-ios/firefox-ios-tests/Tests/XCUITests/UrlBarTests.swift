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
        browserScreen.navigateToURL("http://localhost:\(serverPort)/test-fixture/\(TestPages.findInPage)")
        waitUntilPageLoad()
        browserScreen.tapOnAddressBar()
        // The keyboard is brought up.
        browserScreen.assertAddressBarHasKeyboardFocus()
        // Tap cancel button
        browserScreen.tapCancelButtonOnUrlBarExist()
        // The keyboard is dismissed and edit mode is fully left
        browserScreen.assertAddressBarLeftEditMode()
        // The address bar is still usable afterwards
        browserScreen.assertAddressBarRegainsKeyboardFocus()
        browserScreen.tapCancelButtonOnUrlBarExist()
        browserScreen.assertAddressBarLeftEditMode()
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

    // https://mozilla.testrail.io/index.php?/cases/view/3167400
    // https://mozilla.testrail.io/index.php?/cases/view/3167424
    func testCopyURLFromAddressBar() {
        // A decoy on the pasteboard makes the assertion meaningful: if "Copy Address" silently does
        // nothing, the paste below yields the decoy instead of the page URL and the test fails.
        UIPasteboard.general.string = "decoy-clipboard-contents"

        // Open a website
        browserScreen.navigateToURL(urlExample)
        waitUntilPageLoad()

        // Long press the URL in the toolbar and copy it
        browserScreen.longPressAddressBar()
        browserScreen.tapContextMenuCopyAddress()

        // Open a new tab and paste the previously copied URL
        waitForTabsButton()
        toolbarScreen.tapOnTabsButton()
        tabTrayScreen.tapOnNewTabButton()

        // The URL is pasted without issues
        browserScreen.pasteAndAssertAddressBarContains(urlValueLongExample)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3167548
    func testClearTextInAddressBar() {
        // Tap on the address bar of a new tab
        browserScreen.tapOnAddressBar()
        browserScreen.assertAddressBarHasKeyboardFocus()

        // Start typing a search query
        browserScreen.typeOnSearchBar(text: "mozilla")
        browserScreen.assertAddressBarContains(value: "mozilla")

        // Tap the X button in the address bar
        browserScreen.clearURL()

        // The text is removed from the address bar, and it stays in edit mode so the user can keep
        // typing without tapping again.
        browserScreen.assertAddressBarContains(value: "Search or enter address")
        browserScreen.assertAddressBarHasKeyboardFocus()

        // Start typing a search query again
        browserScreen.typeOnSearchBar(text: "firefox")
        browserScreen.assertAddressBarContains(value: "firefox")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3279353
    // https://mozilla.testrail.io/index.php?/cases/view/3279354
    func testEditURLInAddressBar() {
        // Open a website
        browserScreen.navigateToURL(urlExample)
        waitUntilPageLoad()
        browserScreen.assertExampleDomainTextExists()

        // Unfocused, the toolbar shows only the domain
        browserScreen.assertAddressBarValueEquals(urlValueLong)

        // Tap on the URL bar: the full URL has to be handed over for editing, otherwise the user
        // cannot edit anything but the domain.
        browserScreen.tapOnAddressBar()
        browserScreen.assertAddressBarContains(value: urlValueLongExample)

        // Edit the URL and submit it. Tapping the address bar leaves the URL selected, so typing
        // replaces it.
        browserScreen.typeOnSearchBar(text: path(forTestPage: TestPages.mozillaBook))
        browserScreen.typeOnSearchBar(text: "\r")
        waitUntilPageLoad()

        // The webpage is correctly loaded with the newly edited website
        XCTAssertTrue(browserScreen.bookOfMozillaPageContentExists(), "The edited URL did not load")
        browserScreen.assertAddressBarValueEquals(urlValueLong)
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
