/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let testPageBase = "http://www.example.com"
let loremIpsumURL = "\(testPageBase)"

class L10nSnapshotTests: L10nBaseSnapshotTests {
    func test02DefaultTopSites() {
        navigator.toggleOff(userState.pocketInNewTab, withAction: Action.TogglePocketInNewTab)
        navigator.goto(HomePanelsScreen)
        snapshot("02DefaultTopSites-01")
        navigator.toggleOn(userState.pocketInNewTab, withAction: Action.TogglePocketInNewTab)
        navigator.goto(HomePanelsScreen)
        snapshot("02DefaultTopSites-with-pocket-02")
    }

    func test03MenuOnTopSites() {
        navigator.goto(NewTabScreen)
        navigator.goto(BrowserTabMenu)
        snapshot("03MenuOnTopSites-01")
    }

    func test04Settings() {
        let table = app.tables.element(boundBy: 0)
        navigator.goto(SettingsScreen)
        table.forEachScreen { i in
            snapshot("04Settings-main-\(i)")
        }

        allSettingsScreens.forEach { nodeName in
            self.navigator.goto(nodeName)
            table.forEachScreen { i in
                snapshot("04Settings-\(nodeName)-\(i)")
            }
        }
    }

    func test05PrivateBrowsingTabsEmptyState() {
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        snapshot("05PrivateBrowsingTabsEmptyState-01")
    }

    func test06PanelsEmptyState() {
        let libraryPanels = [
            "LibraryPanels.History",
            "LibraryPanels.ReadingList",
            "LibraryPanels.Downloads",
            "LibraryPanels.SyncedTabs"
        ]
        navigator.goto(LibraryPanel_Bookmarks)
        snapshot("06PanelsEmptyState-LibraryPanels.Bookmarks")
        libraryPanels.forEach { panel in
            app.buttons[panel].tap()
            snapshot("06PanelsEmptyState-\(panel)")
        }
    }

    // From here on it is fine to load pages
    func test07LongPressOnTextOptions() {
        navigator.openURL(loremIpsumURL)

        // Select some text and long press to find the option
        app.webViews.element(boundBy: 0).staticTexts.element(boundBy: 0).press(forDuration: 1)
        snapshot("07LongPressTextOptions-01")
        waitForExistence(app.menus.children(matching: .menuItem).element(boundBy: 3))
        app.menus.children(matching: .menuItem).element(boundBy: 3).tap()
        snapshot("07LongPressTextOptions-02")
    }

    func test08URLBar() {
        navigator.goto(URLBarOpen)
        snapshot("08URLBar-01")

        userState.url = "moz"
        navigator.performAction(Action.SetURLByTyping)
        snapshot("08URLBar-02")
    }

    func test09URLBarContextMenu() {
        // Long press with nothing on the clipboard
        navigator.goto(URLBarLongPressMenu)
        snapshot("09LocationBarContextMenu-01-no-url")
        navigator.back()

        // Long press with a URL on the clipboard
        UIPasteboard.general.string = "https://www.mozilla.com"
        navigator.goto(URLBarLongPressMenu)
        snapshot("09LocationBarContextMenu-02-with-url")
    }

    func test10MenuOnWebPage() {
        navigator.openURL(loremIpsumURL)
        navigator.goto(BrowserTabMenu)
        snapshot("10MenuOnWebPage-01")
        navigator.back()

        navigator.toggleOn(userState.noImageMode, withAction: Action.ToggleNoImageMode)
        navigator.toggleOn(userState.nightMode, withAction: Action.ToggleNightMode)
        navigator.goto(BrowserTabMenu)
        snapshot("10MenuOnWebPage-02")
        navigator.back()
    }

    func test10PageMenuOnWebPage() {
        navigator.goto(PageOptionsMenu)
        snapshot("10MenuOnWebPage-03")
        navigator.back()
    }

    func test11WebViewContextMenu() {
        // Drag the context menu up to show all the options
        func drag() {
            let window = XCUIApplication().windows.element(boundBy: 0)
            let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
            let finish = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            start.press(forDuration: 0.01, thenDragTo: finish)
        }

        // Link
        navigator.openURL("http://wikipedia.org")
        navigator.goto(WebLinkContextMenu)
        drag()
        snapshot("11WebViewContextMenu-01-link")
        navigator.back()

        // Image
        navigator.openURL("http://wikipedia.org")
        navigator.goto(WebImageContextMenu)
        drag()
        snapshot("11WebViewContextMenu-02-image")
        navigator.back()
    }

    func test12WebViewAuthenticationDialog() {
        navigator.openURL("https://jigsaw.w3.org/HTTP/Basic/", waitForLoading: false)
        navigator.goto(BasicAuthDialog)
        snapshot("12WebViewAuthenticationDialog-01", waitForLoadingIndicator: false)
        navigator.back()
    }

