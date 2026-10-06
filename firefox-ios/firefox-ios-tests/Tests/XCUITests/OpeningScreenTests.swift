// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import XCTest

class OpeningScreenTests: BaseTestCase {
    private var browserScreen: BrowserScreen!
    private var homePageScreen: HomePageScreen!
    private var settingsHomepageScreen: SettingsHomepageScreen!
    private var tabTrayScreen: TabTrayScreen!
    private var toolbarScreen: ToolbarScreen!

    private let startAtHomeTests = ["testHomepageOnOpeningScreen"]

    override func setUp() async throws {
        if startAtHomeTests.contains(where: name.contains) {
            // Start at Home is skipped under UI tests, and skipped again until tab restore has
            // finished, which only ever happens when session restore is opted into as well
            launchArguments += [LaunchArguments.EnableStartAtHome, LaunchArguments.EnableSessionRestore]
        }
        try await super.setUp()
        browserScreen = BrowserScreen(app: app)
        homePageScreen = HomePageScreen(app: app)
        settingsHomepageScreen = SettingsHomepageScreen(app: app)
        tabTrayScreen = TabTrayScreen(app: app)
        toolbarScreen = ToolbarScreen(app: app)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307039
    func testLastOpenedTab() {
        // Open a web page
        browserScreen.navigateToURL(path(forTestPage: TestPages.mozillaOrg))
        waitUntilPageLoad()
        // Close the app from app switcher. Relaunch the app
        closeFromAppSwitcherAndRelaunch()
        // After re-launching the app, the last visited page is displayed
        browserScreen.assertAddressBarContains(value: "localhost")
        // Background and restore Firefox
        restartInBackground()
        // After re-launching the app, the last visited page is displayed
        browserScreen.assertAddressBarContains(value: "localhost")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307037
    // Regression
    func testHomepageOnOpeningScreen() {
        // Select Homepage as the opening screen
        navigator.nowAt(NewTabScreen)
        navigator.goto(HomeSettings)
        settingsHomepageScreen.selectHomepageAsOpeningScreen()
        navigator.goto(SettingsScreen)
        navigator.goto(NewTabScreen)

        // Open a web page
        browserScreen.navigateToURL(path(forTestPage: TestPages.mozillaOrg))
        waitUntilPageLoad()
        browserScreen.assertAddressBarContains(value: "localhost")

        // Background and foreground Firefox: the homepage is displayed in a new tab, next to the
        // tab holding the web page
        restartInBackground(inactiveFor: startAtHomeInactivityWait)
        homePageScreen.assertHomepageIsDisplayed()
        toolbarScreen.assertTabsButtonValue(expectedCount: "2", message: "The tab with the web page was not kept")

        // Open a web page again
        browserScreen.navigateToURL(path(forTestPage: TestPages.mozillaOrg))
        waitUntilPageLoad()
        browserScreen.assertAddressBarContains(value: "localhost")

        // Close Firefox from the app switcher and relaunch it: the homepage is displayed again, and
        // the tabs left behind confirm it is not merely the clean state of a fresh launch
        closeFromAppSwitcherAndRelaunch(inactiveFor: startAtHomeInactivityWait)
        homePageScreen.assertHomepageIsDisplayed()
        toolbarScreen.tapOnTabsButton()
        tabTrayScreen.assertTabCount(3)
    }
}
