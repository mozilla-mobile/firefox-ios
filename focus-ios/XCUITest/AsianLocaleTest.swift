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
		XCUIApplication().terminate()
		super.tearDown()
	}
 
	func testSearchinLocale() {
		let app = XCUIApplication()
		
		// Set search engine to Google
		app.buttons["Settings"].tap()
		app.tables.cells["SettingsViewController.searchCell"].tap()
	
		app.tables.staticTexts["Google"].tap()
		app.navigationBars["Settings"].children(matching: .button).matching(identifier: "Back").element(boundBy: 0).tap()
		
		waitforExistence(element: app.buttons["Search or enter address"])
		
		// Enter 'mozilla' on the search field
		search(searchWord: "모질라")
		search(searchWord: "モジラ")
		search(searchWord: "因特網")
	}
	
	func search(searchWord: String) {
		let app = XCUIApplication()
		
		app.buttons["Search or enter address"].tap()
		let searchOrEnterAddressTextField = app.textFields["Search or enter address"]
		XCTAssertTrue(searchOrEnterAddressTextField.exists)
		XCTAssertTrue(searchOrEnterAddressTextField.isEnabled)
		
		// Check the text autocompletes to mozilla.org/, and also look for 'Search for mozilla' button below
		searchOrEnterAddressTextField.typeText(searchWord)
		waitforExistence(element: app.buttons["Search for " + searchWord])
		app.buttons["Search for " + searchWord].tap()
		
		// Check the correct site is reached
		waitForValueContains(element: app.otherElements["Search"], value: searchWord)
		
		// Erase the history
		app.buttons["ERASE"].tap()
		waitforExistence(element: app.staticTexts["Your browsing history has been erased."])
		
		// Check it is on the initial page
		XCTAssertTrue(app.staticTexts["Browse. Erase. Repeat."].exists)
		XCTAssertTrue(app.staticTexts["Automatic private browsing."].exists)
	}
}
