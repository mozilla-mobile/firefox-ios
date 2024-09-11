/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class SearchProviderTest: BaseTestCase {
    // https://mozilla.testrail.io/index.php?/cases/view/1707743
    func testGoogleSearchProvider() {
        searchProviderTestHelper(provider: "Google")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2512720
    func testDuckDuckGoSearchProvider() {
        searchProviderTestHelper(provider: "DuckDuckGo")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2512721
    func testWikipediaSearchProvider() {
        searchProviderTestHelper(provider: "Wikipedia")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2524588
    func testSearchQuery() {
        searchQuery("test", provider: "Google")
        dismissKeyboardFocusMenuSettings()
        searchQuery("test", provider: "DuckDuckGo")
    }

    private func dismissKeyboardFocusMenuSettings() {
        if !app.buttons["HomeView.settingsButton"].isHittable {
            dismissURLBarFocused()
        }
    }

    func searchProviderTestHelper(provider: String) {
        changeSearchProvider(provider: provider)
        doSearch(searchWord: "mozilla", provider: provider)
        waitForWebPageLoad()

        waitForExistence(app.buttons["URLBar.deleteButton"])
        app.buttons["URLBar.deleteButton"].tap()
        if !iPad() {
            waitForExistence(app.buttons["URLBar.cancelButton"])
            app.buttons["URLBar.cancelButton"].tap()
        }
        checkForHomeScreen()
	}

    func searchQuery(_ query: String, provider: String) {
        let urlbarUrltextTextField = app.textFields["URLBar.urlText"]
        changeSearchProvider(provider: provider)

        urlbarUrltextTextField.tap()
        urlbarUrltextTextField.typeText(query)
        app.buttons["OverlayView.searchButton"].firstMatch.tap()
        waitForWebPageLoad()

        urlbarUrltextTextField.tap()
        waitForValueContains(urlbarUrltextTextField, value: query)
        if iPad() {
            app.buttons["icon delete"].tap()
        } else {
            app.buttons["icon cancel"].tap()
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/1707744
    func testAddRemoveCustomSearchProvider() {
        dismissURLBarFocused()
        waitForExistence(app.buttons["HomeView.settingsButton"])
        // Set search engine to Google
        app.buttons["HomeView.settingsButton"].tap()

        let settingsButton = app.settingsButton
        waitForExistence(settingsButton)
        settingsButton.tap()

        waitForExistence(app.tables.cells["SettingsViewController.searchCell"])
        app.tables.cells["SettingsViewController.searchCell"].tap()
        app.tables.cells["addSearchEngine"].tap()
        app.textFields["nameInput"].tap()
        app.textFields["nameInput"].typeText("MDN")
        app.textViews["templateInput"].tap()
        app.textViews["templateInput"].typeText("https://developer.mozilla.org/en-US/search?q=%s")
        app.navigationBars.buttons["save"].tap()

        let toast = app.staticTexts["Toast.label"]
        waitForNoExistence(toast)

        waitForExistence(app.tables.cells["MDN"])
        app.tables.cells["Wikipedia"].tap()

        waitForExistence(app.tables.cells["SettingsViewController.searchCell"])
        app.tables.cells["SettingsViewController.searchCell"].tap()

        // enter edit mode
        app.navigationBars.buttons["edit"].tap()
        if #available(iOS 17, *) {
            waitForExistence(app.tables.cells["MDN"].buttons["Remove MDN"])
            app.tables.cells["MDN"].buttons["Remove MDN"].tap()
        } else {
            waitForExistence(app.tables.cells["MDN"].buttons["Delete MDN"])
            app.tables.cells["MDN"].buttons["Delete MDN"].tap()
        }
        waitForExistence(app.tables.cells["MDN"].buttons["Delete"])
        app.tables.cells["MDN"].buttons["Delete"].tap()

        // leave edit mode
        app.navigationBars.buttons["edit"].tap()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/1707745
    func testPreventionOfRemovingDefaultSearchProvider() {
        dismissURLBarFocused()
        waitForExistence(app.buttons["HomeView.settingsButton"])
        // Set search engine to Google
        app.buttons["HomeView.settingsButton"].tap()
        let settingsButton = app.settingsButton
        waitForExistence(settingsButton)
        settingsButton.tap()
        waitForExistence(app.tables.cells["SettingsViewController.searchCell"])
        let defaultEngineName = app.tables.cells["SettingsViewController.searchCell"].staticTexts.element(boundBy: 1).label
        app.tables.cells["SettingsViewController.searchCell"].tap()

        waitForExistence(app.tables.cells["restoreDefaults"])

        // enter edit mode
        app.navigationBars.buttons["edit"].tap()
        waitForNoExistence(app.tables.cells["restoreDefaults"])

        waitForNoExistence(app.tables.cells["defaultEngineName"].buttons["Delete \(defaultEngineName)"])
    }

    private func changeSearchProvider(provider: String) {
        waitForExistence(app.buttons["HomeView.settingsButton"])
        // Set search engine to Google
        app.buttons["HomeView.settingsButton"].tap()

        let settingsButton = app.settingsButton
        waitForExistence(settingsButton)
        settingsButton.tap()
        waitForExistence(app.tables.cells["SettingsViewController.searchCell"])
        app.tables.cells["SettingsViewController.searchCell"].tap()
        waitForExistence(app.tables.staticTexts[provider])
        app.tables.staticTexts[provider].tap()
        app.buttons["Done"].tap()
    }

    private func doSearch(searchWord: String, provider: String) {
        let urlbarUrltextTextField = app.textFields["URLBar.urlText"]
        let cancelButton = app.buttons["URLBar.cancelButton"]
        urlbarUrltextTextField.tap()
        urlbarUrltextTextField.typeText(searchWord)
        app.buttons["SearchSuggestionsPromptView.enableButton"].tap()
        app.buttons["OverlayView.searchButton"].firstMatch.tap()
        waitForWebPageLoad()

        // Check the correct site is reached
        switch provider {
        case "Google":
            waitForValueContains(urlbarUrltextTextField, value: "google.com")
            if app.webViews.textFields["Search"].exists {
                waitForValueContains(app.webViews.textFields["Search"], value: searchWord)
            } else if app.webViews.otherElements["Search"].exists {
                waitForValueContains(app.webViews.otherElements["Search"], value: searchWord)
            }
        case "DuckDuckGo":
            waitForValueContains(urlbarUrltextTextField, value: "duckduckgo.com")
            waitForExistence(app.otherElements["mozilla at DuckDuckGo"])
        case "Wikipedia":
            waitForValueContains(urlbarUrltextTextField, value: "wikipedia.org")
        default:
            XCTFail("Invalid Search Provider")
        }
    }
}
