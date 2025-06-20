// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

final class InactiveTabsTest: FeatureFlaggedTestBase {
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
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "tab-tray-ui-experiments")
        super.setUp()
        app.launch()

        // Workaround: Restart app to guarantee the tabs are loaded
        waitForTabsButton()
        waitUntilPageLoad()
        app.terminate()
        app.launch()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307045
    func testInactiveTabs_tabTrayExperimentOff() {
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
                app.otherElements[tabsTray].staticTexts.firstMatch
            ]
        )

        // Tap on the ">" button.
        app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerView].waitAndTap()
        waitForElementsToExist(
            [
                app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerButton],
                app.otherElements[tabsTray].staticTexts["Homepage"],
                app.otherElements[tabsTray].staticTexts["Google"],
                app.otherElements[tabsTray].staticTexts["Facebook - log in or sign up"],
                app.otherElements[tabsTray].staticTexts["Amazon.com. Spend less. Smile more."]
            ]
        )
        app.buttons[AccessibilityIdentifiers.TabTray.doneButton].waitAndTap()

        // Go to Settings -> Browsing and disable "Inactive tabs"
        navigator.nowAt(NewTabScreen)
        navigator.goto(BrowsingSettings)
        mozWaitForElementToExist(app.tables.otherElements[AccessibilityIdentifiers.Settings.Browsing.tabs])
        XCTAssertEqual(
            app.switches[AccessibilityIdentifiers.Settings.Browsing.inactiveTabsSwitch].value as? String, "1")
        app.switches[AccessibilityIdentifiers.Settings.Browsing.inactiveTabsSwitch].waitAndTap()
        XCTAssertEqual(
            app.switches[AccessibilityIdentifiers.Settings.Browsing.inactiveTabsSwitch].value as? String, "0")
        app.navigationBars.buttons["Settings"].waitAndTap() // Note: No AccessibilityIdentifiers
        navigator.nowAt(SettingsScreen)

        // Return to tabs tray
        navigator.goto(TabTray)
        app.otherElements[tabsTray].swipeDown()
        app.otherElements[tabsTray].swipeDown()
        app.otherElements[tabsTray].swipeDown()
        waitForElementsToExist(
            [
                app.otherElements[tabsTray].staticTexts["Homepage"],
                app.otherElements[tabsTray].staticTexts["Google"],
                app.otherElements[tabsTray].staticTexts["Facebook - log in or sign up"],
                app.otherElements[tabsTray].staticTexts["Amazon.com. Spend less. Smile more."],
            ]
        )
        mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerButton])
        app.buttons[AccessibilityIdentifiers.TabTray.doneButton].waitAndTap()
        navigator.nowAt(NewTabScreen)

        // Go to Settings -> Browsing and disable "Inactive tabs"
        navigator.goto(BrowsingSettings)
        app.switches[AccessibilityIdentifiers.Settings.Browsing.inactiveTabsSwitch].waitAndTap()
        XCTAssertEqual(
            app.switches[AccessibilityIdentifiers.Settings.Browsing.inactiveTabsSwitch].value as? String, "1")
        app.navigationBars.buttons["Settings"].waitAndTap()
        navigator.nowAt(SettingsScreen)

        // Return to tabs tray
        navigator.goto(TabTray)

        // Tap on a tab from the inactive list
        app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerView].waitAndTap()
        waitForElementsToExist(
            [
                app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerButton],
                app.otherElements[tabsTray].staticTexts["Homepage"]
            ]
        )
        app.otherElements[tabsTray].staticTexts["Homepage"].waitAndTap()
        mozWaitForElementToNotExist(app.otherElements[tabsTray])

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
                app.otherElements[tabsTray].staticTexts["Google"]
            ]
        )
        if !iPad() {
            // The active tabs on iPhone is so far down that "Homepage" is invisible.
            // iPad is large enough that "Homepage" is still visible"
            mozWaitForElementToNotExist(app.otherElements[tabsTray].staticTexts["Homepage"])
        }

        // Swipe on a tab from the list to delete
        app.otherElements[tabsTray].staticTexts["Google"].swipeLeft()
        app.otherElements[tabsTray].buttons["Close"].waitAndTap() // Note: No AccessibilityIdentifier
        mozWaitForElementToNotExist(app.otherElements[tabsTray].staticTexts["Google"])
        waitForElementsToExist(
            [
                app.otherElements[tabsTray].staticTexts["Facebook - log in or sign up"],
                app.otherElements[tabsTray].staticTexts["Amazon.com. Spend less. Smile more."]
            ]
        )

        // Tap "Close All Inactive Tabs"
        app.swipeUp()
        mozWaitForElementToExist(app.buttons["InactiveTabs.deleteButton"])
        app.buttons["InactiveTabs.deleteButton"].waitAndTap()
        mozWaitForElementToExist(app.staticTexts["Tabs Closed: 17"])

        // All inactive tabs are deleted
        navigator.nowAt(TabTray)
        mozWaitForElementToExist(app.otherElements[tabsTray].staticTexts["Homepage"])
        XCTAssertEqual(app.otherElements[tabsTray].collectionViews.cells.count, 2)
        mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerView])
        mozWaitForElementToNotExist(app.otherElements[tabsTray].staticTexts["Google"])
        mozWaitForElementToNotExist(app.otherElements[tabsTray].staticTexts["Facebook - log in or sign up"])
        mozWaitForElementToNotExist(app.otherElements[tabsTray].staticTexts["Amazon.com. Spend less. Smile more."])
    }
}
