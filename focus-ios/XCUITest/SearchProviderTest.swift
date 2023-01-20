/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class SearchProviderTest: BaseTestCase {
    func testGoogleSearchProvider() {
        searchProviderTestHelper(provider: "Google")
    }

    func testDuckDuckGoSearchProvider() {
        searchProviderTestHelper(provider: "DuckDuckGo")
    }

    func testWikipediaSearchProvider() {
        searchProviderTestHelper(provider: "Wikipedia")
    }
    
    func testAmazonSearchProvider() {
        searchProviderTestHelper(provider: "Amazon.com")
    }
    
    func testSearchQuery() {
        searchQuery("test", provider: "Google")
        searchQuery("test", provider: "Amazon.com")
        searchQuery("test", provider: "DuckDuckGo")
    }
    
    func searchProviderTestHelper(provider:String) {
        changeSearchProvider(provider: provider)
        doSearch(searchWord: "mozilla", provider: provider)
        waitForWebPageLoad()

        waitForExistence(app.buttons["URLBar.deleteButton"], timeout: 5)
        app.buttons["URLBar.deleteButton"].tap()
        if !iPad() {
            waitForExistence(app.buttons["URLBar.cancelButton"], timeout: 5)
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
    }

    func testAddRemoveCustomSearchProvider() {
        dismissURLBarFocused()
        waitForExistence(app.buttons["HomeView.settingsButton"], timeout: 10)
        // Set search engine to Google
        app.buttons["HomeView.settingsButton"].tap()

        let settingsButton = app.settingsButton
        waitForExistence(settingsButton, timeout: 10)
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
        waitForExistence(app.tables.cells["MDN"].buttons["Delete MDN"])
        app.tables.cells["MDN"].buttons["Delete MDN"].tap()
        waitForExistence(app.tables.cells["MDN"].buttons["Delete"])
        app.tables.cells["MDN"].buttons["Delete"].tap()

        // leave edit mode
        app.navigationBars.buttons["edit"].tap()
    }

    func testPreventionOfRemovingDefaultSearchProvider() {
        dismissURLBarFocused()
        waitForExistence(app.buttons["HomeView.settingsButton"], timeout: 10)
        // Set search engine to Google
        app.buttons["HomeView.settingsButton"].tap()
        let settingsButton = app.settingsButton
        waitForExistence(settingsButton, timeout: 10)
        settingsButton.tap()
        waitForExistence(app.tables.cells["SettingsViewController.searchCell"], timeout: 5)
        let defaultEngineName = app.tables.cells["SettingsViewController.searchCell"].staticTexts.element(boundBy: 1).label
        app.tables.cells["SettingsViewController.searchCell"].tap()

        XCTAssertTrue(app.tables.cells["restoreDefaults"].exists)

        // enter edit mode
        app.navigationBars.buttons["edit"].tap()
        XCTAssertFalse(app.tables.cells["restoreDefaults"].exists)

        XCTAssertFalse(app.tables.cells["defaultEngineName"].buttons["Delete \(defaultEngineName)"].exists)
    }

	private func changeSearchProvider(provider: String) {
        dismissURLBarFocused()
        waitForExistence(app.buttons["HomeView.settingsButton"], timeout: 10)
        // Set search engine to Google
        app.buttons["HomeView.settingsButton"].tap()
        
        let settingsButton = app.settingsButton
        waitForExistence(settingsButton, timeout: 10)
        settingsButton.tap()
        waitForExistence(app.tables.cells["SettingsViewController.searchCell"], timeout: 5)
		app.tables.cells["SettingsViewController.searchCell"].tap()
        waitForExistence(app.tables.staticTexts[provider], timeout: 5)
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
            case "Amazon.com":
				waitForValueContains(urlbarUrltextTextField, value: "amazon.com")
                waitForValueContains(app.webViews.textFields.element(boundBy: 0),
                    value: searchWord)

			default:
				XCTFail("Invalid Search Provider")
		}
	}
}
