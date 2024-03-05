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

    func testAddRemoveShortcut() {
        addShortcut(website: "mozilla.org")

        // Tap on erase button to go to homepage and check the shortcut created
        app.eraseButton.tap()

        // Verify the shortcut is created
        XCTAssertTrue(app.otherElements.staticTexts["Mozilla"].exists)

        // Remove created shortcut
        app.otherElements["outerView"].press(forDuration: 2)
        waitForExistence(app.collectionViews.cells.buttons["Remove from Shortcuts"])
        app.collectionViews.cells.buttons["Remove from Shortcuts"].tap()
        waitForNoExistence(app.otherElements.staticTexts["Mozilla"])
        XCTAssertFalse(app.otherElements.staticTexts["Mozilla"].exists)
    }

    func testAddRenameShortcut() {
        addShortcut(website: "mozilla.org")

        // Tap on erase button to go to homepage and check the shortcut created
        app.eraseButton.tap()

        // Verify the shortcut is created
        XCTAssertTrue(app.otherElements.staticTexts["Mozilla"].exists)

        // Rename shortcut
        app.otherElements["outerView"].press(forDuration: 2)
        waitForExistence(app.collectionViews.cells.buttons["Rename Shortcut"])
        app.collectionViews.cells.buttons["Rename Shortcut"].tap()
        let textField = app.alerts.textFields.element
        textField.clearAndEnterText(text: "Cheese")
        app.alerts.buttons["Save"].tap()

        waitForExistence(app.otherElements.staticTexts["Cheese"])
        XCTAssertTrue(app.otherElements.staticTexts["Cheese"].exists)
    }

    func testShortcutShownWhileTypingURLBar() {
        addShortcut(website: "example.com")
        app.urlTextField.tap()
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
