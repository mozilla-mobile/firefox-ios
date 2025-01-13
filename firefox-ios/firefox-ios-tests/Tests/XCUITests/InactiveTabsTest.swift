// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

final class InactiveTabsTest: BaseTestCase {
    override func setUp() {
        // Load 20 tabs. 19 tabs are inactive.
        let tabsDatabase = "tabsState20.archive"
        launchArguments = [
            LaunchArguments.PerformanceTest,
            LaunchArguments.SkipIntro,
            LaunchArguments.SkipWhatsNew,
            LaunchArguments.SkipETPCoverSheet,
            LaunchArguments.SkipContextualHints,
            LaunchArguments.DisableAnimations,
        ]
        launchArguments.append(LaunchArguments.LoadTabsStateArchive + tabsDatabase)

        super.setUp()

        // Workaround: Restart app to guarantee the tabs are loaded
        waitForTabsButton()
        waitUntilPageLoad()
        app.terminate()
        app.launch()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307045
    func testInactiveTabs() {
        // Confirm we have tabs loaded
        let tabsButtonNumber = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].staticTexts["20"]
        waitForTabsButton()
        mozWaitForElementToExist(tabsButtonNumber)
        waitUntilPageLoad()

        // Open Tab Tray
        navigator.goto(TabTray)

        // Inactive tabs list is displayed at the top
        waitForElementsToExist(
            [
                app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerView],
                app.otherElements["Tabs Tray"].staticTexts.firstMatch
            ]
        )

        // Tap on the ">" button.
        app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerView].waitAndTap()
        waitForElementsToExist(
            [
                app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerButton],
                app.otherElements["Tabs Tray"].staticTexts["Homepage"],
                app.otherElements["Tabs Tray"].staticTexts["Google"],
                app.otherElements["Tabs Tray"].staticTexts["Facebook - log in or sign up"],
                app.otherElements["Tabs Tray"].staticTexts["Amazon.com. Spend less. Smile more."]
            ]
        )
        app.buttons[AccessibilityIdentifiers.TabTray.doneButton].waitAndTap()

        // Go to Settings -> Tabs and disable "Inactive tabs"
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)
        app.cells[AccessibilityIdentifiers.Settings.Tabs.title].waitAndTap()
        mozWaitForElementToExist(app.tables.otherElements[AccessibilityIdentifiers.Settings.Tabs.Customize.title])
        XCTAssertEqual(
            app.switches[AccessibilityIdentifiers.Settings.Tabs.Customize.inactiveTabsSwitch].value as? String, "1")
        app.switches[AccessibilityIdentifiers.Settings.Tabs.Customize.inactiveTabsSwitch].waitAndTap()
        XCTAssertEqual(
            app.switches[AccessibilityIdentifiers.Settings.Tabs.Customize.inactiveTabsSwitch].value as? String, "0")
        app.navigationBars.buttons["Settings"].waitAndTap() // Note: No AccessibilityIdentifiers
        navigator.nowAt(SettingsScreen)

        // Return to tabs tray
        navigator.goto(TabTray)
        app.otherElements["Tabs Tray"].swipeDown()
        app.otherElements["Tabs Tray"].swipeDown()
        app.otherElements["Tabs Tray"].swipeDown()
        waitForElementsToExist(
            [
                app.otherElements["Tabs Tray"].staticTexts["Homepage"],
                app.otherElements["Tabs Tray"].staticTexts["Google"],
                app.otherElements["Tabs Tray"].staticTexts["Facebook - log in or sign up"],
                app.otherElements["Tabs Tray"].staticTexts["Amazon.com. Spend less. Smile more."],
            ]
        )
        mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerButton])
        app.buttons[AccessibilityIdentifiers.TabTray.doneButton].waitAndTap()
        navigator.nowAt(NewTabScreen)

        // Go to Settings -> Tabs and enable "Inactive tabs"
        navigator.goto(SettingsScreen)
        app.cells[AccessibilityIdentifiers.Settings.Tabs.title].waitAndTap()
        app.switches[AccessibilityIdentifiers.Settings.Tabs.Customize.inactiveTabsSwitch].waitAndTap()
        XCTAssertEqual(
            app.switches[AccessibilityIdentifiers.Settings.Tabs.Customize.inactiveTabsSwitch].value as? String, "1")
        app.navigationBars.buttons["Settings"].waitAndTap()
        navigator.nowAt(SettingsScreen)

        // Return to tabs tray
        navigator.goto(TabTray)

        // Tap on a tab from the inactive list
        app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerView].waitAndTap()
        waitForElementsToExist(
            [
                app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerButton],
                app.otherElements["Tabs Tray"].staticTexts["Homepage"]
            ]
        )
        app.otherElements["Tabs Tray"].staticTexts["Homepage"].waitAndTap()
        mozWaitForElementToNotExist(app.otherElements["Tabs Tray"])

        navigator.nowAt(NewTabScreen)
        navigator.goto(TabTray)
        waitForElementsToExist(
            [
                app.staticTexts["Homepage"],
                app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerView]
            ]
        )

        // Expand inactive list
        app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerView].waitAndTap()
        waitForElementsToExist(
            [
                app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerButton],
                app.otherElements["Tabs Tray"].staticTexts["Google"]
            ]
        )
        if !iPad() {
            // The active tabs on iPhone is so far down that "Homepage" is invisible.
            // iPad is large enough that "Homepage" is still visible"
            mozWaitForElementToNotExist(app.otherElements["Tabs Tray"].staticTexts["Homepage"])
        }

        // Swipe on a tab from the list to delete
        app.otherElements["Tabs Tray"].staticTexts["Google"].swipeLeft()
        app.otherElements["Tabs Tray"].buttons["Close"].waitAndTap() // Note: No AccessibilityIdentifier
        mozWaitForElementToNotExist(app.otherElements["Tabs Tray"].staticTexts["Google"])
        waitForElementsToExist(
            [
                app.otherElements["Tabs Tray"].staticTexts["Facebook - log in or sign up"],
                app.otherElements["Tabs Tray"].staticTexts["Amazon.com. Spend less. Smile more."]
            ]
        )

        // Tap "Close All Inactive Tabs"
        app.swipeUp()
        mozWaitForElementToExist(app.buttons["InactiveTabs.deleteButton"])
        app.buttons["InactiveTabs.deleteButton"].waitAndTap()
        mozWaitForElementToExist(app.staticTexts["Tabs Closed: 17"])

        // All inactive tabs are deleted
        navigator.nowAt(TabTray)
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Homepage"])
        XCTAssertEqual(app.otherElements["Tabs Tray"].collectionViews.cells.count, 2)
        mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerView])
        mozWaitForElementToNotExist(app.otherElements["Tabs Tray"].staticTexts["Google"])
        mozWaitForElementToNotExist(app.otherElements["Tabs Tray"].staticTexts["Facebook - log in or sign up"])
        mozWaitForElementToNotExist(app.otherElements["Tabs Tray"].staticTexts["Amazon.com. Spend less. Smile more."])
    }
}
