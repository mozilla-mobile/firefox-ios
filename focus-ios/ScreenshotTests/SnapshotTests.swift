/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class SnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }

    func test01Screenshots() {
        let app = XCUIApplication()
        snapshot("00FirstRun")
        app.buttons["FirstRunViewController.button"].tap()

        snapshot("01Home")

        snapshot("02LocationBarEmptyState")
        app.textFields["URLBar.urlText"].typeText("bugzilla.mozilla.org")
        snapshot("03SearchFor")

        app.typeText("\n")
        waitForValueContains(element: app.textFields["URLBar.urlText"], value: "https://bugzilla.mozilla.org/")
        snapshot("04EraseButton")

        app.buttons["URLBar.deleteButton"].tap()
        waitforExistence(element: app.staticTexts["Toast.label"])
        snapshot("05YourBrowsingHistoryHasBeenErased")
    }

    func test02Settings() {
        let app = XCUIApplication()
        app.buttons["HomeView.settingsButton"].tap()
        snapshot("06Settings")
        app.swipeUp()
        snapshot("07Settings")
        app.swipeDown()
        app.cells["SettingsViewController.searchCell"].tap()
        snapshot("08SettingsSearchEngine")
        app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap()
        app.swipeUp()
        app.switches["BlockerToggle.BlockOther"].tap()
        snapshot("09SettingsBlockOtherContentTrackers")
    }
    
    func test03About() {
        let app = XCUIApplication()
        app.buttons["HomeView.settingsButton"].tap()
        app.cells["settingsViewController.about"].tap()
        snapshot("10About")
        app.swipeUp()
        snapshot("11About")
    }

    func test04ShareMenu() {
        let app = XCUIApplication()
        app.textFields["URLBar.urlText"].typeText("bugzilla.mozilla.org\n")
        waitForValueContains(element: app.textFields["URLBar.urlText"], value: "https://bugzilla.mozilla.org/")
        app.buttons["BrowserToolset.sendButton"].tap()
        snapshot("12ShareMenu")
    }

    func test05SafariIntegration() {
        let app = XCUIApplication()
        app.buttons["HomeView.settingsButton"].tap()
        app.tables.switches["BlockerToggle.Safari"].tap()
        snapshot("13SafariIntegrationInstructions")
    }

    func test06OpenMaps() {
        let app = XCUIApplication()
        app.textFields["URLBar.urlText"].typeText("maps.apple.com\n")
        waitForValueContains(element: app.textFields["URLBar.urlText"], value: "http://maps.apple.com")
        snapshot("06OpenMaps")
    }

    func test07OpenAppStore() {
        let app = XCUIApplication()
        app.textFields["URLBar.urlText"].typeText("itunes.apple.com\n")
        waitForValueContains(element: app.textFields["URLBar.urlText"], value: "http://itunes.apple.com")
        snapshot("07OpenAppStore")
    }

    func test08PasteAndGo() {
        let app = XCUIApplication()
        // Inject a string into clipboard
        let clipboardString = "Hello world"
        UIPasteboard.general.string = clipboardString

        // Enter 'mozilla' on the search field
        let searchOrEnterAddressTextField = app.textFields["URLBar.urlText"]
        searchOrEnterAddressTextField.typeText("mozilla.org\n")

        // Check the correct site is reached
        waitForValueContains(element: searchOrEnterAddressTextField, value: "https://www.mozilla.org/")

        // Tap URL field, check for paste & go menu
        searchOrEnterAddressTextField.tap()
        searchOrEnterAddressTextField.press(forDuration: 1.5)
        expectation(for: NSPredicate(format: "count > 0"), evaluatedWith: app.menuItems, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)

        app.menuItems.element(boundBy: 3).tap()

        snapshot("08PasteAndGo")
    }

    func waitForValueContains(element:XCUIElement, value:String, file: String = #file, line: UInt = #line) {
        let predicateText = "value CONTAINS " + "'" + value + "'"
        let valueCheck = NSPredicate(format: predicateText)

        expectation(for: valueCheck, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: 20) {(error) -> Void in
            if (error != nil) {
                let message = "Failed to find \(element) after 20 seconds."
                self.recordFailure(withDescription: message,
                                   inFile: file, atLine: line, expected: true)
            }
        }
    }

    func waitforExistence(element: XCUIElement, file: String = #file, line: UInt = #line) {
        let exists = NSPredicate(format: "exists == true")

        expectation(for: exists, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: 20) {(error) -> Void in
            if (error != nil) {
                let message = "Failed to find \(element) after 20 seconds."
                self.recordFailure(withDescription: message,
                                   inFile: file, atLine: line, expected: true)
            }
        }
    }
}
