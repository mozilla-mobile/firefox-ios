/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let testPageBase = "http://www.example.com"
let loremIpsumURL = "\(testPageBase)"

class L10nSuite2SnapshotTests: L10nBaseSnapshotTests {
    func test21DefaultTopSites() {
        navigator.toggleOff(userState.pocketInNewTab, withAction: Action.TogglePocketInNewTab)
        navigator.goto(HomePanelsScreen)
        snapshot("21DefaultTopSites-01")
        navigator.toggleOn(userState.pocketInNewTab, withAction: Action.TogglePocketInNewTab)
        navigator.goto(HomePanelsScreen)
        snapshot("21DefaultTopSites-with-pocket-02")
    }

    func test22MenuOnTopSites() {
        navigator.goto(NewTabScreen)
        navigator.goto(BrowserTabMenu)
        snapshot("22MenuOnTopSites-01")
    }

    func test23Settings() {
        let table = app.tables.element(boundBy: 0)
        navigator.goto(SettingsScreen)
        table.forEachScreen { i in
            snapshot("23Settings-main-\(i)")
        }

        allSettingsScreens.forEach { nodeName in
            self.navigator.goto(nodeName)
            table.forEachScreen { i in
                snapshot("23Settings-\(nodeName)-\(i)")
            }
        }
    }

    func test24PrivateBrowsingTabsEmptyState() {
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        snapshot("24PrivateBrowsingTabsEmptyState-01")
    }

    func test25PanelsEmptyState() {
        let libraryPanels = [
            "LibraryPanels.History",
            "LibraryPanels.ReadingList",
            "LibraryPanels.Downloads",
            "LibraryPanels.SyncedTabs"
        ]
        navigator.goto(LibraryPanel_Bookmarks)
        snapshot("25PanelsEmptyState-LibraryPanels.Bookmarks")
        libraryPanels.forEach { panel in
            app.buttons[panel].tap()
            snapshot("25PanelsEmptyState-\(panel)")
        }
    }

    // From here on it is fine to load pages
    func test26LongPressOnTextOptions() {
        navigator.openURL(loremIpsumURL)

        // Select some text and long press to find the option
        app.webViews.element(boundBy: 0).staticTexts.element(boundBy: 0).press(forDuration: 1)
        snapshot("26LongPressTextOptions-01")
        waitForExistence(app.menuItems["show.next.items.menu.button"])
        app.menuItems["show.next.items.menu.button"].tap()
        snapshot("26LongPressTextOptions-02")
    }

    func test27URLBar() {
        navigator.goto(URLBarOpen)
        snapshot("27URLBar-01")

        userState.url = "moz"
        navigator.performAction(Action.SetURLByTyping)
        snapshot("27URLBar-02")
    }

    func test28URLBarContextMenu() {
        // Long press with nothing on the clipboard
        navigator.goto(URLBarLongPressMenu)
        snapshot("28LocationBarContextMenu-01-no-url")
        navigator.back()

        // Long press with a URL on the clipboard
        UIPasteboard.general.string = "https://www.mozilla.com"
        navigator.goto(URLBarLongPressMenu)
        snapshot("28LocationBarContextMenu-02-with-url")
    }

    func test29MenuOnWebPage() {
        navigator.openURL(loremIpsumURL)
        navigator.goto(BrowserTabMenu)
        snapshot("29MenuOnWebPage-01")
        navigator.back()

        navigator.toggleOn(userState.noImageMode, withAction: Action.ToggleNoImageMode)
        navigator.toggleOn(userState.nightMode, withAction: Action.ToggleNightMode)
        navigator.goto(BrowserTabMenu)
        snapshot("29MenuOnWebPage-02")
        navigator.back()
    }

    func test201PageMenuOnWebPage() {
        navigator.goto(PageOptionsMenu)
        snapshot("201MenuOnWebPage-03")
        navigator.back()
    }
}
