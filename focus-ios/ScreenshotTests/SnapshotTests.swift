/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class SnapshotTests: XCTestCase {

    let app = XCUIApplication()
    let testRunningFirstRun = ["test01Screenshots"]

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        // Test name looks like: "[Class testFunc]", parse out the function name
        let parts = name.replacingOccurrences(of: "]", with: "").split(separator: " ")
        let key = String(parts[1])
        if testRunningFirstRun.contains(key) {
        // for the current test name, add the db fixture used
            app.launchArguments = ["testMode"]
        } else {
            app.launchArguments = ["testMode", "disableFirstRunUI"]
        }
        setupSnapshot(app)
        app.launch()
    }

    func test01Screenshots() {
        snapshot("00FirstRun")
        app.swipeLeft()
        snapshot("01FirstRun")
        app.swipeLeft()
        snapshot("02FirstRun")
        app.buttons["IntroViewController.button"].tap()
        snapshot("03Home")

        app.textFields["URLBar.urlText"].tap()
        app.textFields["URLBar.urlText"].typeText("bugzilla.mozilla.org")
        snapshot("04SearchFor")

        app.typeText("\n")
        waitForValueContains(app.textFields["URLBar.urlText"], value: "bugzilla.mozilla.org")
        snapshot("05EraseButton")

        let searchOrEnterAddressTextField = app.textFields["URLBar.urlText"]
        searchOrEnterAddressTextField.tap()
        waitForExistence(app.buttons["URLBar.cancelButton"])
        snapshot("06AddLinkToAutoComplete")

        app.buttons["URLBar.cancelButton"].tap()
        app.buttons["URLBar.deleteButton"].tap()
        waitForExistence(app.staticTexts["Toast.label"])
        snapshot("07YourBrowsingHistoryHasBeenErased")
    }

    func test02Settings() {
        app.buttons["HomeView.settingsButton"].tap()
        snapshot("08Settings")
        app.swipeUp()
        snapshot("9Settings")
        app.swipeDown()

        app.cells["settingsViewController.trackingCell"].tap()
        snapshot("10SettingsBlockOtherContentTrackers")
        app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap()

        app.cells["SettingsViewController.searchCell"].tap()
        snapshot("11SettingsSearchEngine")
        app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap()

        app.cells["SettingsViewController.autocompleteCell"].tap()
        snapshot("12SettingsSearchEngine")
    }
    
    func test03About() {
        app.buttons["HomeView.settingsButton"].tap()
        app.cells["settingsViewController.about"].tap()
        snapshot("13About")
    }

    func test04ShareMenu() {
        app.textFields["URLBar.urlText"].tap()
        app.textFields["URLBar.urlText"].typeText("bugzilla.mozilla.org\n")
        waitForValueContains(app.textFields["URLBar.urlText"], value: "bugzilla.mozilla.org")
        app.buttons["URLBar.pageActionsButton"].tap()
        app.tables["Context Menu"].cells["icon_openwith_active"].tap()
        snapshot("14ShareMenu")
    }

    func test05SafariIntegration() {
        app.buttons["HomeView.settingsButton"].tap()
        app.tables.switches["BlockerToggle.Safari"].tap()
        snapshot("15SafariIntegrationInstructions")
    }

    func test06OpenMaps() {
        app.textFields["URLBar.urlText"].tap()
        app.textFields["URLBar.urlText"].typeText("maps.apple.com\n")
        waitForValueContains(app.textFields["URLBar.urlText"], value: "maps.apple.com")
        snapshot("16OpenMaps")
    }

    func test07OpenAppStore() {
        app.textFields["URLBar.urlText"].tap()
        app.textFields["URLBar.urlText"].typeText("itunes.apple.com\n")
        waitForValueContains(app.textFields["URLBar.urlText"], value: "itunes.apple.com")
        snapshot("17OpenAppStore")
    }

    func test08PasteAndGo() {
        // Inject a string into clipboard
        let clipboardString = "Hello world"
        UIPasteboard.general.string = clipboardString

        // Enter 'bugzilla.mozilla.org' on the search field as its URL does not change for locale.
        let searchOrEnterAddressTextField = app.textFields["URLBar.urlText"]
        searchOrEnterAddressTextField.tap()
        searchOrEnterAddressTextField.typeText("bugzilla.mozilla.org\n")

        // Check the correct site is reached
        waitForValueContains(searchOrEnterAddressTextField, value: "bugzilla.mozilla.org")

        // Tap URL field, check for paste & go menu
        searchOrEnterAddressTextField.press(forDuration: 2)
        snapshot("18PasteAndGo")
    }
    
    func test09TrackingProtection() {
        // Inject a string into clipboard
        let clipboardString = "Hello world"
        UIPasteboard.general.string = clipboardString

        // Enter 'bugzilla.mozilla.org' on the search field as its URL does not change for locale.
        let searchOrEnterAddressTextField = app.textFields["URLBar.urlText"]
        searchOrEnterAddressTextField.tap()
        searchOrEnterAddressTextField.typeText("bugzilla.mozilla.org\n")
        
        // Check the correct site is reached
        waitForExistence(app.otherElements["URLBar.trackingProtectionIcon"], timeout: 5)
        app.otherElements["URLBar.trackingProtectionIcon"].tap()
        snapshot("19TrackingProtection")
    }
    
    func test10CustomSearchEngines() {
        app.buttons["HomeView.settingsButton"].tap()
        app.cells["SettingsViewController.searchCell"].tap()
        app.cells["addSearchEngine"].tap()
        snapshot("20CustomSearchEngines")
    }

    func waitForValueContains(_ element: XCUIElement, value: String, file: String = #file, line: UInt = #line) {
            waitFor(element, with: "value CONTAINS '\(value)'", file: file, line: line)
        }

    func waitForExistence(_ element: XCUIElement, timeout: TimeInterval = 5.0, file: String = #file, line: UInt = #line) {
                waitFor(element, with: "exists == true", timeout: timeout, file: file, line: line)
    }
    
    private func waitFor(_ element: XCUIElement, with predicateString: String, description: String? = nil, timeout: TimeInterval = 5.0, file: String, line: UInt) {
            let predicate = NSPredicate(format: predicateString)
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
            let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
            if result != .completed {
                let message = description ?? "Expect predicate \(predicateString) for \(element.description)"
                self.recordFailure(withDescription: message, inFile: file, atLine: Int(line), expected: false)
            }
    }
}
