// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

let website_1 = [
    "url": "www.mozilla.org",
    "label": "Internet for people, not profit — Mozilla",
    "value": "mozilla.org"
]
let website_2 = [
    "url": "www.example.com",
    "label": "Example",
    "value": "example",
    "link": "More information...",
    "moreLinkLongPressUrl": "http://www.iana.org/domains/example",
    "moreLinkLongPressInfo": "iana"
]
let popUpTestUrl = path(forTestPage: "test-popup-blocker.html")

class NavigationTest: BaseTestCase {
    // https://testrail.stage.mozaws.net/index.php?/cases/view/2441488
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
        mozWaitForValueContains(app.textFields["url"], value: "test-example.html")
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.Toolbar.backButton].isEnabled)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.Toolbar.forwardButton].isEnabled)

        // Once a second url is open, back button is enabled but not the forward one till we go back to url_1
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        mozWaitForValueContains(app.textFields["url"], value: "test-mozilla-org.html")
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.Toolbar.backButton].isEnabled)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.Toolbar.forwardButton].isEnabled)
        // Go back to previous visited web site
        app.buttons[AccessibilityIdentifiers.Toolbar.backButton].tap()

        waitUntilPageLoad()
        mozWaitForValueContains(app.textFields["url"], value: "test-example.html")

        if iPad() {
            app.buttons[AccessibilityIdentifiers.Toolbar.forwardButton].tap()
        } else {
            // Go forward to next visited web site
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.forwardButton])
            app.buttons[AccessibilityIdentifiers.Toolbar.forwardButton].tap()
        }
        waitUntilPageLoad()
        mozWaitForValueContains(app.textFields["url"], value: "test-mozilla-org")
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2441489
    func testTapSignInShowsFxAFromTour() {
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        // Open FxAccount from tour option in settings menu and go throughout all the screens there
        navigator.goto(Intro_FxASignin)
        navigator.performAction(Action.OpenEmailToSignIn)
        mozWaitForElementToExist(app.webViews.firstMatch, timeout: TIMEOUT_LONG)
        mozWaitForElementToExist(app.webViews.staticTexts["Continue to your Mozilla account"])
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2441493
    func testTapSigninShowsFxAFromSettings() {
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)
        // Open FxAccount from settings menu and check the Sign in to Firefox screen
        let signInToFirefoxStaticText = app.tables[AccessibilityIdentifiers.Settings.tableViewController]
            .staticTexts[AccessibilityIdentifiers.Settings.FirefoxAccount.fxaSettingsButton]
        mozWaitForElementToExist(signInToFirefoxStaticText)
        signInToFirefoxStaticText.tap()
        checkFirefoxSyncScreenShownViaSettings()

        // After that it is possible to go back to Settings
        let closeButton = app.navigationBars["Client.FxAWebView"].buttons.element(boundBy: 0)
        mozWaitForElementToExist(closeButton)
        closeButton.tap()

        let closeButtonFxView = app.navigationBars[AccessibilityIdentifiers.Settings.FirefoxAccount.fxaNavigationBar]
            .buttons["Settings"]
        mozWaitForElementToExist(closeButtonFxView)
        closeButtonFxView.tap()
    }

    // Because the Settings menu does not stretch tot the top we need a different function to check 
    // if the Firefox Sync screen is shown
    private func checkFirefoxSyncScreenShownViaSettings() {
        mozWaitForElementToExist(
            app.navigationBars[AccessibilityIdentifiers.Settings.FirefoxAccount.fxaNavigationBar],
            timeout: TIMEOUT_LONG
        )
        app.buttons["EmailSignIn.button"].tap()
        mozWaitForElementToExist(app.webViews.textFields.element(boundBy: 0), timeout: TIMEOUT_LONG)

        let email = app.webViews.textFields.element(boundBy: 0)
        // Verify the placeholdervalues here for the textFields
        let mailPlaceholder = "Enter your email"
        let defaultMailPlaceholder = email.placeholderValue!
        XCTAssertEqual(mailPlaceholder, defaultMailPlaceholder, "The mail placeholder does not show the correct value")
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2441494
    func testTapSignInShowsFxAFromRemoteTabPanel() {
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        // Open FxAccount from remote tab panel and check the Sign in to Firefox screen
        navigator.goto(TabTray)
        navigator.performAction(Action.ToggleSyncMode)

        app.tables.buttons[AccessibilityIdentifiers.Settings.FirefoxAccount.fxaSettingsButton].tap()
        mozWaitForElementToExist(app.navigationBars["Sync and Save Data"])
        mozWaitForElementToExist(app.buttons["Use Email Instead"])
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2441495
    func testScrollsToTopWithMultipleTabs() {
        navigator.goto(TabTray)
        navigator.openURL(website_1["url"]!)
        waitUntilPageLoad()
        mozWaitForValueContains(app.textFields["url"], value: website_1["value"]!)
        let topElement = app.links["Mozilla"].firstMatch
        let bottomElement = app.webViews.links.staticTexts["Legal"]

        // Scroll to bottom
        scrollToElement(bottomElement)
        mozWaitForElementToExist(bottomElement)
        // Scroll to top
        scrollToElement(topElement, swipe: "down")
        mozWaitForElementToExist(topElement)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306836
    // Smoketest
    func testLongPressLinkOptions() {
        openContextMenuForArticleLink()
        XCTAssertTrue(app.buttons["Open in New Tab"].exists, "The option is not shown")
        XCTAssertTrue(app.buttons["Open in New Private Tab"].exists, "The option is not shown")
        XCTAssertTrue(app.buttons["Copy Link"].exists, "The option is not shown")
        XCTAssertTrue(app.buttons["Download Link"].exists, "The option is not shown")
        XCTAssertTrue(app.buttons["Share Link"].exists, "The option is not shown")
        XCTAssertTrue(app.buttons["Bookmark Link"].exists, "The option is not shown")
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2441496
    func testCopyLink() {
        longPressLinkOptions(optionSelected: "Copy Link")
        navigator.goto(NewTabScreen)
        app.textFields["url"].press(forDuration: 2)

        mozWaitForElementToExist(app.tables["Context Menu"])
        app.tables.otherElements[AccessibilityIdentifiers.Photon.pasteAction].tap()
        app.buttons["Go"].tap()
        waitUntilPageLoad()
        mozWaitForValueContains(app.textFields["url"], value: website_2["moreLinkLongPressInfo"]!)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2441497
    func testCopyLinkPrivateMode() {
        navigator.nowAt(NewTabScreen)
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        longPressLinkOptions(optionSelected: "Copy Link")
        navigator.goto(NewTabScreen)
        mozWaitForElementToExist(app.textFields["url"])
        app.textFields["url"].press(forDuration: 2)

        app.tables.otherElements[AccessibilityIdentifiers.Photon.pasteAction].tap()
        mozWaitForElementToExist(app.buttons["Go"])
        app.buttons["Go"].tap()
        waitUntilPageLoad()
        mozWaitForValueContains(app.textFields["url"], value: website_2["moreLinkLongPressInfo"]!)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2441923
    func testLongPressOnAddressBar() throws {
        // Long press on the URL requires copy & paste permission
        throw XCTSkip("Test needs to be updated")
        /*
            // This test is for populated clipboard only so we need to make sure there's something in Pasteboard
            app.textFields["address"].typeText("www.google.com")
            // Tapping two times when the text is not selected will reveal the menu
            app.textFields["address"].tap()
            mozWaitForElementToExist(app.textFields["address"])
            app.textFields["address"].tap()
            mozWaitForElementToExist(app.menuItems["Select All"])
            XCTAssertTrue(app.menuItems["Select All"].exists)
            XCTAssertTrue(app.menuItems["Select"].exists)

            // Tap on Select All option and make sure Copy, Cut, Paste, and Look Up are shown
            app.menuItems["Select All"].tap()
            mozWaitForElementToExist(app.menuItems["Copy"])
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
            mozWaitForElementToNotExist(app.staticTexts["XCUITests-Runner pasted from Fennec"])

            app.textFields["url"].press(forDuration: 3)
            app.tables.otherElements[StandardImageIdentifiers.Large.link].tap()

            sleep(2)
            app.textFields["url"].tap()
            // Since the textField value appears all selected first time is clicked
            // this workaround is necessary
            mozWaitForElementToNotExist(app.staticTexts["XCUITests-Runner pasted from Fennec"])
            app.textFields["address"].tap()
            mozWaitForElementToExist(app.menuItems["Copy"])
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
         */
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

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2441498
    func testDownloadLink() {
        longPressLinkOptions(optionSelected: "Download Link")
        mozWaitForElementToExist(app.tables["Context Menu"])
        XCTAssertTrue(app.tables["Context Menu"].otherElements[StandardImageIdentifiers.Large.download].exists)
        app.tables["Context Menu"].otherElements[StandardImageIdentifiers.Large.download].tap()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)
        mozWaitForElementToExist(app.tables["DownloadsTable"])
        // There should be one item downloaded. It's name and size should be shown
        let downloadedList = app.tables["DownloadsTable"].cells.count
        XCTAssertEqual(downloadedList, 1, "The number of items in the downloads table is not correct")
        XCTAssertTrue(app.tables.cells.staticTexts["example-domains.html"].exists)

        // Tap on the just downloaded link to check that the web page is loaded
        app.tables.cells.staticTexts["example-domains.html"].tap()
        waitUntilPageLoad()
        mozWaitForValueContains(app.textFields["url"], value: "example-domains.html")
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2441499
    func testShareLink() {
        longPressLinkOptions(optionSelected: "Share Link")
        mozWaitForElementToExist(app.cells["Copy"], timeout: TIMEOUT)
        if !iPad() {
            mozWaitForElementToExist(app.scrollViews.staticTexts["Messages"], timeout: TIMEOUT)
        }
        if #unavailable(iOS 17) {
            mozWaitForElementToExist(app.scrollViews.cells["XCElementSnapshotPrivilegedValuePlaceholder"], timeout: TIMEOUT)
        } else {
            mozWaitForElementToExist(app.scrollViews.staticTexts["Reminders"], timeout: TIMEOUT)
        }
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2441500
    func testShareLinkPrivateMode() {
        navigator.nowAt(NewTabScreen)
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        longPressLinkOptions(optionSelected: "Share Link")
        mozWaitForElementToExist(app.cells["Copy"], timeout: TIMEOUT)
        if !iPad() {
            mozWaitForElementToExist(app.scrollViews.staticTexts["Messages"], timeout: TIMEOUT)
        }
        if #unavailable(iOS 17) {
            mozWaitForElementToExist(app.scrollViews.cells["XCElementSnapshotPrivilegedValuePlaceholder"], timeout: TIMEOUT)
        } else {
            mozWaitForElementToExist(app.scrollViews.staticTexts["Reminders"], timeout: TIMEOUT)
        }
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2441776
    // Smoketest
    func testPopUpBlocker() throws {
        throw XCTSkip("This test is flakey")
//        // Check that it is enabled by default
//        navigator.nowAt(BrowserTab)
//        mozWaitForElementToExist(app.buttons["TabToolbar.menuButton"], timeout: TIMEOUT)
//        navigator.goto(SettingsScreen)
//        mozWaitForElementToExist(app.tables[AccessibilityIdentifiers.Settings.tableViewController])
//        let switchBlockPopUps = app.tables.cells.switches["blockPopups"]
//        let switchValue = switchBlockPopUps.value!
//        XCTAssertEqual(switchValue as? String, "1")
//
//        // Check that there are no pop ups
//        navigator.openURL(popUpTestUrl)
//        mozWaitForValueContains(app.textFields["url"], value: "blocker.html")
//        mozWaitForElementToExist(app.webViews.staticTexts["Blocked Element"])
//
//        let numTabs = app.buttons["Show Tabs"].value
//        XCTAssertEqual("1", numTabs as? String, "There should be only on tab")
//
//        // Now disable the Block PopUps option
//        navigator.goto(BrowserTabMenu)
//        navigator.goto(SettingsScreen)
//        mozWaitForElementToExist(switchBlockPopUps, timeout: TIMEOUT)
//        switchBlockPopUps.tap()
//        let switchValueAfter = switchBlockPopUps.value!
//        XCTAssertEqual(switchValueAfter as? String, "0")
//
//        // Check that now pop ups are shown, two sites loaded
//        navigator.openURL(popUpTestUrl)
//        waitUntilPageLoad()
//        mozWaitForValueContains(app.textFields["url"], value: "example.com")
//        let numTabsAfter = app.buttons["Show Tabs"].value
//        XCTAssertNotEqual("1", numTabsAfter as? String, "Several tabs are open")
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306858
    // Smoketest
    func testSSL() {
        navigator.nowAt(NewTabScreen)

        navigator.openURL("https://expired.badssl.com/")
        mozWaitForElementToExist(app.buttons["Advanced"], timeout: TIMEOUT)
        app.buttons["Advanced"].tap()

        mozWaitForElementToExist(app.links["Visit site anyway"])
        app.links["Visit site anyway"].tap()
        mozWaitForElementToExist(app.webViews.otherElements["expired.badssl.com"], timeout: TIMEOUT)
        XCTAssertTrue(app.webViews.otherElements["expired.badssl.com"].exists)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307022
    // In this test, the parent window opens a child and in the child it creates a fake link 'link-created-by-parent'
    func testWriteToChildPopupTab() {
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)
        mozWaitForElementToExist(app.tables[AccessibilityIdentifiers.Settings.tableViewController])
        let switchBlockPopUps = app.tables.cells.switches["blockPopups"]
        switchBlockPopUps.tap()
        let switchValueAfter = switchBlockPopUps.value!
        XCTAssertEqual(switchValueAfter as? String, "0")
        navigator.goto(HomePanelsScreen)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        navigator.openURL(path(forTestPage: "test-window-opener.html"))
        mozWaitForElementToExist(app.links["link-created-by-parent"], timeout: TIMEOUT)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307020
    // Smoketest
    func testVerifyBrowserTabMenu() {
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], timeout: TIMEOUT)
        navigator.nowAt(NewTabScreen)
        navigator.goto(BrowserTabMenu)
        mozWaitForElementToExist(app.tables["Context Menu"])

        XCTAssertTrue(app.tables.otherElements[StandardImageIdentifiers.Large.bookmarkTrayFill].exists)
        XCTAssertTrue(app.tables.otherElements[StandardImageIdentifiers.Large.history].exists)
        XCTAssertTrue(app.tables.otherElements[StandardImageIdentifiers.Large.download].exists)
        XCTAssertTrue(app.tables.otherElements[StandardImageIdentifiers.Large.readingList].exists)
        XCTAssertTrue(app.tables.otherElements[StandardImageIdentifiers.Large.login].exists)
        XCTAssertTrue(app.tables.otherElements[StandardImageIdentifiers.Large.sync].exists)
        XCTAssertTrue(app.tables.otherElements[StandardImageIdentifiers.Large.nightMode].exists)
        XCTAssertTrue(app.tables.otherElements[StandardImageIdentifiers.Large.whatsNew].exists)
        XCTAssertTrue(app.tables.otherElements[StandardImageIdentifiers.Large.helpCircle].exists)
        XCTAssertTrue(app.tables.otherElements[StandardImageIdentifiers.Large.edit].exists)
        XCTAssertTrue(app.tables.otherElements[StandardImageIdentifiers.Large.settings].exists)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2441775
    // Smoketest
    func testURLBar() {
        let urlBar = app.textFields["url"]
        mozWaitForElementToExist(urlBar, timeout: TIMEOUT)
        urlBar.tap()

        let addressBar = app.textFields["address"]
        XCTAssertTrue(addressBar.value(forKey: "hasKeyboardFocus") as? Bool ?? false)

        // These instances are false positives of the swiftlint configuration
        // swiftlint:disable empty_count
        XCTAssert(app.keyboards.count > 0, "The keyboard is not shown")
        app.typeText("example.com\n")

        mozWaitForValueContains(urlBar, value: "example.com/")
        XCTAssertFalse(app.keyboards.count > 0, "The keyboard is shown")
        // swiftlint:enable empty_count
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2441772
    func testOpenInNewTab() {
        // Long-tap on an article link. Choose "Open in New Tab".
        openContextMenuForArticleLink()
        mozWaitForElementToExist(app.buttons["Open in New Tab"])
        app.buttons["Open in New Tab"].tap()
        // A new tab loading the article page should open
        navigator.goto(TabTray)
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].cells.staticTexts["Example Domain"])
        let numTabs = app.otherElements["Tabs Tray"].cells.count
        XCTAssertEqual(numTabs, 2, "Total number of opened tabs should be 2")
        XCTAssertTrue(app.otherElements["Tabs Tray"].cells.elementContainingText("Example Domain.").exists)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2441773
    func testOpenInNewPrivateTab() {
        // Long-tap on an article link. Choose "Open in New Private Tab".
        openContextMenuForArticleLink()
        mozWaitForElementToExist(app.buttons["Open in New Private Tab"])
        app.buttons["Open in New Private Tab"].tap()
        // The article is loaded in a new private tab
        navigator.goto(TabTray)
        var numTabs = app.otherElements["Tabs Tray"].cells.count
        XCTAssertEqual(numTabs, 1, "Total number of regulat opened tabs should be 1")
        XCTAssertTrue(app.otherElements["Tabs Tray"].cells.elementContainingText("Example Domain.").exists)
        if iPad() {
            app.buttons["Private"].tap()
        } else {
            app.buttons["privateModeLarge"].tap()
        }
        numTabs = app.otherElements["Tabs Tray"].cells.count
        XCTAssertEqual(numTabs, 1, "Total number of private opened tabs should be 1")
        XCTAssertTrue(app.otherElements["Tabs Tray"].cells.staticTexts["Example Domains"].exists)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2441774
    func testBookmarkLink() {
        // Long-tap on an article link. Choose "Bookmark Link".
        openContextMenuForArticleLink()
        mozWaitForElementToExist(app.buttons["Bookmark Link"])
        app.buttons["Bookmark Link"].tap()
        // The link has been added to the Bookmarks panel in Library
        navigator.goto(LibraryPanel_Bookmarks)
        mozWaitForElementToExist(app.tables["Bookmarks List"], timeout: 5)
        XCTAssertTrue(app.tables["Bookmarks List"].staticTexts[website_2["link"]!].exists)
    }

    private func openContextMenuForArticleLink() {
        navigator.openURL(path(forTestPage: "test-example.html"))
        mozWaitForElementToExist(app.webViews.links[website_2["link"]!], timeout: TIMEOUT_LONG)
        app.webViews.links[website_2["link"]!].press(forDuration: 2)
        mozWaitForElementToExist(app.otherElements.collectionViews.element(boundBy: 0), timeout: TIMEOUT)
    }
 }
