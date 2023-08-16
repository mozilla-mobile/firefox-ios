// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

let website_1 = ["url": "www.mozilla.org", "label": "Internet for people, not profit — Mozilla", "value": "mozilla.org"]
let website_2 = ["url": "www.example.com", "label": "Example", "value": "example", "link": "More information...", "moreLinkLongPressUrl": "http://www.iana.org/domains/example", "moreLinkLongPressInfo": "iana"]
let urlAddons = "addons.mozilla.org"
let urlGoogle = "www.google.com"
let popUpTestUrl = path(forTestPage: "test-popup-blocker.html")

let requestMobileSiteLabel = "Request Mobile Site"
let requestDesktopSiteLabel = "Request Desktop Site"

class NavigationTest: BaseTestCase {
    func testNavigation() {
        let urlPlaceholder = "Search or enter address"
        XCTAssert(app.textFields["url"].exists)
        let defaultValuePlaceholder = app.textFields["url"].placeholderValue!

        // Check the url placeholder text and that the back and forward buttons are disabled
        XCTAssert(urlPlaceholder == defaultValuePlaceholder)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.Toolbar.backButton].isEnabled)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.Toolbar.forwardButton].isEnabled)

        if iPad() {
            app.textFields["url"].tap()
            // Once an url has been open, the back button is enabled but not the forward button
            navigator.performAction(Action.CloseURLBarOpen)
            navigator.nowAt(NewTabScreen)
        }
        navigator.openURL(path(forTestPage: "test-example.html"))
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: "test-example.html")
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.Toolbar.backButton].isEnabled)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.Toolbar.forwardButton].isEnabled)

        // Once a second url is open, back button is enabled but not the forward one till we go back to url_1
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: "test-mozilla-org.html")
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.Toolbar.backButton].isEnabled)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.Toolbar.forwardButton].isEnabled)
        // Go back to previous visited web site
        app.buttons[AccessibilityIdentifiers.Toolbar.backButton].tap()

        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: "test-example.html")

        if iPad() {
            app.buttons[AccessibilityIdentifiers.Toolbar.forwardButton].tap()
        } else {
            // Go forward to next visited web site
            waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.forwardButton])
            app.buttons[AccessibilityIdentifiers.Toolbar.forwardButton].tap()
        }
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: "test-mozilla-org")
    }

    func testTapSignInShowsFxAFromTour() {
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        // Open FxAccount from tour option in settings menu and go throughout all the screens there
        navigator.goto(Intro_FxASignin)
        navigator.performAction(Action.OpenEmailToSignIn)
        checkFirefoxSyncScreenShown()
    }

    func testTapSigninShowsFxAFromSettings() {
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)
        // Open FxAccount from settings menu and check the Sign in to Firefox screen
        let signInToFirefoxStaticText = app.tables[AccessibilityIdentifiers.Settings.tableViewController].staticTexts[AccessibilityIdentifiers.Settings.FirefoxAccount.fxaSettingsButton]
        waitForExistence(signInToFirefoxStaticText)
        signInToFirefoxStaticText.tap()
        checkFirefoxSyncScreenShownViaSettings()

        // After that it is possible to go back to Settings
        let closeButton = app.navigationBars["Client.FxAWebView"].buttons.element(boundBy: 0)
        closeButton.tap()

        let closeButtonFxView = app.navigationBars[AccessibilityIdentifiers.Settings.FirefoxAccount.fxaNavigationBar].buttons["Settings"]
        closeButtonFxView.tap()
    }

    // Because the Settings menu does not stretch tot the top we need a different function to check if the Firefox Sync screen is shown
    private func checkFirefoxSyncScreenShownViaSettings() {
        waitForExistence(app.navigationBars[AccessibilityIdentifiers.Settings.FirefoxAccount.fxaNavigationBar], timeout: TIMEOUT_LONG)
        app.buttons["EmailSignIn.button"].tap()
        waitForExistence(app.webViews.textFields.element(boundBy: 0), timeout: TIMEOUT_LONG)

        let email = app.webViews.textFields.element(boundBy: 0)
        // Verify the placeholdervalues here for the textFields
        let mailPlaceholder = "Enter your email"
        let defaultMailPlaceholder = email.placeholderValue!
        XCTAssertEqual(mailPlaceholder, defaultMailPlaceholder, "The mail placeholder does not show the correct value")
    }

    func testTapSignInShowsFxAFromRemoteTabPanel() {
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        // Open FxAccount from remote tab panel and check the Sign in to Firefox screen
        navigator.goto(TabTray)
        navigator.performAction(Action.ToggleSyncMode)

        app.tables.buttons[AccessibilityIdentifiers.Settings.FirefoxAccount.fxaSettingsButton].tap()
        checkFirefoxSyncScreenShown()
    }

    private func checkFirefoxSyncScreenShown() {
        // Disable check, page load issues on iOS13.3 sims, issue #5937
        waitForExistence(app.webViews.firstMatch, timeout: TIMEOUT_LONG)
    }

    func testScrollsToTopWithMultipleTabs() {
        navigator.goto(TabTray)
        navigator.openURL(website_1["url"]!)
        waitForValueContains(app.textFields["url"], value: website_1["value"]!)
        // Element at the TOP. TBChanged once the web page is correctly shown
        let topElement = app.links.staticTexts["Mozilla"].firstMatch

        // Element at the BOTTOM
        let bottomElement = app.webViews.links.staticTexts["Legal"]

        // Scroll to bottom
        bottomElement.tap()
        waitUntilPageLoad()
        app.buttons[AccessibilityIdentifiers.Toolbar.backButton].tap()
        waitUntilPageLoad()

        // Scroll to top
        topElement.tap()
        waitForExistence(topElement)
    }

    // Smoketest
    func testLongPressLinkOptions() {
        navigator.openURL(path(forTestPage: "test-example.html"))
        waitForExistence(app.webViews.links[website_2["link"]!], timeout: TIMEOUT_LONG)
        app.webViews.links[website_2["link"]!].press(forDuration: 2)
        waitForExistence(app.otherElements.collectionViews.element(boundBy: 0), timeout: TIMEOUT)

        XCTAssertTrue(app.buttons["Open in New Tab"].exists, "The option is not shown")
        XCTAssertTrue(app.buttons["Open in New Private Tab"].exists, "The option is not shown")
        XCTAssertTrue(app.buttons["Copy Link"].exists, "The option is not shown")
        XCTAssertTrue(app.buttons["Download Link"].exists, "The option is not shown")
        XCTAssertTrue(app.buttons["Share Link"].exists, "The option is not shown")
        XCTAssertTrue(app.buttons["Bookmark Link"].exists, "The option is not shown")
    }

    // Only testing Share and Copy Link, the other two options are already covered in other tests
    func testCopyLink() {
        longPressLinkOptions(optionSelected: "Copy Link")
        navigator.goto(NewTabScreen)
        app.textFields["url"].press(forDuration: 2)

        waitForExistence(app.tables["Context Menu"])
        app.tables.otherElements[AccessibilityIdentifiers.Photon.pasteAction].tap()
        app.buttons["Go"].tap()
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: website_2["moreLinkLongPressInfo"]!)
    }

    func testCopyLinkPrivateMode() {
        navigator.nowAt(NewTabScreen)
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        longPressLinkOptions(optionSelected: "Copy Link")
        navigator.goto(NewTabScreen)
        waitForExistence(app.textFields["url"])
        app.textFields["url"].press(forDuration: 2)

        app.tables.otherElements[AccessibilityIdentifiers.Photon.pasteAction].tap()
        waitForExistence(app.buttons["Go"])
        app.buttons["Go"].tap()
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: website_2["moreLinkLongPressInfo"]!)
    }

    func testLongPressOnAddressBar() throws {
        if processIsTranslatedStr() == m1Rosetta {
            // Long press on the URL requires copy & paste permission
            throw XCTSkip("Copy & paste may not work on M1")
        } else {
            // This test is for populated clipboard only so we need to make sure there's something in Pasteboard
            app.textFields["address"].typeText("www.google.com")
            // Tapping two times when the text is not selected will reveal the menu
            app.textFields["address"].tap()
            waitForExistence(app.textFields["address"])
            app.textFields["address"].tap()
            waitForExistence(app.menuItems["Select All"])
            XCTAssertTrue(app.menuItems["Select All"].exists)
            XCTAssertTrue(app.menuItems["Select"].exists)

            // Tap on Select All option and make sure Copy, Cut, Paste, and Look Up are shown
            app.menuItems["Select All"].tap()
            waitForExistence(app.menuItems["Copy"])
            if iPad() {
                XCTAssertTrue(app.menuItems["Copy"].exists)
                XCTAssertTrue(app.menuItems["Cut"].exists)
                XCTAssertTrue(app.menuItems["Paste"].exists)
                XCTAssertTrue(app.menuItems["Open Link"].exists)
                XCTAssertTrue(app.menuItems["Add to Reading List"].exists)
                XCTAssertTrue(app.menuItems["Share…"].exists)
                XCTAssertTrue(app.menuItems["Paste & Go"].exists)
            } else {
                XCTAssertTrue(app.menuItems["Copy"].exists)
                XCTAssertTrue(app.menuItems["Cut"].exists)
                XCTAssertTrue(app.menuItems["Paste"].exists)
                XCTAssertTrue(app.menuItems["Open Link"].exists)
            }

            app.textFields["address"].typeText("\n")
            waitUntilPageLoad()
            waitForNoExistence(app.staticTexts["XCUITests-Runner pasted from Fennec"])

            app.textFields["url"].press(forDuration: 3)
            app.tables.otherElements[StandardImageIdentifiers.Large.link].tap()

            sleep(2)
            app.textFields["url"].tap()
            // Since the textField value appears all selected first time is clicked
            // this workaround is necessary
            waitForNoExistence(app.staticTexts["XCUITests-Runner pasted from Fennec"])
            app.textFields["address"].tap()
            waitForExistence(app.menuItems["Copy"])
            if iPad() {
                XCTAssertTrue(app.menuItems["Cut"].exists)
                XCTAssertTrue(app.menuItems["Copy"].exists)
                XCTAssertTrue(app.menuItems["Open Link"].exists)
                XCTAssertTrue(app.menuItems["Add to Reading List"].exists)
                XCTAssertTrue(app.menuItems["Paste"].exists)
            } else {
                XCTAssertTrue(app.menuItems["Copy"].exists)
                XCTAssertTrue(app.menuItems["Cut"].exists)
                XCTAssertTrue(app.menuItems["Open Link"].exists)
            }
        }
    }

    private func longPressLinkOptions(optionSelected: String) {
        navigator.nowAt(NewTabScreen)
        if app.buttons["Done"].exists {
            app.buttons["Done"].tap()
        }
        navigator.goto(ClearPrivateDataSettings)
        app.cells.switches["Downloaded Files"].tap()
        navigator.performAction(Action.AcceptClearPrivateData)

        navigator.goto(HomePanelsScreen)
        navigator.openURL(path(forTestPage: "test-example.html"))
        waitUntilPageLoad()
        app.webViews.links[website_2["link"]!].press(forDuration: 2)
        app.buttons[optionSelected].tap()
    }

    func testDownloadLink() {
        longPressLinkOptions(optionSelected: "Download Link")
        waitForExistence(app.tables["Context Menu"])
        XCTAssertTrue(app.tables["Context Menu"].otherElements[StandardImageIdentifiers.Large.download].exists)
        app.tables["Context Menu"].otherElements[StandardImageIdentifiers.Large.download].tap()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)
        waitForExistence(app.tables["DownloadsTable"])
        // There should be one item downloaded. It's name and size should be shown
        let downloadedList = app.tables["DownloadsTable"].cells.count
        XCTAssertEqual(downloadedList, 1, "The number of items in the downloads table is not correct")
        XCTAssertTrue(app.tables.cells.staticTexts["example-domains.html"].exists)

        // Tap on the just downloaded link to check that the web page is loaded
        app.tables.cells.staticTexts["example-domains.html"].tap()
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: "example-domains.html")
    }

    func testShareLink() {
        longPressLinkOptions(optionSelected: "Share Link")
        waitForExistence(app.cells["Copy"], timeout: TIMEOUT)
        XCTAssertTrue(app.cells["Copy"].exists, "The share menu is not shown")
    }

    func testShareLinkPrivateMode() {
        navigator.nowAt(NewTabScreen)
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        longPressLinkOptions(optionSelected: "Share Link")
        waitForExistence(app.cells["Copy"], timeout: TIMEOUT)
        XCTAssertTrue(app.cells["Copy"].exists, "The share menu is not shown")
    }

    // Smoketest
    func testPopUpBlocker() throws {
        throw XCTSkip("This test is flakey")
//        // Check that it is enabled by default
//        navigator.nowAt(BrowserTab)
//        waitForExistence(app.buttons["TabToolbar.menuButton"], timeout: TIMEOUT)
//        navigator.goto(SettingsScreen)
//        waitForExistence(app.tables[AccessibilityIdentifiers.Settings.tableViewController])
//        let switchBlockPopUps = app.tables.cells.switches["blockPopups"]
//        let switchValue = switchBlockPopUps.value!
//        XCTAssertEqual(switchValue as? String, "1")
//
//        // Check that there are no pop ups
//        navigator.openURL(popUpTestUrl)
//        waitForValueContains(app.textFields["url"], value: "blocker.html")
//        waitForExistence(app.webViews.staticTexts["Blocked Element"])
//
//        let numTabs = app.buttons["Show Tabs"].value
//        XCTAssertEqual("1", numTabs as? String, "There should be only on tab")
//
//        // Now disable the Block PopUps option
//        navigator.goto(BrowserTabMenu)
//        navigator.goto(SettingsScreen)
//        waitForExistence(switchBlockPopUps, timeout: TIMEOUT)
//        switchBlockPopUps.tap()
//        let switchValueAfter = switchBlockPopUps.value!
//        XCTAssertEqual(switchValueAfter as? String, "0")
//
//        // Check that now pop ups are shown, two sites loaded
//        navigator.openURL(popUpTestUrl)
//        waitUntilPageLoad()
//        waitForValueContains(app.textFields["url"], value: "example.com")
//        let numTabsAfter = app.buttons["Show Tabs"].value
//        XCTAssertNotEqual("1", numTabsAfter as? String, "Several tabs are open")
    }

    // Smoketest
    func testSSL() {
        navigator.nowAt(NewTabScreen)

        navigator.openURL("https://expired.badssl.com/")
        waitForExistence(app.buttons["Advanced"], timeout: TIMEOUT)
        app.buttons["Advanced"].tap()

        waitForExistence(app.links["Visit site anyway"])
        app.links["Visit site anyway"].tap()
        waitForExistence(app.webViews.otherElements["expired.badssl.com"], timeout: TIMEOUT)
        XCTAssertTrue(app.webViews.otherElements["expired.badssl.com"].exists)
    }

    // In this test, the parent window opens a child and in the child it creates a fake link 'link-created-by-parent'
    func testWriteToChildPopupTab() {
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)
        waitForExistence(app.tables[AccessibilityIdentifiers.Settings.tableViewController])
        let switchBlockPopUps = app.tables.cells.switches["blockPopups"]
        switchBlockPopUps.tap()
        let switchValueAfter = switchBlockPopUps.value!
        XCTAssertEqual(switchValueAfter as? String, "0")
        navigator.goto(HomePanelsScreen)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        navigator.openURL(path(forTestPage: "test-window-opener.html"))
        waitForExistence(app.links["link-created-by-parent"], timeout: TIMEOUT)
    }

    // Smoketest
    func testVerifyBrowserTabMenu() {
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], timeout: TIMEOUT)
        navigator.nowAt(NewTabScreen)
        navigator.goto(BrowserTabMenu)
        waitForExistence(app.tables["Context Menu"])

        XCTAssertTrue(app.tables.otherElements[StandardImageIdentifiers.Large.bookmarkTrayFill].exists)
        XCTAssertTrue(app.tables.otherElements[StandardImageIdentifiers.Large.history].exists)
        XCTAssertTrue(app.tables.otherElements[StandardImageIdentifiers.Large.download].exists)
        XCTAssertTrue(app.tables.otherElements[ImageIdentifiers.readingList].exists)
        XCTAssertTrue(app.tables.otherElements[StandardImageIdentifiers.Large.login].exists)
        XCTAssertTrue(app.tables.otherElements[ImageIdentifiers.sync].exists)
        XCTAssertTrue(app.tables.otherElements[ImageIdentifiers.nightMode].exists)
        XCTAssertTrue(app.tables.otherElements[ImageIdentifiers.whatsNew].exists)
        XCTAssertTrue(app.tables.otherElements[ImageIdentifiers.settings].exists)
        // TODO: Add new options added [Customize home page, new tab, help]
        // Customize home page, help and whatsNew are only there when we are on the homepage menu
    }

    // Smoketest
    func testURLBar() {
        let urlBar = app.textFields["url"]
        waitForExistence(urlBar, timeout: TIMEOUT)
        urlBar.tap()

        let addressBar = app.textFields["address"]
        XCTAssertTrue(addressBar.value(forKey: "hasKeyboardFocus") as? Bool ?? false)

        // These instances are false positives of the swiftlint configuration
        // swiftlint:disable empty_count
        XCTAssert(app.keyboards.count > 0, "The keyboard is not shown")
        app.typeText("example.com\n")

//        waitUntilPageLoad()
        waitForValueContains(urlBar, value: "example.com/")
        XCTAssertFalse(app.keyboards.count > 0, "The keyboard is shown")
        // swiftlint:enable empty_count
    }
 }
