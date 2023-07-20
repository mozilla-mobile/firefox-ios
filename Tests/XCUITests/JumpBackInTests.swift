// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class JumpBackInTests: BaseTestCase {
    func closeKeyboard() {
        waitForExistence(app.buttons["urlBar-cancel"])
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
        XCTAssertEqual(app.switches["Jump Back In"].value as! String, "1")

        navigator.goto(NewTabScreen)
    }

    func testJumpBackInSection() {
        // Open a tab and visit a page
        navigator.openURL("https://www.example.com")
        waitUntilPageLoad()

        // Open a new tab
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        closeKeyboard()

        // "Jump Back In" section is displayed
        waitForExistence(app.cells["JumpBackInCell"].firstMatch, timeout: TIMEOUT)
        // The contextual hint box is not displayed consistently, so
        // I don't test for its existence.
    }

    func testGroupedTabs() {
        // Enable "Tab Groups" from Settings -> Tabs
        navigator.goto(TabsSettings)
        navigator.performAction(Action.ToggleTabGroups)
        navigator.goto(SettingsScreen)
        app.navigationBars.buttons["Done"].tap()
        navigator.nowAt(NewTabScreen)

        // Create 1 group in tab tray
        let groups = ["test3"]
        for group in groups {
            for _ in 1...3 {
                navigator.goto(TabTray)
                waitForExistence(app.buttons[AccessibilityIdentifiers.TabTray.newTabButton], timeout: TIMEOUT)
                navigator.performAction(Action.OpenNewTabFromTabTray)
                navigator.openURL(group)
                waitUntilPageLoad()
            }
        }
        waitForTabsButton()
        // Open a new tab
        navigator.goto(TabTray)
        waitForExistence(app.buttons[AccessibilityIdentifiers.TabTray.newTabButton], timeout: TIMEOUT)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        closeKeyboard()
        waitForTabsButton()

        // Tap on the "test3" from "Jump Back In" section
        scrollDown()
        waitForExistence(app.cells["JumpBackInCell"].firstMatch, timeout: TIMEOUT)
        app.cells["JumpBackInCell"].staticTexts["Test3"].tap()
        if isTablet {
            waitForExistence(app.navigationBars.segmentedControls["navBarTabTray"])
        } else {
            waitForExistence(app.navigationBars.staticTexts["Open Tabs"])
        }
        waitForExistence(app.staticTexts["Test3"])
    }

    func testPrivateTab() throws {
        throw XCTSkip("This test is flaky")
//        // Visit https://www.twitter.com
//        navigator.openURL("https://www.twitter.com")
//        waitUntilPageLoad()
//
//        // Open a new tab and check the "Jump Back In" section
//        navigator.goto(TabTray)
//        waitForExistence(app.buttons[AccessibilityIdentifiers.TabTray.newTabButton], timeout: TIMEOUT)
//        navigator.performAction(Action.OpenNewTabFromTabTray)
//        closeKeyboard()
//
//        // Twitter tab is visible in the "Jump Back In" section
//        scrollDown()
//        waitForExistence(app.cells["JumpBackInCell"].firstMatch)
//        waitForExistence(app.cells["JumpBackInCell"].staticTexts["Twitter"])
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
//        waitForExistence(app.cells["JumpBackInCell"].firstMatch)
//        waitForExistence(app.cells["JumpBackInCell"].staticTexts["Twitter"])
//        waitForNoExistence(app.cells["JumpBackInCell"].staticTexts["YouTube"])
//
//        // Visit "amazon.com" and check the "Jump Back In" section
//        navigator.openURL("https://www.amazon.com")
//        waitUntilPageLoad()
//
//        navigator.goto(TabTray)
//        waitForExistence(app.buttons[AccessibilityIdentifiers.TabTray.newTabButton], timeout: TIMEOUT)
//        navigator.performAction(Action.OpenNewTabFromTabTray)
//        closeKeyboard()
//
//        // Amazon and Twitter are visible in the "Jump Back In" section
//        scrollDown()
//        waitForExistence(app.cells["JumpBackInCell"].firstMatch)
//        waitForExistence(app.cells["JumpBackInCell"].staticTexts["Amazon"])
//        waitForExistence(app.cells["JumpBackInCell"].staticTexts["Twitter"])
//        waitForNoExistence(app.cells["JumpBackInCell"].staticTexts["YouTube"])
//
//        // Tap on Twitter from "Jump Back In"
//        app.cells["JumpBackInCell"].staticTexts["Twitter"].tap()
//
//        // The view is switched to the twitter tab
//        let url = app.textFields["url"].value as! String
//        XCTAssertEqual(url, "twitter.com/i/flow/login")
//
//        // Open a new tab in normal browsing
//        navigator.goto(TabTray)
//        waitForExistence(app.buttons[AccessibilityIdentifiers.TabTray.newTabButton], timeout: TIMEOUT)
//        navigator.performAction(Action.OpenNewTabFromTabTray)
//        closeKeyboard()
//
//        // Check the "Jump Back In Section"
//        scrollDown()
//        waitForExistence(app.cells["JumpBackInCell"].firstMatch)
//
//        // Amazon is visible in "Jump Back In"
//        waitForExistence(app.cells["JumpBackInCell"].staticTexts["Amazon"])
//
//        // Close the amazon tab
//        navigator.goto(TabTray)
//        if isTablet {
//            waitForExistence(app.navigationBars.segmentedControls["navBarTabTray"])
//        } else {
//            waitForExistence(app.navigationBars.staticTexts["Open Tabs"])
//        }
//        app.cells["Amazon.com. Spend less. Smile more."].buttons[StandardImageIdentifiers.Large.cross].tap()
//
//        // Revisit the "Jump Back In" section
//        waitForExistence(app.buttons[AccessibilityIdentifiers.TabTray.newTabButton], timeout: TIMEOUT)
//        navigator.performAction(Action.OpenNewTabFromTabTray)
//        closeKeyboard()
//
//        // The "Jump Back In" section is still here with twitter listed
//        scrollDown()
//        waitForExistence(app.cells["JumpBackInCell"].firstMatch)
//        // FXIOS-5448 - Amazon should not be listed because we've closed the Amazon tab
//        // waitForNoExistence(app.cells["JumpBackInCell"].staticTexts["Amazon"])
//        waitForExistence(app.cells["JumpBackInCell"].staticTexts["Twitter"])
//        waitForNoExistence(app.cells["JumpBackInCell"].staticTexts["YouTube"])
    }
}
