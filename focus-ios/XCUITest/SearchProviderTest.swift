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
		app.terminate()
        super.tearDown()
    }
	
    func testSearchProvider() {
		// Removing Twitter since it seems to be blocked from BB devices
		let searchEngines = ["Google", "Yahoo", "DuckDuckGo", "Wikipedia", "Amazon.com"]
		
		for searchEngine in searchEngines {
			changeSearchProvider(provider: searchEngine)
			doSearch(searchWord: "mozilla", provider: searchEngine)
            waitforEnable(element: app.buttons["ERASE"])
			app.buttons["ERASE"].tap()

            // Disabling this check since BB seem to intermittently miss this popup which disappears after 1~2 seconds
            // The popup is also checked in PastenGOTest
            //waitforExistence(element: app.staticTexts["Your browsing history has been erased."])
            waitforExistence(element: app.staticTexts["Browse. Erase. Repeat."])
            waitforExistence(element: app.staticTexts["Automatic private browsing."])
		}
	}
    
    func testAddRemoveCustomSearchProvider() {
        app.buttons["Settings"].tap()
        app.tables.cells["SettingsViewController.searchCell"].tap()
        app.tables.cells["addSearchEngine"].tap()
        
        app.textFields["nameInput"].typeText("MDN")
        app.textViews["templateInput"].tap()
        app.textViews["templateInput"].typeText("https://developer.mozilla.org/en-US/search?q=%s")
        app.navigationBars.buttons["save"].tap()

        let toast = app.staticTexts["Toast.label"]
        waitforNoExistence(element: toast)

        XCTAssertTrue(app.tables.cells["MDN"].exists)
        app.tables.cells["Wikipedia"].tap()
        
        waitforExistence(element: app.tables.cells["SettingsViewController.searchCell"])
        app.tables.cells["SettingsViewController.searchCell"].tap()
        
        // enter edit mode
        app.navigationBars.buttons["edit"].tap()
        app.tables.cells["MDN"].buttons["Delete MDN"].tap()
        app.tables.cells["MDN"].buttons["Delete"].tap()
        
        // leave edit mode
        app.navigationBars.buttons["edit"].tap()
    }
    
    func testPreventionOfRemovingDefaultSearchProvider() {
        app.buttons["Settings"].tap()
        let defaultEngineName = app.tables.cells["SettingsViewController.searchCell"].staticTexts.element(boundBy: 1).label
        app.tables.cells["SettingsViewController.searchCell"].tap()
        
        XCTAssertTrue(app.tables.cells["restoreDefaults"].exists)
        
        // enter edit mode
        app.navigationBars.buttons["edit"].tap()
        XCTAssertFalse(app.tables.cells["restoreDefaults"].exists)
        
        XCTAssertFalse(app.tables.cells["defaultEngineName"].buttons["Delete \(defaultEngineName)"].exists)
    }
	
	private func changeSearchProvider(provider: String) {
		
		app.buttons["Settings"].tap()
		app.tables.cells["SettingsViewController.searchCell"].tap()
		
		app.tables.staticTexts[provider].tap()
		app.navigationBars["Settings"].children(matching: .button).matching(identifier: "Back").element(boundBy: 0).tap()
		
	}
	
	private func doSearch(searchWord: String, provider: String) {
		let searchForText = "Search for " + searchWord
        let urlbarUrltextTextField = app.textFields["URLBar.urlText"]
		urlbarUrltextTextField.tap()
		
		urlbarUrltextTextField.typeText(searchWord)
		waitforExistence(element: app.buttons[searchForText])
		app.buttons[searchForText].tap()
        waitForWebPageLoad()
		
		// Check the correct site is reached
		switch provider {
			case "Google":
                waitForValueContains(element: urlbarUrltextTextField, value: "https://www.google")
                if app.webViews.textFields["Search"].exists {
                    waitForValueContains(element: app.webViews.textFields["Search"], value: searchWord)
                } else if app.webViews.otherElements["Search"].exists {
                    waitForValueContains(element: app.webViews.otherElements["Search"], value: searchWord)
                }
            case "Yahoo":
				waitForValueContains(element: urlbarUrltextTextField, value: "https://search.yahoo.com")
                
                if app.otherElements["banner"].searchFields["Search"].exists {
                   waitForValueContains(element: app.otherElements["banner"].searchFields["Search"], value: searchWord)
                } else if app.webViews.otherElements[searchWord + " - - Yahoo Search Results"].exists {
                    XCTAssertTrue(true)
                }
           case "DuckDuckGo":
				waitForValueContains(element: urlbarUrltextTextField, value: "https://duckduckgo.com/?q=mozilla")
				waitforExistence(element: app.otherElements["mozilla at DuckDuckGo"])
			case "Wikipedia":
				waitForValueContains(element: urlbarUrltextTextField, value: "https://en.m.wikipedia.org/wiki/Mozilla")
            case "Amazon.com":
				waitForValueContains(element: urlbarUrltextTextField, value: "https://www.amazon")
                waitForValueContains(element: app.webViews.textFields["Type search keywords"],
                    value: searchWord)
            
			default:
				XCTFail("Invalid Search Provider")
		}
	}
    
}
