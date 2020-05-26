/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let testPageBase = "http://www.example.com"
let loremIpsumURL = "\(testPageBase)"

class L10nSuite2SnapshotTests: L10nBaseSnapshotTests {
    func test1DefaultTopSites() {
        navigator.toggleOff(userState.pocketInNewTab, withAction: Action.TogglePocketInNewTab)
        navigator.goto(HomePanelsScreen)
        snapshot("DefaultTopSites-01")
        navigator.toggleOn(userState.pocketInNewTab, withAction: Action.TogglePocketInNewTab)
        navigator.goto(HomePanelsScreen)
        snapshot("DefaultTopSites-with-pocket-02")
    }

    func test2MenuOnTopSites() {
        navigator.goto(NewTabScreen)
        navigator.goto(BrowserTabMenu)
        snapshot("MenuOnTopSites-01")
    }

    func test3Settings() {
        let table = app.tables.element(boundBy: 0)
        navigator.goto(SettingsScreen)
        table.forEachScreen { i in
            snapshot("Settings-main-\(i)")
        }

        allSettingsScreens.forEach { nodeName in
            self.navigator.goto(nodeName)
            table.forEachScreen { i in
                snapshot("Settings-\(nodeName)-\(i)")
            }
        }
    }

    func test4PrivateBrowsingTabsEmptyState() {
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        snapshot("PrivateBrowsingTabsEmptyState-01")
    }

    func test5PanelsEmptyState() {
        let libraryPanels = [
            "LibraryPanels.History",
            "LibraryPanels.ReadingList",
            "LibraryPanels.Downloads",
            "LibraryPanels.SyncedTabs"
        ]
        navigator.goto(LibraryPanel_Bookmarks)
        snapshot("PanelsEmptyState-LibraryPanels.Bookmarks")
        libraryPanels.forEach { panel in
            app.buttons[panel].tap()
            snapshot("PanelsEmptyState-\(panel)")
        }
    }

    // From here on it is fine to load pages
    func test6LongPressOnTextOptions() {
        navigator.openURL(loremIpsumURL)

        // Select some text and long press to find the option
        app.webViews.element(boundBy: 0).staticTexts.element(boundBy: 0).press(forDuration: 1)
        snapshot("LongPressTextOptions-01")
        if(app.menuItems["show.next.items.menu.button"].exists) {
            app.menuItems["show.next.items.menu.button"].tap()
            snapshot("LongPressTextOptions-02")
        }
    }

    func test7URLBar() {
        navigator.goto(URLBarOpen)
        snapshot("URLBar-01")

        userState.url = "moz"
        navigator.performAction(Action.SetURLByTyping)
        snapshot("URLBar-02")
    }

    func test8URLBarContextMenu() {
        // Long press with nothing on the clipboard
        navigator.goto(URLBarLongPressMenu)
        snapshot("LocationBarContextMenu-01-no-url")
        navigator.back()

        // Long press with a URL on the clipboard
        UIPasteboard.general.string = "https://www.mozilla.com"
        navigator.goto(URLBarLongPressMenu)
        snapshot("LocationBarContextMenu-02-with-url")
    }

    func test10MenuOnWebPage() {
        navigator.openURL(loremIpsumURL)
        navigator.goto(BrowserTabMenu)
        snapshot("MenuOnWebPage-01")
        navigator.back()

        navigator.toggleOn(userState.noImageMode, withAction: Action.ToggleNoImageMode)
        navigator.toggleOn(userState.nightMode, withAction: Action.ToggleNightMode)
        navigator.goto(BrowserTabMenu)
        snapshot("MenuOnWebPage-02")
        navigator.back()
    }

    func test10PageMenuOnWebPage() {
           navigator.goto(PageOptionsMenu)
           snapshot("MenuOnWebPage-03")
           navigator.back()
       }

    func test11FxASignInPage() {
        navigator.goto(Intro_FxASignin)
        waitForExistence(app.navigationBars["Turn on Sync"])
        snapshot("FxASignInScreen-01")
    }
}
