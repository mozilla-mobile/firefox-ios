/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class L10nSuite1SnapshotTests: L10nBaseSnapshotTests {

    var noSkipIntroTest = ["testIntro"]

    override func setUp() {
        // Test name looks like: "[Class testFunc]", parse out the function name
        let parts = name.replacingOccurrences(of: "]", with: "").split(separator: " ")
                let key = String(parts[1])
        if noSkipIntroTest.contains(key) {
            args = [LaunchArguments.ClearProfile, LaunchArguments.SkipWhatsNew, LaunchArguments.SkipETPCoverSheet]
        }
        super.setUp()
    }

    func testIntro() {
        var num = 1
        waitForExistence(app.buttons["nextOnboardingButton"])
        navigator.nowAt(Intro_Welcome)
        allIntroPages.forEach { screenName in
            navigator.goto(screenName)
            snapshot("Intro-\(num)-\(screenName)")
            num += 1
        }
    }
    
    func testWebViewContextMenu() {
        // Drag the context menu up to show all the options
        func drag() {
            let window = XCUIApplication().windows.element(boundBy: 0)
            let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
            let finish = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            start.press(forDuration: 0.01, thenDragTo: finish)
        }

        // Link
        navigator.openURL("http://wikipedia.org")
        waitForNoExistence(app.staticTexts["XCUITests-Runner pasted from Fennec"])
        waitForExistence(app.webViews.element(boundBy: 0).links.element(boundBy: 0), timeout: 5)
        navigator.goto(WebLinkContextMenu)
        drag()
        snapshot("WebViewContextMenu-01-link")
        navigator.back()

        // Image
        navigator.openURL("http://wikipedia.org")
        waitForNoExistence(app.staticTexts["XCUITests-Runner pasted from Fennec"])
        waitForExistence(app.webViews.element(boundBy: 0).images.element(boundBy: 0), timeout: 5)
        navigator.goto(WebImageContextMenu)
        drag()
        snapshot("WebViewContextMenu-02-image")
        navigator.back()
    }

    func testWebViewAuthenticationDialog() {
        navigator.openURL("https://jigsaw.w3.org/HTTP/Basic/", waitForLoading: false)
        waitForNoExistence(app.staticTexts["XCUITests-Runner pasted from Fennec"])
        navigator.goto(BasicAuthDialog)
        snapshot("WebViewAuthenticationDialog-01", waitForLoadingIndicator: false)
        navigator.back()
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
        navigator.goto(HomePanel_TopSites)
        navigator.goto(TopSitesPanelContextMenu)
        snapshot("TopSitesMenu-01")
    }

    func testHistoryTableContextMenu() {
        navigator.openURL(loremIpsumURL)
        waitForNoExistence(app.staticTexts["XCUITests-Runner pasted from Fennec"])
        
        navigator.goto(HistoryPanelContextMenu)
        snapshot("HistoryTableContextMenu-01")
    }

    func testBookmarksTableContextMenu() {
        navigator.openURL(loremIpsumURL)
        // There is no other way the test work with the new Copied.. snackbar ahow on iOS14
        waitForNoExistence(app.staticTexts["XCUITests-Runner pasted from Fennec"])
        waitForExistence(app.buttons["TabLocationView.pageOptionsButton"], timeout: 5)
        navigator.performAction(Action.Bookmark)
        navigator.createNewTab()
        // Disable due to issue #7521
        // navigator.goto(BookmarksPanelContextMenu)
        navigator.goto(LibraryPanel_Bookmarks)
        snapshot("BookmarksTableContextMenu-01")
    }

    // Disable in parallel testing
    /*
    func test21ReaderModeSettingsMenu() {
        loadWebPage(url: "en.m.wikipedia.org/wiki/Main_Page")
        app.buttons["TabLocationView.readerModeButton"].tap()
        waitForExistence(app.buttons["ReaderModeBarView.settingsButton"])
        app.buttons["ReaderModeBarView.settingsButton"].tap()
        snapshot("21ReaderModeSettingsMenu-01")
    }*/

    func testETPperSite() {
        // Enable Strict ETP
        navigator.goto(TrackingProtectionSettings)
        // Check the warning alert
         app.cells["Settings.TrackingProtectionOption.BlockListStrict"].tap()

         snapshot("TrackingProtectionStrictWarning-01")
         app.alerts.buttons.firstMatch.tap()

        // Website without blocked elements
        navigator.openURL(loremIpsumURL)
        waitForNoExistence(app.staticTexts["XCUITests-Runner pasted from Fennec"])
        waitForExistence(app.buttons["TabLocationView.trackingProtectionButton"], timeout: 5)
        navigator.goto(TrackingProtectionContextMenuDetails)
        snapshot("TrackingProtectionEnabledPerSite-01")

        // Disable the toggle so that TP is off
        app.cells["tp.add-to-safelist"].tap()
        snapshot("TrackingProtectionDisabledPerSite-02")
    }

    func testSettingsETP() {
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

    func testSetDefaultBrowser() {
        if #available(iOS 14, *) {
            waitForExistence(app.buttons["Home.learnMoreDefaultBrowserbutton"], timeout: 5)
            app.buttons["Home.learnMoreDefaultBrowserbutton"].tap()
            waitForExistence(app.buttons["DefaultBrowserCard.goToSettingsButton"], timeout: 5)
            snapshot("HomeDefaultBrowserLearnMore")
        }
    }
}
