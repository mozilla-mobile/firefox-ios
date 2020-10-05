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
        navigator.goto(BrowserTab)
        waitForExistence(app.buttons["TabLocationView.pageOptionsButton"])
        navigator.goto(PageOptionsMenu)
        snapshot("MenuOnWebPage-03")
        navigator.back()
       }

    func test11FxASignInPage() {
        navigator.goto(Intro_FxASignin)
        waitForExistence(app.navigationBars.staticTexts["FxASingin.navBar"])
        snapshot("FxASignInScreen-01")
    }
    
    func testSearchWidgets2() {
        
        // Set a url in the pasteboard
        UIPasteboard.general.string = "www.example.com"

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        setupSnapshot(springboard)
        // Open the app and set it to background
        app.activate()
        navigator.openURL("www.mozilla.org")
        sleep(1)
        XCUIDevice.shared.press(.home)

        // Swipe Right to go to Widgets view
        let window = springboard.children(matching: .window).element(boundBy: 0)
        window.swipeRight()
        window.swipeRight()

        // Swipe Up to get to the Edit and Add Widget buttons
        // This line is needed the first time widgets view is open
        springboard.alerts.firstMatch.scrollViews.otherElements.buttons.element(boundBy: 0).tap()

        let element = springboard/*@START_MENU_TOKEN@*/.scrollViews["left-of-home-scroll-view"]/*[[".otherElements[\"Home screen icons\"].scrollViews[\"left-of-home-scroll-view\"]",".scrollViews[\"left-of-home-scroll-view\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.children(matching: .other).element.children(matching: .other).element(boundBy: 0)
        element.swipeUp()
        element.swipeUp()
        element.swipeUp()
        springboard.scrollViews["left-of-home-scroll-view"].otherElements.buttons.firstMatch.tap()
        
        sleep(1)
        springboard.otherElements["Home screen icons"].buttons.firstMatch.tap()
        
        // Select Fennec (username)
        springboard.collectionViews.cells.element(boundBy: 5).children(matching: .other).element.children(matching: .other).element(boundBy: 0).children(matching: .other).element.tap()
        // Tap on Add widget button
        springboard.buttons.staticTexts.firstMatch.tap()

        // Dismiss the edit mode
        element.tap()

        // Wait for the Search in Firefox widget and tap on it
        sleep(1)
        snapshot("Widget-01")
        // Tap on Edit and then on Add to Widget
        springboard.scrollViews["left-of-home-scroll-view"].otherElements.buttons.firstMatch.tap()
        
        springboard.otherElements["Home screen icons"].buttons.firstMatch.tap()

        springboard.collectionViews.cells.element(boundBy: 5).children(matching: .other).element.children(matching: .other).element(boundBy: 0).children(matching: .other).element.swipeLeft()

        // Scroll to she second screen to select the other widget
        print(springboard.debugDescription)
        springboard.scrollViews.staticTexts.firstMatch.swipeLeft()
        // Tap on Add widget button
        springboard.buttons.staticTexts.firstMatch.tap()

        // Dismiss the edit mode
        element.tap()
        sleep(1)
        snapshot("Widget-02")
    }
}
