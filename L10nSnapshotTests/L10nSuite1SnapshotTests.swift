// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class L10nSuite1SnapshotTests: L10nBaseSnapshotTests {
    var noSkipIntroTest = ["testIntro"]

    var currentScreen = 0
    var rootA11yId: String {
        return "\(AccessibilityIdentifiers.Onboarding.onboarding)\(currentScreen)"
    }

    override func setUp() {
        // Test name looks like: "[Class testFunc]", parse out the function name
        let parts = name.replacingOccurrences(of: "]", with: "").split(separator: " ")
                let key = String(parts[1])
        if noSkipIntroTest.contains(key) {
            args = [LaunchArguments.ClearProfile,
                    LaunchArguments.SkipWhatsNew,
                    LaunchArguments.SkipETPCoverSheet,
                    LaunchArguments.SkipContextualHints,
                    LaunchArguments.TurnOffTabGroupsInUserPreferences]
        }
        currentScreen = 0
        super.setUp()
    }

    func testIntro() {
        waitForExistence(app.scrollViews.staticTexts["\(rootA11yId)TitleLabel"], timeout: 15)
        waitForExistence(app.scrollViews.staticTexts["\(rootA11yId)DescriptionLabel"], timeout: 15)
        snapshot("Onboarding-1")

        // Swipe to the second screen
        app.buttons["\(rootA11yId)SecondaryButton"].tap()
        currentScreen += 1
        waitForExistence(app.scrollViews.staticTexts["\(rootA11yId)TitleLabel"], timeout: 15)
        waitForExistence(app.scrollViews.staticTexts["\(rootA11yId)DescriptionLabel"], timeout: 15)
        waitForExistence(app.buttons["\(rootA11yId)PrimaryButton"])
        waitForExistence(app.buttons["\(rootA11yId)SecondaryButton"])
        snapshot("Onboarding-2")

        // Swipe to the third screen
        app.buttons["\(rootA11yId)SecondaryButton"].tap()
        currentScreen += 1
        waitForExistence(app.scrollViews.staticTexts["\(rootA11yId)TitleLabel"], timeout: 15)
        waitForExistence(app.scrollViews.staticTexts["\(rootA11yId)DescriptionLabel"], timeout: 15)
        waitForExistence(app.buttons["\(rootA11yId)PrimaryButton"])
        waitForExistence(app.buttons["\(rootA11yId)SecondaryButton"])
        snapshot("Onboarding-3")

        // Swipe to the Homescreen
        app.buttons["\(rootA11yId)SecondaryButton"].tap()
        currentScreen += 1
        waitForExistence(app.textFields["url"])
        waitForExistence(app.webViews["contentView"])
        snapshot("Homescreen-first-visit")
    }

    func testWebViewContextMenu () throws {
        throw XCTSkip("Failing a lot and now new strings here")
//        // Drag the context menu up to show all the options
//        func drag() {
//            let window = XCUIApplication().windows.element(boundBy: 0)
//            let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
//            let finish = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
//            start.press(forDuration: 0.01, thenDragTo: finish)
//        }
//
//        // Link
//        navigator.openURL("http://wikipedia.org")
//        waitForNoExistence(app.staticTexts["XCUITests-Runner pasted from Fennec"])
//        waitForExistence(app.webViews.element(boundBy: 0).links.element(boundBy: 0), timeout: 5)
//        navigator.goto(WebLinkContextMenu)
//        drag()
//        snapshot("WebViewContextMenu-01-link")
//        navigator.back()
//
//        // Image
//        navigator.openURL("http://wikipedia.org")
//        waitForNoExistence(app.staticTexts["XCUITests-Runner pasted from Fennec"])
//        waitForExistence(app.webViews.element(boundBy: 0).images.element(boundBy: 0), timeout: 5)
//        navigator.goto(WebImageContextMenu)
//        drag()
//        snapshot("WebViewContextMenu-02-image")
//        navigator.back()
    }

    func testWebViewAuthenticationDialog() {
        navigator.openURL("https://jigsaw.w3.org/HTTP/Basic/", waitForLoading: false)
        waitForNoExistence(app.staticTexts["XCUITests-Runner pasted from Fennec"])
        navigator.nowAt(BasicAuthDialog)
        snapshot("WebViewAuthenticationDialog-01", waitForLoadingIndicator: false)
    }

    func test3ReloadButtonContextMenu() {
        navigator.openURL(loremIpsumURL)
        waitUntilPageLoad()
        waitForNoExistence(app.staticTexts["XCUITests-Runner pasted from Fennec"])

        navigator.toggleOff(userState.requestDesktopSite, withAction: Action.ToggleRequestDesktopSite)
        navigator.goto(ReloadLongPressMenu)
        snapshot("ContextMenuReloadButton-01")
        navigator.toggleOn(userState.requestDesktopSite, withAction: Action.ToggleRequestDesktopSite)
        navigator.goto(ReloadLongPressMenu)
        snapshot("ContextMenuReloadButton-02", waitForLoadingIndicator: false)
    }

    func testTopSitesMenu() {
        sleep(3)
        // waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], timeout: 15)
        navigator.nowAt(NewTabScreen)
        app.collectionViews.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell].firstMatch.swipeUp()
        snapshot("TopSitesMenu-00")

        // Workaround since in some locales Top Sites are not shown right away
