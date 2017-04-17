/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class SearchProviderTest: BaseTestCase {
        
    override func setUp() {
        super.setUp()
        dismissFirstRunUI()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
		XCUIApplication().terminate()
        super.tearDown()
    }
	
    func testSearchProvider() {
		let app = XCUIApplication()
        // Removing Twitter since it seems to be blocked from BB devices
		let searchEngines = ["Google", "Yahoo", "DuckDuckGo", "Wikipedia", "Amazon.com"]
		
		for searchEngine in searchEngines {
			changeSearchProvider(provider: searchEngine)
			doSearch(searchWord: "mozilla", provider: searchEngine)
			app.buttons["ERASE"].tap()
			waitforExistence(element: app.staticTexts["Your browsing history has been erased."])
		}
	}
	
	private func changeSearchProvider(provider: String) {
		let app = XCUIApplication()
		
		app.buttons["Settings"].tap()
		app.tables.cells["SettingsViewController.searchCell"].tap()
		
		app.tables.staticTexts[provider].tap()
		app.navigationBars["Settings"].children(matching: .button).matching(identifier: "Back").element(boundBy: 0).tap()
		
	}
	
	private func doSearch(searchWord: String, provider: String) {
		let app = XCUIApplication()
		let searchForText = "Search for " + searchWord
		
		app.buttons["URLBar.activateButton"].tap()
		
		let urlbarUrltextTextField = app.textFields["URLBar.urlText"]
		urlbarUrltextTextField.tap()
		
		urlbarUrltextTextField.typeText(searchWord)
		waitforExistence(element: app.buttons[searchForText])
		app.buttons[searchForText].tap()
		
		// Check the correct site is reached
		switch provider {
			case "Google":
				waitForValueContains(element: urlbarUrltextTextField, value: "https://www.google")
				waitForValueContains(element: app.otherElements["Search"], value: searchWord)
		    case "Yahoo":
				waitForValueContains(element: urlbarUrltextTextField, value: "https://search.yahoo.com")
				waitForValueContains(element: app.otherElements["banner"].searchFields["Search"], value: searchWord)
			case "DuckDuckGo":
				waitForValueContains(element: urlbarUrltextTextField, value: "https://duckduckgo.com/?q=mozilla")
				waitforExistence(element: app.otherElements["mozilla at DuckDuckGo"])
			case "Wikipedia":
				waitForValueContains(element: urlbarUrltextTextField, value: "https://en.m.wikipedia.org/wiki/Mozilla")
            case "Amazon.com":
				waitForValueContains(element: urlbarUrltextTextField, value: "https://www.amazon")
				waitForValueContains(element: app.textFields["Search"], value: searchWord)
			default:
				XCTFail("Invalid Search Provider")
		}
	}
    
}
