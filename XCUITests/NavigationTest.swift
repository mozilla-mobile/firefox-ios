/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class NavigationTest: BaseTestCase {
    func testNavigation() {
        navigator.goto(URLBarOpen)
        let urlPlaceholder = "Search or enter address"
        XCTAssert(Base.app.textFields["url"].exists)
        let defaultValuePlaceholder = Base.app.textFields["url"].placeholderValue!

        // Check the url placeholder text and that the back and forward buttons are disabled
        XCTAssert(urlPlaceholder == defaultValuePlaceholder)
        if Base.helper.iPad() {
            Base.app.buttons["urlBar-cancel"].tap()
            XCTAssertFalse(Base.app.buttons["URLBarView.backButton"].isEnabled)
            XCTAssertFalse(Base.app.buttons["Forward"].isEnabled)
            Base.app.textFields["url"].tap()
        } else {
            XCTAssertFalse(Base.app.buttons["TabToolbar.backButton"].isEnabled)
            XCTAssertFalse(Base.app.buttons["TabToolbar.forwardButton"].isEnabled)
        }

        // Once an url has been open, the back button is enabled but not the forward button
        navigator.openURL(Base.helper.path(forTestPage: "test-example.html"))
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForValueContains(Base.app.textFields["url"], value: "test-example.html")
        if Base.helper.iPad() {
            XCTAssertTrue(Base.app.buttons["URLBarView.backButton"].isEnabled)
            XCTAssertFalse(Base.app.buttons["Forward"].isEnabled)
        } else {
            XCTAssertTrue(Base.app.buttons["TabToolbar.backButton"].isEnabled)
            XCTAssertFalse(Base.app.buttons["TabToolbar.forwardButton"].isEnabled)
        }

        // Once a second url is open, back button is enabled but not the forward one till we go back to url_1
        navigator.openURL(Base.helper.path(forTestPage: "test-mozilla-org.html"))
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForValueContains(Base.app.textFields["url"], value: "test-mozilla-org.html")
        if Base.helper.iPad() {
            XCTAssertTrue(Base.app.buttons["URLBarView.backButton"].isEnabled)
            XCTAssertFalse(Base.app.buttons["Forward"].isEnabled)
            // Go back to previous visited web site
            Base.app.buttons["URLBarView.backButton"].tap()
        } else {
            XCTAssertTrue(Base.app.buttons["TabToolbar.backButton"].isEnabled)
            XCTAssertFalse(Base.app.buttons["TabToolbar.forwardButton"].isEnabled)
            // Go back to previous visited web site
            Base.app.buttons["TabToolbar.backButton"].tap()
        }
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForValueContains(Base.app.textFields["url"], value: "test-example.html")

        if Base.helper.iPad() {
            Base.app.buttons["Forward"].tap()
        } else {
            // Go forward to next visited web site
            Base.app.buttons["TabToolbar.forwardButton"].tap()
        }
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForValueContains(Base.app.textFields["url"], value: "test-mozilla-org")
    }

    func testTapSignInShowsFxAFromTour() {
        // Open FxAccount from tour option in settings menu and go throughout all the screens there
        navigator.goto(Intro_FxASignin)
        checkFirefoxSyncScreenShown()

        // Disabled due to issue 5937, not possible to tap on Close button
        // Go back to NewTabScreen
        // navigator.goto(HomePanelsScreen)
        // Base.helper.waitForExistence(Base.app.cells["TopSitesCell"])
    }
    
    func testTapSigninShowsFxAFromSettings() {
        navigator.goto(SettingsScreen)
        // Open FxAccount from settings menu and check the Sign in to Firefox scren
        let signInToFirefoxStaticText = Base.app.tables["AppSettingsTableViewController.tableView"].staticTexts["Sign in to Sync"]
        signInToFirefoxStaticText.tap()
        checkFirefoxSyncScreenShownViaSettings()

        // After that it is possible to go back to Settings
        let settingsButton = Base.app.navigationBars["Client.FxAWebView"].buttons["Settings"]
        settingsButton.tap()
    }
    
    // Beacuse the Settings menu does not stretch tot the top we need a different function to check if the Firefox Sync screen is shown
    private func checkFirefoxSyncScreenShownViaSettings() {
        Base.helper.waitForExistence(Base.app.navigationBars["Client.FxAWebView"], timeout: 20)
        Base.helper.waitForExistence(Base.app.webViews.textFields.element(boundBy: 0), timeout:20)
        let email = Base.app.webViews.textFields.element(boundBy: 0)
        // Verify the placeholdervalues here for the textFields
        let mailPlaceholder = "Email"
        let defaultMailPlaceholder = email.placeholderValue!
        XCTAssertEqual(mailPlaceholder, defaultMailPlaceholder, "The mail placeholder does not show the correct value")
    }

    func testTapSignInShowsFxAFromRemoteTabPanel() {
        // Open FxAccount from remote tab panel and check the Sign in to Firefox scren
        navigator.goto(LibraryPanel_SyncedTabs)

        Base.app.tables.buttons["Sign in to Sync"].tap()
        checkFirefoxSyncScreenShown()
        
        Base.app.navigationBars["Client.FxAWebView"].buttons["Close"].tap()
        navigator.nowAt(LibraryPanel_SyncedTabs)
    }

    private func checkFirefoxSyncScreenShown() {
        // Disable check, page load issues on iOS13.3 sims, issue #5937
        Base.helper.waitForExistence(Base.app.webViews.firstMatch, timeout: 20)
        // Workaround BB iOS13
//        Base.helper.waitForExistence(Base.app.navigationBars["Client.FxAContentView"], timeout: 60)
//        if isTablet {
//            Base.helper.waitForExistence(Base.app.webViews.textFields.element(boundBy: 0), timeout: 40)
//            let email = Base.app.webViews.textFields.element(boundBy: 0)
//            // Verify the placeholdervalues here for the textFields
//            let mailPlaceholder = "Email"
//            let defaultMailPlaceholder = email.placeholderValue!
//            XCTAssertEqual(mailPlaceholder, defaultMailPlaceholder, "The mail placeholder does not show the correct value")
//        } else {
//            Base.helper.waitForExistence(Base.app.textFields.element(boundBy: 0), timeout: 40)
//            let email = Base.app.textFields.element(boundBy: 0)
//            XCTAssertTrue(email.exists) // the email field
//            // Verify the placeholdervalues here for the textFields
//            let mailPlaceholder = "Email"
//            let defaultMailPlaceholder = email.placeholderValue!
//            XCTAssertEqual(mailPlaceholder, defaultMailPlaceholder, "The mail placeholder does not show the correct value")
//        }
    }

    func testScrollsToTopWithMultipleTabs() {
        navigator.goto(TabTray)
        navigator.openURL(Constants.website_1["url"]!)
        Base.helper.waitForValueContains(Base.app.textFields["url"], value: Constants.website_1["value"]!)
        // Element at the TOP. TBChanged once the web page is correclty shown
        let topElement = Base.app.links.staticTexts["Mozilla"].firstMatch

        // Element at the BOTTOM
        let bottomElement = Base.app.webViews.links.staticTexts["Legal"]

        // Scroll to bottom
        bottomElement.tap()
        Base.helper.waitUntilPageLoad()
        if Base.helper.iPad() {
            Base.app.buttons["URLBarView.backButton"].tap()
        } else {
            Base.app.buttons["TabToolbar.backButton"].tap()
        }
        Base.helper.waitUntilPageLoad()

        // Scroll to top
        topElement.tap()
        Base.helper.waitForExistence(topElement)
    }

    // Smoketest
    func testLongPressLinkOptions() {
        navigator.openURL(Base.helper.path(forTestPage: "test-example.html"))
        Base.helper.waitForExistence(Base.app.webViews.links[Constants.website_2["link"]!], timeout: 30)
        Base.app.webViews.links[Constants.website_2["link"]!].press(forDuration: 2)
        Base.helper.waitForExistence(Base.app.scrollViews.staticTexts[Constants.website_2["moreLinkLongPressUrl"]!])

        XCTAssertTrue(Base.app.buttons["Open in New Tab"].exists, "The option is not shown")
        XCTAssertTrue(Base.app.buttons["Open in New Private Tab"].exists, "The option is not shown")
        XCTAssertTrue(Base.app.buttons["Copy Link"].exists, "The option is not shown")
        XCTAssertTrue(Base.app.buttons["Download Link"].exists, "The option is not shown")
        XCTAssertTrue(Base.app.buttons["Share Link"].exists, "The option is not shown")
        XCTAssertTrue(Base.app.buttons["Bookmark Link"].exists, "The option is not shown")
    }

    func testLongPressLinkOptionsPrivateMode() {
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(Base.helper.path(forTestPage: "test-example.html"))
        Base.app.webViews.links[Constants.website_2["link"]!].press(forDuration: 2)
        Base.helper.waitForExistence(Base.app.scrollViews.staticTexts[Constants.website_2["moreLinkLongPressUrl"]!])
        XCTAssertFalse(Base.app.buttons["Open in New Tab"].exists, "The option is not shown")
        XCTAssertTrue(Base.app.buttons["Open in New Private Tab"].exists, "The option is not shown")
        XCTAssertTrue(Base.app.buttons["Copy Link"].exists, "The option is not shown")
        XCTAssertTrue(Base.app.buttons["Download Link"].exists, "The option is not shown")
    }
    // Only testing Share and Copy Link, the other two options are already covered in other tests
    func testCopyLink() {
        longPressLinkOptions(optionSelected: "Copy Link")
        navigator.goto(NewTabScreen)
        Base.app.textFields["url"].press(forDuration: 2)

        Base.helper.waitForExistence(Base.app.tables["Context Menu"])
        Base.app.tables.cells["menu-Paste"].tap()
        Base.app.buttons["Go"].tap()
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForValueContains(Base.app.textFields["url"], value: Constants.website_2["moreLinkLongPressInfo"]!)
    }

    func testCopyLinkPrivateMode() {
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        longPressLinkOptions(optionSelected: "Copy Link")
        navigator.goto(NewTabScreen)
        Base.app.textFields["url"].press(forDuration: 2)

        Base.app.tables.cells["menu-Paste"].tap()
        Base.app.buttons["Go"].tap()
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForValueContains(Base.app.textFields["url"], value: Constants.website_2["moreLinkLongPressInfo"]!)
    }

    /* Disabled due to issue 5581
    func testLongPressOnAddressBar() {
        //This test is for populated clipboard only so we need to make sure there's something in Pasteboard
        navigator.goto(URLBarOpen)
        Base.app.textFields["address"].typeText("www.google.com\n")
        Base.helper.waitUntilPageLoad()
        Base.app.textFields["url"].press(forDuration:3)
        Base.app.tables.cells["menu-Copy-Link"].tap()
        Base.app.textFields["url"].tap()
        // Since the textField value appears all selected first time is clicked
        // this workaround is necessary
        Base.app.textFields["address"].tap()
        Base.app.textFields["address"].tap()
        Base.app.textFields["address"].press(forDuration: 2)

        //Ensure that long press on address bar brings up a menu with Select All, Select, Paste, and Paste & Go
        Base.helper.waitForExistence(Base.app.menuItems["Select All"], timeout: 3)
        XCTAssertTrue(Base.app.menuItems["Select All"].exists)
        XCTAssertTrue(Base.app.menuItems["Select"].exists)
        XCTAssertTrue(Base.app.menuItems["Paste"].exists)
        XCTAssertTrue(Base.app.menuItems["Paste & Go"].exists)

        //Tap on Select option and make sure Copy, Cut, Paste, and Look Up are shown
        Base.app.menuItems["Select"].tap()
        Base.helper.waitForExistence(Base.app.menuItems["Copy"])
        if Base.helper.iPad() {
            XCTAssertTrue(Base.app.menuItems["Copy"].exists)
            XCTAssertTrue(Base.app.menuItems["Cut"].exists)
            XCTAssertTrue(Base.app.menuItems["Look Up"].exists)
            XCTAssertTrue(Base.app.menuItems["Share…"].exists)
            XCTAssertTrue(Base.app.menuItems["Paste & Go"].exists)
            XCTAssertTrue(Base.app.menuItems["Paste"].exists)
        } else {
            XCTAssertTrue(Base.app.menuItems["Copy"].exists)
            XCTAssertTrue(Base.app.menuItems["Cut"].exists)
            XCTAssertTrue(Base.app.menuItems["Look Up"].exists)
            XCTAssertTrue(Base.app.menuItems["Paste"].exists)
            XCTAssertTrue(Base.app.menus.children(matching: .menuItem).element(boundBy: 4).exists)
        }

        //Go back from Select and redo the tap
        Base.app.textFields["address"].tap()
        Base.app.textFields["address"].press(forDuration: 2)

        //Tap on Select All option and make sure Copy, Cut, Paste, and Look Up are shown
        Base.app.menuItems["Select All"].tap()
        Base.helper.waitForExistence(Base.app.menuItems["Copy"])
        if Base.helper.iPad() {
            XCTAssertTrue(Base.app.menuItems["Copy"].exists)
            XCTAssertTrue(Base.app.menuItems["Cut"].exists)
            XCTAssertTrue(Base.app.menuItems["Look Up"].exists)
            XCTAssertTrue(Base.app.menuItems["Share…"].exists)
            XCTAssertTrue(Base.app.menuItems["Paste"].exists)
            XCTAssertTrue(Base.app.menuItems["Paste & Go"].exists)
        } else {
            XCTAssertTrue(Base.app.menuItems["Copy"].exists)
            XCTAssertTrue(Base.app.menuItems["Cut"].exists)
            XCTAssertTrue(Base.app.menuItems["Look Up"].exists)
            XCTAssertTrue(Base.app.menuItems["Paste"].exists)
            XCTAssertTrue(Base.app.menus.children(matching: .menuItem).element(boundBy: 4).exists)
        }
    }*/

    private func longPressLinkOptions(optionSelected: String) {
        navigator.openURL(Base.helper.path(forTestPage: "test-example.html"))
        Base.helper.waitUntilPageLoad()
        Base.app.webViews.links[Constants.website_2["link"]!].press(forDuration: 2)
        Base.app.buttons[optionSelected].tap()
    }

    func testDownloadLink() {
        longPressLinkOptions(optionSelected: "Download Link")
        Base.helper.waitForExistence(Base.app.tables["Context Menu"])
        XCTAssertTrue(Base.app.tables["Context Menu"].cells["download"].exists)
        Base.app.tables["Context Menu"].cells["download"].tap()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_Downloads)
        Base.helper.waitForExistence(Base.app.tables["DownloadsTable"])
        // There should be one item downloaded. It's name and size should be shown
        let downloadedList = Base.app.tables["DownloadsTable"].cells.count
        XCTAssertEqual(downloadedList, 1, "The number of items in the downloads table is not correct")
        XCTAssertTrue(Base.app.tables.cells.staticTexts["reserved.html"].exists)

        // Tap on the just downloaded link to check that the web page is loaded
        Base.app.tables.cells.staticTexts["reserved.html"].tap()
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForValueContains(Base.app.textFields["url"], value: "reserved.html")
    }

    func testShareLink() {
        longPressLinkOptions(optionSelected: "Share Link")
        Base.helper.waitForExistence(Base.app.collectionViews.cells["Copy"])
        XCTAssertTrue(Base.app.collectionViews.cells["Copy"].exists, "The share menu is not shown")
    }

    func testShareLinkPrivateMode() {
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        longPressLinkOptions(optionSelected: "Share Link")
        Base.helper.waitForExistence(Base.app.collectionViews.cells["Copy"])
        XCTAssertTrue(Base.app.collectionViews.cells["Copy"].exists, "The share menu is not shown")
    }

    // Disable, no Cancel button now and no option to
    // tap on PopoverDismissRegion
    /*
    func testCancelLongPressLinkMenu() {
        navigator.openURL(website_2["url"]!)
        Base.app.webViews.links[website_2["link"]!].press(forDuration: 2)
        
        if Base.helper.iPad() {
            // For iPad there is no Cancel, so we tap to dismiss the menu
            app/*@START_MENU_TOKEN@*/.otherElements["PopoverDismissRegion"]/*[[".otherElements[\"dismiss popup\"]",".otherElements[\"PopoverDismissRegion\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        } else {
            Base.app.buttons["Cancel"].tap()
        }
        waitForNoExistence(Base.app.sheets[website_2["moreLinkLongPressInfo"]!])
        XCTAssertEqual(Base.app.textFields["url"].value! as? String, "www.example.com/", "After canceling the menu user is in a different website")
    }*/

    // Smoketest
    func testPopUpBlocker() {
        // Check that it is enabled by default
        navigator.goto(SettingsScreen)
        Base.helper.waitForExistence(Base.app.tables["AppSettingsTableViewController.tableView"])
        let switchBlockPopUps = Base.app.tables.cells.switches["blockPopups"]
        let switchValue = switchBlockPopUps.value!
        XCTAssertEqual(switchValue as? String, "1")

        // Check that there are no pop ups
        navigator.openURL(Constants.popUpTestUrl)
        Base.helper.waitForValueContains(Base.app.textFields["url"], value: "blocker.html")
        Base.helper.waitForExistence(Base.app.webViews.staticTexts["Blocked Element"])

        let numTabs = Base.app.buttons["Show Tabs"].value
        XCTAssertEqual("1", numTabs as? String, "There should be only on tab")

        // Now disable the Block PopUps option
        navigator.goto(BrowserTabMenu)
        navigator.goto(SettingsScreen)
        switchBlockPopUps.tap()
        let switchValueAfter = switchBlockPopUps.value!
        XCTAssertEqual(switchValueAfter as? String, "0")

        // Check that now pop ups are shown, two sites loaded
        navigator.openURL(Constants.popUpTestUrl)
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForValueContains(Base.app.textFields["url"], value: "example.com")
        let numTabsAfter = Base.app.buttons["Show Tabs"].value
        XCTAssertNotEqual("1", numTabsAfter as? String, "Several tabs are open")
    }

    // Smoketest
    func testSSL() {
        navigator.openURL("https://expired.badssl.com/")
        Base.helper.waitForExistence(Base.app.buttons["Advanced"], timeout: 10)
        Base.app.buttons["Advanced"].tap()

        Base.helper.waitForExistence(Base.app.links["Visit site anyway"])
        Base.app.links["Visit site anyway"].tap()
        Base.helper.waitForExistence(Base.app.webViews.otherElements["expired.badssl.com"], timeout: 10)
        XCTAssertTrue(Base.app.webViews.otherElements["expired.badssl.com"].exists)
    }

    // In this test, the parent window opens a child and in the child it creates a fake link 'link-created-by-parent'
    func testWriteToChildPopupTab() {
        navigator.goto(SettingsScreen)
        Base.helper.waitForExistence(Base.app.tables["AppSettingsTableViewController.tableView"])
        let switchBlockPopUps = Base.app.tables.cells.switches["blockPopups"]
        switchBlockPopUps.tap()
        let switchValueAfter = switchBlockPopUps.value!
        XCTAssertEqual(switchValueAfter as? String, "0")
        navigator.goto(BrowserTab)
        navigator.openURL(Base.helper.path(forTestPage: "test-window-opener.html"))
        Base.helper.waitForExistence(Base.app.links["link-created-by-parent"], timeout: 10)
    }
 }
