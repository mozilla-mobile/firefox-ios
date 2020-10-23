/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
let testPageBase2 = "http://www.example.com"
let loremIpsumURL2 = "\(testPageBase2)"

class L10nSuite1SnapshotTests: L10nBaseSnapshotTests {
    override var skipIntro: Bool {
        return false
    }

    func testIntro() {
        var num = 1
        allIntroPages.forEach { screenName in
            navigator.goto(screenName)
            snapshot("Intro-\(num)-\(screenName)")
            num += 1
        }
    }
    
    func test1WebViewContextMenu() {
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
        snapshot("WebViewContextMenu-01-link")
        navigator.back()

        // Image
        navigator.openURL("http://wikipedia.org")
        navigator.goto(WebImageContextMenu)
        drag()
        snapshot("WebViewContextMenu-02-image")
        navigator.back()
    }

    func test2WebViewAuthenticationDialog() {
        navigator.openURL("https://jigsaw.w3.org/HTTP/Basic/", waitForLoading: false)
        navigator.goto(BasicAuthDialog)
        snapshot("WebViewAuthenticationDialog-01", waitForLoadingIndicator: false)
        navigator.back()
    }
    // Disabled due to real bug:  https://github.com/mozilla-mobile/firefox-ios/issues/7248
    /*func test3ReloadButtonContextMenu() {
        navigator.toggleOn(userState.trackingProtectionSettingOnNormalMode == true, withAction: Action.SwitchETP)
        navigator.goto(BrowserTab)

        navigator.openURL(loremIpsumURL2)
        navigator.toggleOff(userState.requestDesktopSite, withAction: Action.ToggleRequestDesktopSite)
        navigator.goto(ReloadLongPressMenu)
        snapshot("ContextMenuReloadButton-01")
        navigator.toggleOn(userState.requestDesktopSite, withAction: Action.ToggleRequestDesktopSite)
        navigator.goto(ReloadLongPressMenu)
        snapshot("ContextMenuReloadButton-02", waitForLoadingIndicator: false)

        navigator.toggleOff(userState.trackingProtectionPerTabEnabled, withAction: Action.ToggleTrackingProtectionPerTabEnabled)
        navigator.goto(ReloadLongPressMenu)

        // Snapshot of 'Reload *with* tracking protection' label, because trackingProtectionPerTabEnabled is false.
        snapshot("ContextMenuReloadButton-03", waitForLoadingIndicator: false)
    }*/

    private func typePasscode(n: Int, keyNumber: Int) {
        for _ in 1...n {
            app.keys.element(boundBy: keyNumber).tap()
            sleep(1)
        }
    }

    func test4PasscodeSettings() {
        navigator.goto(PasscodeSettings)
        app.tables.cells["TurnOnPasscode"].tap()
        snapshot("SetPasscodeScreen-1-nopasscode")
        
        // Type "111111 passcode"
        typePasscode(n: 6, keyNumber: 2)
        snapshot("SetPasscodeScreen-2-typepasscode")
        // Type incorrect passcode "111112"
        typePasscode(n: 5, keyNumber: 2)
        // Type once inkey "2"
        typePasscode(n: 1, keyNumber: 1)
        snapshot("SetPasscodeScreen-3-passcodesmustmatch")
        
        // Confitm passcode
        typePasscode(n: 6, keyNumber: 2)
        typePasscode(n: 6, keyNumber: 2)
        snapshot("SetPasscodeScreen-3")
        
        // Go to interval settings
        app.tables.cells["PasscodeInterval"].tap()
        typePasscode(n: 6, keyNumber: 2)
        snapshot("PasscodeIntervalScreen-1")
    }

    func test5TopSitesMenu() {
        navigator.goto(HomePanel_TopSites)
        navigator.goto(TopSitesPanelContextMenu)
        snapshot("TopSitesMenu-01")
    }

    func test6HistoryTableContextMenu() {
        navigator.openURL(loremIpsumURL2)
        navigator.goto(HistoryPanelContextMenu)
        snapshot("HistoryTableContextMenu-01")
    }

    func test7BookmarksTableContextMenu() {
        navigator.openURL(loremIpsumURL2)
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

    func test8ETPperSite() {
        // Enable Strict ETP
        navigator.goto(TrackingProtectionSettings)
        // Check the warning alert
         app.cells["Settings.TrackingProtectionOption.BlockListStrict"].tap()

         snapshot("TrackingProtectionStrictWarning-01")
         app.alerts.buttons.firstMatch.tap()

        // Website without blocked elements
        navigator.openURL(loremIpsumURL2)
        waitForNoExistence(app.staticTexts["XCUITests-Runner pasted from Fennec"])
        waitForExistence(app.buttons["TabLocationView.trackingProtectionButton"], timeout: 5)
        navigator.goto(TrackingProtectionContextMenuDetails)
        snapshot("TrackingProtectionEnabledPerSite-01")

        // Disable the toggle so that TP is off
        app.cells["tp.add-to-safelist"].tap()
        snapshot("TrackingProtectionDisabledPerSite-02")
    }

    func test9SettingsETP() {
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
}