//        navigator.goto(SettingsScreen)
//        navigator.goto(HomePanel_TopSites)
//        waitForExistence(app.buttons["urlBar-cancel"], timeout: 15)
//        app.buttons["urlBar-cancel"].tap()
//        navigator.goto(TopSitesPanelContextMenu)
//        snapshot("TopSitesMenu-01")
    }

    func testHistoryTableContextMenu() {
        navigator.openURL(loremIpsumURL)
        waitForNoExistence(app.staticTexts["XCUITests-Runner pasted from Fennec"], timeoutValue: 5)
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], timeout: 10)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], timeout: 10)
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables["History List"])
        app.tables["History List"].cells.element(boundBy: 1).staticTexts.element(boundBy: 1).press(forDuration: 2)
        snapshot("HistoryTableContextMenu-01")
    }

    func testBookmarksTableContextMenu() {
        sleep(3)
        navigator.openURL(loremIpsumURL)
        // There is no other way the test work with the new Copied.. snackbar ahow on iOS14
        waitForNoExistence(app.staticTexts["XCUITests-Runner pasted from Fennec"])
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], timeout: 15)
        navigator.performAction(Action.Bookmark)
        navigator.createNewTab()
        // Disable due to issue #7521
        // navigator.goto(BookmarksPanelContextMenu)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_Bookmarks)
        snapshot("BookmarksTableContextMenu-01")
    }

    // Disable in parallel testing
    /*
    func test21ReaderModeSettingsMenu() {
        loadWebPage(url: "en.m.wikipedia.org/wiki/Main_Page")
        app.buttons[ AccessibilityIdentifiers.Toolbar.readerModeButton].tap()
        waitForExistence(app.buttons["ReaderModeBarView.settingsButton"])
        app.buttons["ReaderModeBarView.settingsButton"].tap()
        snapshot("21ReaderModeSettingsMenu-01")
    }*/

    func testETPperSite() {
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], timeout: 10)
        navigator.nowAt(NewTabScreen)
        // Enable Strict ETP
        navigator.goto(TrackingProtectionSettings)
        // Check the warning alert
        app.cells["Settings.TrackingProtectionOption.BlockListStrict"].tap()

        snapshot("TrackingProtectionStrictWarning-01")

        // Website without blocked elements
        navigator.openURL(loremIpsumURL)
        waitForNoExistence(app.staticTexts["XCUITests-Runner pasted from Fennec"])
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.trackingProtection], timeout: 5)
        navigator.goto(TrackingProtectionContextMenuDetails)
        snapshot("TrackingProtectionEnabledPerSite-01")

        // Disable the toggle so that TP is off
        snapshot("TrackingProtectionDisabledPerSite-02")
        app.switches.firstMatch.tap()
        snapshot("TrackingProtectionDisabledPerSite-03")
    }

    func testSettingsETP() {
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], timeout: 10)
        navigator.nowAt(NewTabScreen)
        navigator.goto(TrackingProtectionSettings)

        waitForExistence(app.cells["Settings.TrackingProtectionOption.BlockListBasic"])
        app.cells["Settings.TrackingProtectionOption.BlockListBasic"].buttons.firstMatch.tap()
        snapshot("TrackingProtectionBasicMoreInfo-01")

        waitForExistence(app.navigationBars["Client.TPAccessoryInfo"])
        // Go back to TP settings
        app.navigationBars["Client.TPAccessoryInfo"].buttons.firstMatch.tap()

        // See Strict mode info
        waitForExistence(app.cells["Settings.TrackingProtectionOption.BlockListStrict"])
        app.cells["Settings.TrackingProtectionOption.BlockListStrict"].buttons.firstMatch.tap()
        app.tables.cells.staticTexts.firstMatch.swipeUp()
        snapshot("TrackingProtectionStrictMoreInfo-02")
    }

    func testMenuOnTopSites() {
        typealias homeTabBannerA11y = AccessibilityIdentifiers.FirefoxHomepage.HomeTabBanner

        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], timeout: 10)
        navigator.nowAt(NewTabScreen)
        navigator.goto(BrowserTabMenu)
        snapshot("MenuOnTopSites-01")

        // Set as Default browser screenshot
        navigator.goto(NewTabScreen)
        waitForExistence(app.buttons[homeTabBannerA11y.ctaButton], timeout: 15)
        app.buttons[homeTabBannerA11y.ctaButton].tap()
        waitForExistence(app.buttons["HomeTabBanner.goToSettingsButton"], timeout: 15)
        snapshot("HomeDefaultBrowserLearnMore")
    }

    func testSettings() {
        let table = app.tables.element(boundBy: 0)
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], timeout: 10)
        navigator.nowAt(NewTabScreen)
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

    func testPrivateBrowsingTabsEmptyState() {
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], timeout: 10)
        navigator.nowAt(NewTabScreen)
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        snapshot("PrivateBrowsingTabsEmptyState-01")
    }

    func testTakeMarketingScreenshots() {
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], timeout: 10)
        snapshot("00TopSites")

        // go to synced tabs home screen
        navigator.goto(TabTray)
        snapshot("03SyncedTabs")

        // load some web pages in some new tabs
        navigator.openNewURL(urlString: "https://www.mozilla.org")
        waitUntilPageLoad()
        navigator.openNewURL(urlString: "https://mozilla.org/firefox/desktop")
        waitUntilPageLoad()
        navigator.openNewURL(urlString: "https://mozilla.org/firefox/new")
        waitUntilPageLoad()
        navigator.goto(TabTray)
        snapshot("02TabTray")

        // perform a search but don't complete (we're testing autocomplete here)
        navigator.createNewTab()
        waitForExistence(app.textFields["url"], timeout: 10)
        app.typeText("firef")
        sleep(2)
        snapshot("01SearchResults")
    }
}
