/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let testPageBase = "http://wopr.norad.org/~sarentz/fxios/testpages"
let loremIpsumURL = "\(testPageBase)/index.html"

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
        var i = 0
        navigator.visitNodes(allHomePanels) { nodeName in
            snapshot("06PanelsEmptyState-\(i)-\(nodeName)")
            i += 1
        }
    }

    // From here on it is fine to load pages

    func test07AddSearchProvider() {
        navigator.openURL("\(testPageBase)/addSearchProvider.html")
        app.webViews.element(boundBy: 0).buttons["focus"].tap()
        snapshot("07AddSearchProvider-01", waitForLoadingIndicator: false)
        app.buttons["BrowserViewController.customSearchEngineButton"].tap()
        snapshot("07AddSearchProvider-02", waitForLoadingIndicator: false)

        let alert = XCUIApplication().alerts.element(boundBy: 0)
        expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: alert, handler: nil)
        waitForExpectations(timeout: 3, handler: nil)
        alert.buttons.element(boundBy: 0).tap()
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
        // Link
        navigator.openURL("\(testPageBase)/link.html")
        navigator.goto(WebLinkContextMenu)
        snapshot("11WebViewContextMenu-01-link")
        navigator.back()

        // Image
        navigator.openURL("\(testPageBase)/image.html")
        navigator.goto(WebImageContextMenu)
        snapshot("11WebViewContextMenu-02-image")
        navigator.back()

        // Image inside Link
        navigator.openURL("\(testPageBase)/imageWithLink.html")
        navigator.goto(WebLinkContextMenu)
        snapshot("11WebViewContextMenu-03-imageWithLink")
        navigator.back()
    }

    func test12WebViewAuthenticationDialog() {
        navigator.openURL("\(testPageBase)/basicauth/index.html", waitForLoading: false)
        navigator.goto(BasicAuthDialog)
        snapshot("12WebViewAuthenticationDialog-01", waitForLoadingIndicator: false)
        navigator.back()
    }

    func test13ReloadButtonContextMenu() {
        navigator.openURL(loremIpsumURL)
        navigator.toggleOff(userState.requestDesktopSite, withAction: Action.ToggleRequestDesktopSite)
        navigator.goto(ReloadLongPressMenu)
        snapshot("13ContextMenuReloadButton-01")
        navigator.toggleOn(userState.requestDesktopSite, withAction: Action.ToggleRequestDesktopSite)
        navigator.goto(ReloadLongPressMenu)
        snapshot("13ContextMenuReloadButton-02", waitForLoadingIndicator: false)
        navigator.back()
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

    func test17PasswordSnackbar() {
        navigator.openURL("\(testPageBase)/password.html")
        app.webViews.element(boundBy: 0).buttons["submit"].tap()
        snapshot("17PasswordSnackbar-01")
        app.buttons["SaveLoginPrompt.saveLoginButton"].tap()
        // The password is pre-filled with a random value so second this this will cause the update prompt
        navigator.openURL("\(testPageBase)/password.html")
        app.webViews.element(boundBy: 0).buttons["submit"].tap()
        snapshot("17PasswordSnackbar-02")
    }

    func test18TopSitesMenu() {
        navigator.openURL(loremIpsumURL)
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
        navigator.goto(BookmarksPanelContextMenu)
        snapshot("20BookmarksTableContextMenu-01")
    }

    func test21ReaderModeSettingsMenu() {
        let app = XCUIApplication()
        loadWebPage(url: loremIpsumURL, waitForOtherElementWithAriaLabel: "body")
        app.buttons["TabLocationView.readerModeButton"].tap()
        app.buttons["ReaderModeBarView.settingsButton"].tap()
        snapshot("21ReaderModeSettingsMenu-01")
    }

    func test22ReadingListTableContextMenu() {
        let app = XCUIApplication()
        loadWebPage(url: loremIpsumURL, waitForOtherElementWithAriaLabel: "body")
        app.buttons["TabLocationView.readerModeButton"].tap()
        app.buttons["ReaderModeBarView.listStatusButton"].tap()
        app.textFields["url"].tap()
        app.buttons["HomePanels.ReadingList"].tap()
        app.tables["ReadingTable"].cells.element(boundBy: 0).press(forDuration: 2.0)
        snapshot("22ReadingListTableContextMenu-01")
    }

    func test23ReadingListTableRowMenu() {
        let app = XCUIApplication()
        loadWebPage(url: loremIpsumURL, waitForOtherElementWithAriaLabel: "body")
        app.buttons["TabLocationView.readerModeButton"].tap()
        app.buttons["ReaderModeBarView.listStatusButton"].tap()
        app.textFields["url"].tap()
        app.buttons["HomePanels.ReadingList"].tap()
        app.tables["ReadingTable"].cells.element(boundBy: 0).swipeLeft()
        snapshot("23ReadingListTableRowMenu-01")
        app.tables["ReadingTable"].cells.element(boundBy: 0).buttons.element(boundBy: 1).tap()
        app.tables["ReadingTable"].cells.element(boundBy: 0).swipeLeft()
        snapshot("23ReadingListTableRowMenu-02")
    }

    func test24BookmarksListTableRowMenu() {
        navigator.openURL(loremIpsumURL)
        navigator.performAction(Action.Bookmark)
        navigator.goto(BookmarksPanelContextMenu)
        app.tables["Bookmarks List"].cells.element(boundBy: 0).swipeLeft()
        snapshot("24BookmarksListTableRowMenu-01")
    }
}
