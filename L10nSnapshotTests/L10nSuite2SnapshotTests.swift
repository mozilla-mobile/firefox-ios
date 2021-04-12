/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class L10nSuite2SnapshotTests: L10nBaseSnapshotTests {

    func testPanelsEmptyState() {
        let libraryPanels = [
                "LibraryPanels.History",
                "LibraryPanels.ReadingList",
                "LibraryPanels.Downloads",
                "LibraryPanels.SyncedTabs"
            ]
            app.buttons["urlBar-cancel"].tap()
            navigator.goto(LibraryPanel_Bookmarks)
            snapshot("PanelsEmptyState-LibraryPanels.Bookmarks")
            libraryPanels.forEach { panel in
                app.buttons[panel].tap()
                snapshot("PanelsEmptyState-\(panel)")
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
        navigator.toggleOn(userState.nightMode, withAction: Action.ToggleNightMode)
        navigator.goto(BrowserTabMenu)
        snapshot("MenuOnWebPage-02")
        navigator.back()
    }

    func testPageMenuOnWebPage() {
        navigator.goto(BrowserTab)
        waitForNoExistence(app.staticTexts["XCUITests-Runner pasted from Fennec"])
        waitForExistence(app.buttons["TabLocationView.pageOptionsButton"], timeout: 15)
        navigator.goto(PageOptionsMenu)
        snapshot("MenuOnWebPage-03")
        navigator.back()
    }

    func testFxASignInPage() {
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 5)
        app.buttons["urlBar-cancel"].tap()
        navigator.nowAt(NewTabScreen)
        navigator.goto(BrowserTabMenu)
        waitForExistence(app.tables.cells["menu-sync"], timeout: 5)
        navigator.goto(Intro_FxASignin)
        waitForExistence(app.navigationBars.staticTexts["FxASingin.navBar"], timeout: 10)
        snapshot("FxASignInScreen-01")
    }
}