    func test13ReloadButtonContextMenu() {
        navigator.toggleOn(userState.trackingProtectionSettingOnNormalMode == true, withAction: Action.SwitchETP)
        navigator.goto(BrowserTab)

        navigator.openURL(loremIpsumURL)
        navigator.toggleOff(userState.requestDesktopSite, withAction: Action.ToggleRequestDesktopSite)
        navigator.goto(ReloadLongPressMenu)
        snapshot("13ContextMenuReloadButton-01")
        navigator.toggleOn(userState.requestDesktopSite, withAction: Action.ToggleRequestDesktopSite)
        navigator.goto(ReloadLongPressMenu)
        snapshot("13ContextMenuReloadButton-02", waitForLoadingIndicator: false)

        navigator.toggleOff(userState.trackingProtectionPerTabEnabled, withAction: Action.ToggleTrackingProtectionPerTabEnabled)
        navigator.goto(ReloadLongPressMenu)

        // Snapshot of 'Reload *with* tracking protection' label, because trackingProtectionPerTabEnabled is false.
        snapshot("13ContextMenuReloadButton-03", waitForLoadingIndicator: false)
    }

    func test16PasscodeSettings() {
        navigator.goto(SetPasscodeScreen)
        snapshot("16SetPasscodeScreen-1-nopasscode")
        userState.newPasscode = "111111"
        navigator.performAction(Action.SetPasscodeTypeOnce)
        snapshot("16SetPasscodeScreen-2-typepasscode")

        userState.newPasscode = "111112"
        navigator.performAction(Action.SetPasscodeTypeOnce)
        snapshot("16SetPasscodeScreen-3-passcodesmustmatch")

        userState.newPasscode = "111111"
        navigator.performAction(Action.SetPasscode)
        snapshot("16SetPasscodeScreen-3")

        navigator.goto(PasscodeIntervalSettings)
        snapshot("16PasscodeIntervalScreen-1")
    }

    func test18TopSitesMenu() {
        navigator.goto(HomePanel_TopSites)
        navigator.goto(TopSitesPanelContextMenu)
        snapshot("18TopSitesMenu-01")
    }

    func test19HistoryTableContextMenu() {
        navigator.openURL(loremIpsumURL)
        navigator.goto(HistoryPanelContextMenu)
        snapshot("19HistoryTableContextMenu-01")
    }

    func test20BookmarksTableContextMenu() {
        navigator.openURL(loremIpsumURL)
        navigator.performAction(Action.Bookmark)
        navigator.createNewTab()
        navigator.goto(BookmarksPanelContextMenu)
        snapshot("20BookmarksTableContextMenu-01")
    }

    func test21ReaderModeSettingsMenu() {
        loadWebPage(url: "en.m.wikipedia.org/wiki/Main_Page")
        app.buttons["TabLocationView.readerModeButton"].tap()
        app.buttons["ReaderModeBarView.settingsButton"].tap()
        snapshot("21ReaderModeSettingsMenu-01")
    }

    func test22ETPperSite() {
        // Website without blocked elements
        navigator.openURL(loremIpsumURL)
        navigator.goto(TrackingProtectionContextMenuDetails)
        snapshot("22TrackingProtectionEnabledPerSite-01")
        navigator.performAction(Action.TrackingProtectionperSiteToggle)
        snapshot("22TrackingProtectionDisabledPerSite-02")

        // Website with blocked elements
        navigator.openNewURL(urlString: "twitter.com")
        waitForExistence(app.buttons["TabLocationView.trackingProtectionButton"])
        navigator.goto(TrackingProtectionContextMenuDetails)
        snapshot("22TrackingProtectionBlockedElements-01")
        // Tap on the block element to get more details
        app.cells.element(boundBy: 2).tap()
        snapshot("22TrackingProtectionBlockedElements-02")
    }

    func test23SettingsETP() {
        navigator.goto(TrackingProtectionSettings)
        
       // Check the warning alert
        app.cells["Settings.TrackingProtectionOption.BlockListStrict"].tap()

        snapshot("TrackingProtectionStrictWarning-01")
        app.alerts.buttons.firstMatch.tap()
        waitForExistence(app.cells["Settings.TrackingProtectionOption.BlockListBasic"])
        app.cells["Settings.TrackingProtectionOption.BlockListBasic"].buttons.firstMatch.tap()
        snapshot("23TrackingProtectionBasicMoreInfo-01")

        waitForExistence(app.navigationBars["Client.TPAccessoryInfo"])
        // Go back to TP settings
        app.navigationBars["Client.TPAccessoryInfo"].buttons.firstMatch.tap()

        // See Strict mode info
        waitForExistence(app.cells["Settings.TrackingProtectionOption.BlockListStrict"])
        app.cells["Settings.TrackingProtectionOption.BlockListStrict"].buttons.firstMatch.tap()
        app.tables.cells.staticTexts.firstMatch.swipeUp()
        snapshot("23TrackingProtectionStrictMoreInfo-02")
    }
}
