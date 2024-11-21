// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class UrlBarTests: BaseTestCase {
    // https://mozilla.testrail.io/index.php?/cases/view/2306888
    func testNewTabUrlBar() {
        // Visit any website and select the URL bar
        navigator.openURL("http://localhost:\(serverPort)/test-fixture/find-in-page-test.html")
        waitUntilPageLoad()
        app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].tap()
        // The keyboard is brought up.
        XCTAssertTrue(urlBarAddress.value(forKey: "hasKeyboardFocus") as? Bool ?? false)
        // Scroll on the page
        app.swipeUp()
        // The keyboard is dismissed
        XCTAssertFalse(urlBarAddress.value(forKey: "hasKeyboardFocus") as? Bool ?? true)
        // Select the tab tray and add a new tab
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        // The URL bar is empty on the new tab
        let url = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
        XCTAssertEqual(url.value as? String, "Search or enter address")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306887
    func testSearchEngineLogo() {
        tapUrlBarValidateKeyboardAndIcon()
        // Type a search term and hit "go"
        typeSearchTermAndHitGo(searchTerm: "Firefox")
        // The search is conducted correctly trough the default search engine
        mozWaitForValueContains(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField], value: "google.com")
        // Add a custom search engine and add it as default search engine
        navigator.goto(SearchSettings)
        let defaultSearchEngine = app.tables.cells.element(boundBy: 0)
        mozWaitForElementToExist(app.tables.cells.staticTexts[defaultSearchEngine1])
        defaultSearchEngine.tap()
        app.tables.staticTexts[defaultSearchEngine2].tap()
        mozWaitForElementToExist(app.tables.cells.staticTexts[defaultSearchEngine2])
        navigator.goto(SettingsScreen)
        app.navigationBars.buttons["Done"].tap()
        app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton].tap()
        tapUrlBarValidateKeyboardAndIcon()
        typeSearchTermAndHitGo(searchTerm: "Firefox")
        // The search is conducted correctly trough the default search engine
        mozWaitForValueContains(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField], value: "bing.com")
    }

    private func tapUrlBarValidateKeyboardAndIcon() {
        // Tap on the URL bar
        waitForTabsButton()
        app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].tap()
        // The keyboard pops up and the default search icon is correctly displayed in the URL bar
        XCTAssertTrue(urlBarAddress.value(forKey: "hasKeyboardFocus") as? Bool ?? false)
        let keyboardCount = app.keyboards.count
        XCTAssert(keyboardCount > 0, "The keyboard is not shown")
        let searchEngineLogo = app.images[AccessibilityIdentifiers.Browser.AddressToolbar.searchEngine]
        mozWaitForElementToExist(searchEngineLogo)
        XCTAssertTrue(searchEngineLogo.isLeftOf(rightElement: urlBarAddress))
    }

    private func typeSearchTermAndHitGo(searchTerm: String) {
        urlBarAddress.typeText(searchTerm)
        waitUntilPageLoad()
        app.buttons["Go"].waitAndTap()
    }
}
