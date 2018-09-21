/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class AsianLocaleTest: BaseTestCase {
	
	override func setUp() {
		super.setUp()
		dismissFirstRunUI()
	}
	
	override func tearDown() {
		app.terminate()
		super.tearDown()
	}
 
	func testSearchinLocale() {
        // Set search engine to Google
		app.buttons["Settings"].tap()
		app.tables.cells["SettingsViewController.searchCell"].tap()
	
		app.tables.staticTexts["Google"].tap()
		app.navigationBars["Settings"].children(matching: .button).matching(identifier: "Done").element(boundBy: 0).tap()
        
		// Enter 'mozilla' on the search field
		search(searchWord: "모질라")
        app.buttons["URLBar.deleteButton"].tap()
        checkForHomeScreen()
        
		search(searchWord: "モジラ")
        app.buttons["URLBar.deleteButton"].tap()
        checkForHomeScreen()
        
		search(searchWord: "因特網")
        app.buttons["URLBar.deleteButton"].tap()
        checkForHomeScreen()
	}
	
	
}
