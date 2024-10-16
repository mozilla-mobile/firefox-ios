// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

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
            LaunchArguments.LoadTabsStateArchive + tabsDatabase
        ]

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
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerView])
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Walmart | Save Money. Live better."])

        // Tap on the ">" button.
        app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerView].tap()
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerButton])
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Homepage"])
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Google"])
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Facebook - log in or sign up"])
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Amazon.com. Spend less. Smile more."])
        app.buttons[AccessibilityIdentifiers.TabTray.doneButton].tap()

        // Go to Settings -> Tabs and disable "Inactive tabs"
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)
        mozWaitForElementToExist(app.cells[AccessibilityIdentifiers.Settings.Tabs.title])
        app.cells[AccessibilityIdentifiers.Settings.Tabs.title].tap()
        mozWaitForElementToExist(app.tables.otherElements[AccessibilityIdentifiers.Settings.Tabs.Customize.title])
        XCTAssertEqual(
            app.switches[AccessibilityIdentifiers.Settings.Tabs.Customize.inactiveTabsSwitch].value as! String, "1")
        app.switches[AccessibilityIdentifiers.Settings.Tabs.Customize.inactiveTabsSwitch].tap()
        XCTAssertEqual(
            app.switches[AccessibilityIdentifiers.Settings.Tabs.Customize.inactiveTabsSwitch].value as! String, "0")
        app.navigationBars.buttons["Settings"].tap() // Note: No AccessibilityIdentifiers
        navigator.nowAt(SettingsScreen)

        // Return to tabs tray
        navigator.goto(TabTray)
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Homepage"])
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Google"])
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Facebook - log in or sign up"])
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Amazon.com. Spend less. Smile more."])
        mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerButton])
        app.buttons[AccessibilityIdentifiers.TabTray.doneButton].tap()
        navigator.nowAt(NewTabScreen)

        // Go to Settings -> Tabs and enable "Inactive tabs"
        navigator.goto(SettingsScreen)
        mozWaitForElementToExist(app.cells[AccessibilityIdentifiers.Settings.Tabs.title])
        app.cells[AccessibilityIdentifiers.Settings.Tabs.title].tap()
        mozWaitForElementToExist(app.tables.otherElements[AccessibilityIdentifiers.Settings.Tabs.Customize.title])
        app.switches[AccessibilityIdentifiers.Settings.Tabs.Customize.inactiveTabsSwitch].tap()
        XCTAssertEqual(
            app.switches[AccessibilityIdentifiers.Settings.Tabs.Customize.inactiveTabsSwitch].value as! String, "1")
        app.navigationBars.buttons["Settings"].tap()
        navigator.nowAt(SettingsScreen)

        // Return to tabs tray
        navigator.goto(TabTray)
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerView])

        // Tap on a tab from the inactive list
        app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerView].tap()
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerButton])
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Homepage"])
        app.otherElements["Tabs Tray"].staticTexts["Homepage"].tap()
        mozWaitForElementToNotExist(app.otherElements["Tabs Tray"])

        navigator.nowAt(NewTabScreen)
        navigator.goto(TabTray)
        mozWaitForElementToExist(app.staticTexts["Homepage"])

        // Expand inactive list
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerView])
        app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerView].tap()
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerButton])
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Google"])
        mozWaitForElementToNotExist(app.otherElements["Tabs Tray"].staticTexts["Homepage"])

        // Swipe on a tab from the list to delete
        app.otherElements["Tabs Tray"].staticTexts["Google"].swipeLeft()
        mozWaitForElementToExist(app.buttons["Close"])
        app.buttons["Close"].tap() // Note: No AccessibilityIdentifier
        mozWaitForElementToNotExist(app.otherElements["Tabs Tray"].staticTexts["Google"])
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Facebook - log in or sign up"])
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Amazon.com. Spend less. Smile more."])

        // Tap "Close All Inactive Tabs"
        app.swipeUp()
        mozWaitForElementToExist(app.buttons["InactiveTabs.deleteButton"])
        app.buttons["InactiveTabs.deleteButton"].tap()
        mozWaitForElementToExist(app.staticTexts["Tabs Closed: 17"])

        // All inactive tabs are deleted
        navigator.nowAt(TabTray)
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Homepage"])
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Walmart | Save Money. Live better."])
        mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerView])
        mozWaitForElementToNotExist(app.otherElements["Tabs Tray"].staticTexts["Google"])
        mozWaitForElementToNotExist(app.otherElements["Tabs Tray"].staticTexts["Facebook - log in or sign up"])
        mozWaitForElementToNotExist(app.otherElements["Tabs Tray"].staticTexts["Amazon.com. Spend less. Smile more."])
    }
}
