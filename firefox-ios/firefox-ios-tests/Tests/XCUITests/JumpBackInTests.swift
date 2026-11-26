// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

class JumpBackInTests: FeatureFlaggedTestBase {
    private var jumpBackInScreen: JumpBackInScreen!
    private var browserScreen: BrowserScreen!
    private var toolbarScreen: ToolbarScreen!
    private var tabTrayScreen: TabTrayScreen!
    private var contextMenuScreen: ContextMenuScreen!
    private var firefoxHomePageScreen: FirefoxHomePageScreen!
    private var homepageSettingsScreen: HomepageSettingsScreen!

    override func setUp() async throws {
        try await super.setUp()
        jumpBackInScreen = JumpBackInScreen(app: app)
        browserScreen = BrowserScreen(app: app)
        toolbarScreen = ToolbarScreen(app: app)
        tabTrayScreen = TabTrayScreen(app: app)
        contextMenuScreen = ContextMenuScreen(app: app)
        firefoxHomePageScreen = FirefoxHomePageScreen(app: app)
        homepageSettingsScreen = HomepageSettingsScreen(app: app)
    }

    func prepareTest() {
        // "Jump Back In" is off by default, so it has to be turned on. See Settings -> Homepage
        addLaunchArgument(jsonFileName: "homepageRedesignOff", featureName: "homepage-redesign-feature")
        app.launch()
        enableJumpBackInInSettings()
    }

    private func openNewTabFromTabTray() {
        waitForTabsButton()
        toolbarScreen.tapOnTabsButton()
        tabTrayScreen.assertNewTabButtonExist()
        tabTrayScreen.tapOnNewTabButton()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3254197
    // Regression
    func testJumpBackInIsOffByDefaultAndAvailableInSettings() {
        app.launch()

        // Access some webpages, so the section would have tabs to show if it were enabled
        browserScreen.navigateToURL(path(forTestPage: TestPages.exampleHTML))
        waitUntilPageLoad()
        browserScreen.navigateToURL(path(forTestPage: TestPages.mozillaOrg))
        waitUntilPageLoad()

        // Back on the homepage the section is not displayed. Top Sites is awaited first so the
        // absence check runs against a settled homepage instead of one that is still loading.
        openNewTabFromTabTray()
        waitForTabsButton()
        firefoxHomePageScreen.assertTopSitesItemCellExist()
        jumpBackInScreen.assertSectionNotExists()

        // The toggle is still offered in Settings, switched off
        navigator.nowAt(NewTabScreen)
        navigator.goto(HomeSettings)
        homepageSettingsScreen.assertJumpBackInToggleExists()
        homepageSettingsScreen.assertJumpBackInToggleIsDisabled()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2445811
    func testLongTapOnJumpBackInLink() {
        prepareTest()
        // On homepage, go to the "Jump back in" section and long tap on one of the links
        browserScreen.navigateToURL(path(forTestPage: TestPages.exampleHTML))
        browserScreen.longPressLink(named: website_2["link"]!, duration: 2)
        mozWaitForElementToExist(app.otherElements.collectionViews.element(boundBy: 0))
        contextMenuScreen.tapOpenInNewTab()
        waitUntilPageLoad()
        openNewTabFromTabTray()
        waitForTabsButton()
        browserScreen.tapCancelButtonIfExist()

        jumpBackInScreen.assertSectionExists()
        jumpBackInScreen.longPressFirstItem()
        // The context menu opens, having the correct options
        jumpBackInScreen.assertContextMenuExists()
    }
}
