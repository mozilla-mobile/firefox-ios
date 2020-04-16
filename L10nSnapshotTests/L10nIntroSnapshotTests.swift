/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
let testPageBase2 = "http://www.example.com"
let loremIpsumURL2 = "\(testPageBase2)"

class L10nIntroSnapshotTests: L10nBaseSnapshotTests {
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

        navigator.openURL(loremIpsumURL2)
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
        navigator.openURL(loremIpsumURL2)
        navigator.goto(HistoryPanelContextMenu)
        snapshot("19HistoryTableContextMenu-01")
    }

    func test20BookmarksTableContextMenu() {
        navigator.openURL(loremIpsumURL2)
        navigator.performAction(Action.Bookmark)
        navigator.createNewTab()
        navigator.goto(BookmarksPanelContextMenu)
        snapshot("20BookmarksTableContextMenu-01")
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

    func test22ETPperSite() {
        // Website without blocked elements
        navigator.openURL(loremIpsumURL2)
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
