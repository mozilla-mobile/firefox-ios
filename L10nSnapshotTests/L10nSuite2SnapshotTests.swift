// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest

class L10nSuite2SnapshotTests: L10nBaseSnapshotTests {

    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    func testPanelsEmptyState() {
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 15)
        app.buttons["urlBar-cancel"].tap()
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], timeout: 10)
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_Bookmarks)
        snapshot("PanelsEmptyState-LibraryPanels.Bookmarks")
        // Tap on each of the library buttons
        for i in 1...3 {
            app.segmentedControls["librarySegmentControl"].buttons.element(boundBy: i).tap()
            snapshot("PanelsEmptyState-\(i)")
        }
    }

    // From here on it is fine to load pages
    func testLongPressOnTextOptions() {
        navigator.openURL(loremIpsumURL)
        waitUntilPageLoad()
        waitForNoExistence(app.staticTexts["XCUITests-Runner pasted from Fennec"])

        // Select some text and long press to find the option
        waitForExistence(app.webViews.element(boundBy: 0).staticTexts.element(boundBy: 0), timeout: 10)
        app.webViews.element(boundBy: 0).staticTexts.element(boundBy: 0).press(forDuration: 1)
        snapshot("LongPressTextOptions-01")
        if(app.menuItems["show.next.items.menu.button"].exists) {
            app.menuItems["show.next.items.menu.button"].tap()
            snapshot("LongPressTextOptions-02")
        }
    }

    func testURLBar() {
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 15)
        navigator.goto(URLBarOpen)
        snapshot("URLBar-01")

        userState.url = "moz"
        navigator.performAction(Action.SetURLByTyping)
        snapshot("URLBar-02")
    }

    func testURLBarContextMenu() {
        // Long press with nothing on the clipboard
        navigator.goto(URLBarLongPressMenu)
        snapshot("LocationBarContextMenu-01-no-url")
        navigator.back()

        // Long press with a URL on the clipboard
        UIPasteboard.general.string = "https://www.mozilla.com"
        navigator.goto(URLBarLongPressMenu)
        snapshot("LocationBarContextMenu-02-with-url")
    }

    func testMenuOnWebPage() {
        navigator.openURL(loremIpsumURL)
        waitForNoExistence(app.staticTexts["XCUITests-Runner pasted from Fennec"])
        navigator.goto(BrowserTabMenu)
        snapshot("MenuOnWebPage-01")
        navigator.back()

        navigator.toggleOn(userState.noImageMode, withAction: Action.ToggleNoImageMode)
        
        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenu)
        snapshot("MenuOnWebPage-02")
        navigator.toggleOn(userState.nightMode, withAction: Action.ToggleNightMode)

        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenu)
        snapshot("MenuOnWebPage-03")
        navigator.back()
    }

    func testPageMenuOnWebPage() {
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 15)
        app.buttons["urlBar-cancel"].tap()
        navigator.goto(BrowserTab)
        waitForNoExistence(app.staticTexts["XCUITests-Runner pasted from Fennec"])
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], timeout: 15)
        navigator.goto(PageOptionsMenu)
        snapshot("MenuOnWebPage-03")
        navigator.back()
    }

    func testFxASignInPage() {
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 15)
        app.buttons["urlBar-cancel"].tap()
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], timeout: 10)
        navigator.nowAt(NewTabScreen)
        navigator.goto(BrowserTabMenu)
        waitForExistence(app.tables.cells[ImageIdentifiers.sync], timeout: 5)
        navigator.goto(Intro_FxASignin)
        waitForExistence(app.navigationBars.staticTexts["FxASingin.navBar"], timeout: 10)
        snapshot("FxASignInScreen-01")
    }

    private func typePasscode(n: Int, keyNumber: Int) {
        for _ in 1...n {
            app.keys.element(boundBy: keyNumber).tap()
            sleep(1)
        }
    }

    func testLoginDetails() {
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 15)
        app.buttons["urlBar-cancel"].tap()
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)
        waitForExistence(app.cells["Search"], timeout: 5)
        app.cells["Search"].swipeUp()
        waitForExistence(app.cells["Logins"], timeout: 15)
        app.cells["Logins"].tap()

        waitForExistence(app.navigationBars.buttons.firstMatch, timeout: 15)
        app.otherElements.buttons.element(boundBy: 2).tap()

        let passcodeInput = springboard.secureTextFields.firstMatch
        waitForExistence(passcodeInput, timeout: 20)
        passcodeInput.tap()
        passcodeInput.typeText("foo\n")

        waitForExistence(app.tables["Login List"], timeout: 10)
        app.buttons.element(boundBy: 1).tap()
        waitForExistence(app.tables["Add Credential"], timeout: 10)
        snapshot("CreateLogin")
        app.tables["Add Credential"].cells.element(boundBy: 0).tap()
        app.keyboards.keys.element(boundBy: 3).tap()
        app.tables["Add Credential"].cells.element(boundBy: 1).tap()
        app.keyboards.keys.element(boundBy: 3).tap()
        app.tables["Add Credential"].cells.element(boundBy: 2).tap()
        app.keyboards.keys.element(boundBy: 3).tap()
        app.navigationBars["Client.AddCredentialView"].buttons.element(boundBy: 1).tap()

        waitForExistence(app.tables["Login List"],timeout: 15)
        snapshot("CreatedLoginView")

        app.tables["Login List"].cells.element(boundBy: 2).tap()
        snapshot("CreatedLoginDetailedView")

        app.tables["Login Detail List"].cells.element(boundBy: 5).tap()
        snapshot("RemoveLoginDetailedView")
    }
}
