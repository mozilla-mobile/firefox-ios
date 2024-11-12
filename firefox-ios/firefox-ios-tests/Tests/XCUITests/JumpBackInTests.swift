// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

class JumpBackInTests: BaseTestCase {
    func closeKeyboard() {
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton])
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
    }

    func scrollDown() {
        if !isTablet {
            while app.staticTexts["Switch Your Default Browser"].exists || app.buttons["Learn How"].exists {
                app.collectionViews["FxCollectionView"].swipeUp()
            }
        }
    }

    override func setUp() {
        super.setUp()

        // "Jump Back In" is enabled by default. See Settings -> Homepage
        navigator.goto(HomeSettings)
        mozWaitForElementToExist(app.switches["Jump Back In"])
        XCTAssertEqual(app.switches["Jump Back In"].value as? String, "1")

        navigator.goto(NewTabScreen)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306922
    func testJumpBackInSection() {
        // Open a tab and visit a page
        navigator.openURL("https://www.example.com")
        waitUntilPageLoad()

        // Open a new tab
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        closeKeyboard()

        // "Jump Back In" section is displayed
        mozWaitForElementToExist(app.cells["JumpBackInCell"].firstMatch)
        // The contextual hint box is not displayed consistently, so
        // I don't test for its existence.
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306920
    // Smoketest
    func testPrivateTab() throws {
        throw XCTSkip("This test is flaky")
//        // Visit https://www.twitter.com
//        navigator.openURL("https://www.twitter.com")
//        waitUntilPageLoad()
//
//        // Open a new tab and check the "Jump Back In" section
//        navigator.goto(TabTray)
//        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.TabTray.newTabButton], timeout: TIMEOUT)
//        navigator.performAction(Action.OpenNewTabFromTabTray)
//        closeKeyboard()
//
//        // Twitter tab is visible in the "Jump Back In" section
//        scrollDown()
//        mozWaitForElementToExist(app.cells["JumpBackInCell"].firstMatch)
//        mozWaitForElementToExist(app.cells["JumpBackInCell"].staticTexts["Twitter"])
//
//        // Open private browsing
//        navigator.goto(TabTray)
//        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
//
//        // Visit YouTube in private browsing
//        navigator.performAction(Action.OpenNewTabFromTabTray)
//        navigator.openURL("https://www.youtube.com")
//        waitUntilPageLoad()
//
//        // Open a new tab in normal browsing and check the "Jump Back In" section
//        navigator.toggleOff(userState.isPrivate, withAction: Action.ToggleRegularMode)
//        navigator.goto(NewTabScreen)
//        closeKeyboard()
//
//        // Twitter should be in "Jump Back In"
//        scrollDown()
//        mozWaitForElementToExist(app.cells["JumpBackInCell"].firstMatch)
//        mozWaitForElementToExist(app.cells["JumpBackInCell"].staticTexts["Twitter"])
//        mozWaitForElementToNotExist(app.cells["JumpBackInCell"].staticTexts["YouTube"])
//
//        // Visit "amazon.com" and check the "Jump Back In" section
//        navigator.openURL("https://www.amazon.com")
//        waitUntilPageLoad()
//
//        navigator.goto(TabTray)
//        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.TabTray.newTabButton], timeout: TIMEOUT)
//        navigator.performAction(Action.OpenNewTabFromTabTray)
//        closeKeyboard()
//
//        // Amazon and Twitter are visible in the "Jump Back In" section
//        scrollDown()
//        mozWaitForElementToExist(app.cells["JumpBackInCell"].firstMatch)
//        mozWaitForElementToExist(app.cells["JumpBackInCell"].staticTexts["Amazon"])
//        mozWaitForElementToExist(app.cells["JumpBackInCell"].staticTexts["Twitter"])
//        mozWaitForElementToNotExist(app.cells["JumpBackInCell"].staticTexts["YouTube"])
//
//        // Tap on Twitter from "Jump Back In"
//        app.cells["JumpBackInCell"].staticTexts["Twitter"].tap()
//
//        // The view is switched to the twitter tab
//        let url = app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url].value as! String
//        XCTAssertEqual(url, "twitter.com/i/flow/login")
//
//        // Open a new tab in normal browsing
//        navigator.goto(TabTray)
//        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.TabTray.newTabButton], timeout: TIMEOUT)
//        navigator.performAction(Action.OpenNewTabFromTabTray)
//        closeKeyboard()
//
//        // Check the "Jump Back In Section"
//        scrollDown()
//        mozWaitForElementToExist(app.cells["JumpBackInCell"].firstMatch)
//
//        // Amazon is visible in "Jump Back In"
//        mozWaitForElementToExist(app.cells["JumpBackInCell"].staticTexts["Amazon"])
//
//        // Close the amazon tab
//        navigator.goto(TabTray)
//        if isTablet {
//            mozWaitForElementToExist(app.navigationBars.segmentedControls["navBarTabTray"])
//        } else {
//            mozWaitForElementToExist(app.navigationBars.staticTexts["Open Tabs"])
//        }
//        app.cells["Amazon.com. Spend less. Smile more."].buttons[StandardImageIdentifiers.Large.cross].tap()
//
//        // Revisit the "Jump Back In" section
//        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.TabTray.newTabButton], timeout: TIMEOUT)
//        navigator.performAction(Action.OpenNewTabFromTabTray)
//        closeKeyboard()
//
//        // The "Jump Back In" section is still here with twitter listed
//        scrollDown()
//        mozWaitForElementToExist(app.cells["JumpBackInCell"].firstMatch)
//        // FXIOS-5448 - Amazon should not be listed because we've closed the Amazon tab
//        // mozWaitForElementToNotExist(app.cells["JumpBackInCell"].staticTexts["Amazon"])
//        mozWaitForElementToExist(app.cells["JumpBackInCell"].staticTexts["Twitter"])
//        mozWaitForElementToNotExist(app.cells["JumpBackInCell"].staticTexts["YouTube"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2445811
    func testLongTapOnJumpBackInLink() {
        // On homepage, go to the "Jump back in" section and long tap on one of the links
        navigator.openURL(path(forTestPage: "test-example.html"))
        mozWaitForElementToExist(app.webViews.links[website_2["link"]!], timeout: TIMEOUT_LONG)
        app.webViews.links[website_2["link"]!].press(forDuration: 2)
        mozWaitForElementToExist(app.otherElements.collectionViews.element(boundBy: 0))
        app.buttons["Open in New Tab"].waitAndTap()
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.GoToHomePage)
        mozWaitForElementToExist(app.cells["JumpBackInCell"].firstMatch)
        app.cells["JumpBackInCell"].firstMatch.press(forDuration: 2)
        // The context menu opens, having the correct options
        let ContextMenuTable = app.tables["Context Menu"]
        waitForElementsToExist(
            [
                ContextMenuTable,
                ContextMenuTable.cells.otherElements[StandardImageIdentifiers.Large.plus],
                ContextMenuTable.cells.otherElements[StandardImageIdentifiers.Large.privateMode],
                ContextMenuTable.cells.otherElements[StandardImageIdentifiers.Large.bookmark],
                ContextMenuTable.cells.otherElements[StandardImageIdentifiers.Large.share]
            ]
        )
    }
}
