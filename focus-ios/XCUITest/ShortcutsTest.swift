/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class ShortcutsTest: BaseTestCase {

    override func tearDown() {
        XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        super.tearDown()
    }

    func testAddRemoveShortCut() {
        addShortcut(website: "mozilla.org")

        // Tap on erase button to go to homepage and check the shortcut created
        app.eraseButton.tap()

        // Verify the shortcut is created
        waitForExistence(app.otherElements.staticTexts["M"], timeout: 5)
        XCTAssertTrue(app.otherElements.staticTexts["Mozilla"].exists)

        // Remove created shortcut
        app.otherElements.staticTexts["M"].press(forDuration: 2)
        waitForExistence(app.collectionViews.cells.buttons["Remove from Shortcuts"])
        app.collectionViews.cells.buttons["Remove from Shortcuts"].tap()
        waitForNoExistence(app.otherElements.staticTexts["M"])
        XCTAssertFalse(app.otherElements.staticTexts["Mozilla"].exists)
    }

    func testAdd4Shortcuts() {
        addShortcut(website: "mozilla.org")
//        addShortcut(website: "example.com")
//        addShortcut(website: "pocket.com")
//        addShortcut(website: "wikipedia.com")

        // Tap on erase button to go to homepage and check the shortcut created
        app.eraseButton.tap()

        // Verify the shortcut is created
        waitForExistence(app.otherElements.staticTexts["M"], timeout: 5)
        XCTAssertTrue(app.otherElements.staticTexts["Mozilla"].exists)
        // XCTAssertTrue(app.otherElements.staticTexts["Example"].exists)
        // XCTAssertTrue(app.otherElements.staticTexts["Getpocket"].exists)
        // XCTAssertTrue(app.otherElements.staticTexts["Wikipedia"].exists)

        // Change device orientation
        XCUIDevice.shared.orientation = UIDeviceOrientation.landscapeLeft
        // Verify the shortcut is created
        waitForExistence(app.otherElements.staticTexts["M"], timeout: 5)
        XCTAssertTrue(app.otherElements.staticTexts["Mozilla"].exists)
        // XCTAssertTrue(app.otherElements.staticTexts["Example"].exists)
        // XCTAssertTrue(app.otherElements.staticTexts["Getpocket"].exists)
        // XCTAssertTrue(app.otherElements.staticTexts["Wikipedia"].exists)
    }

    func testShortcutShownWhileTypingURLBar() {
        addShortcut(website: "example.com")
        app.urlTextField.tap()
        waitForExistence(app.otherElements.staticTexts["E"], timeout: 5)
        XCTAssertTrue(app.otherElements.staticTexts["Example"].exists)

        app.urlTextField.typeText("foo")
        waitForNoExistence(app.otherElements.staticTexts["E"])
        XCTAssertFalse(app.otherElements.staticTexts["Example"].exists)
    }

    private func addShortcut(website: String) {
        loadWebPage(website)
        waitForWebPageLoad()

        // Tap on shortcuts settings menu option
        waitForExistence(app.buttons["HomeView.settingsButton"], timeout: 15)
        app.buttons["HomeView.settingsButton"].tap()
        if iPad() {
            waitForExistence(app.collectionViews.cells.element(boundBy: 0))
            app.collectionViews.cells.element(boundBy: 0).tap()
        } else {
            waitForExistence(app.collectionViews.cells.buttons["Add to Shortcuts"])
            app.collectionViews.cells.buttons["Add to Shortcuts"].tap()
        }
        waitForNoExistence(app.collectionViews.cells.buttons.element(boundBy: 0))
    }
}
