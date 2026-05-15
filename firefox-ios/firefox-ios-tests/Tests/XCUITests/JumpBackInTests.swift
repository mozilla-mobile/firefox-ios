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

    override func setUp() async throws {
        try await super.setUp()
        jumpBackInScreen = JumpBackInScreen(app: app)
        browserScreen = BrowserScreen(app: app)
        toolbarScreen = ToolbarScreen(app: app)
        tabTrayScreen = TabTrayScreen(app: app)
    }

    func prepareTest() {
        // "Jump Back In" is enabled by default. See Settings -> Homepage
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

    // https://mozilla.testrail.io/index.php?/cases/view/2306922
    func testJumpBackInSection() {
        prepareTest()
        // Open a tab and visit a page
        browserScreen.navigateToURL("https://www.example.com")
        waitUntilPageLoad()

        // Open a new tab
        openNewTabFromTabTray()

        // "Jump Back In" section is displayed
        jumpBackInScreen.assertSectionExists()
        // The contextual hint box is not displayed consistently, so
        // I don't test for its existence.
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306920
    func testPrivateTab() throws {
        prepareTest()
        // Visit https://www.wikipedia.org
        browserScreen.navigateToURL("https://www.wikipedia.org")
        waitUntilPageLoad()

        // Open a new tab and check the "Jump Back In" section
        openNewTabFromTabTray()
        // The experiment is not opening the keyboard on a new tab
        waitForTabsButton()

        // Twitter tab is visible in the "Jump Back In" section
        jumpBackInScreen.scrollToJumpBackInSection()
        jumpBackInScreen.assertSectionExists()
        jumpBackInScreen.assertItemExists(title: "Wikipedia")

        // Open private browsing
        waitForTabsButton()
        toolbarScreen.tapOnTabsButton()
        tabTrayScreen.switchToPrivateBrowsing()

        // Visit YouTube in private browsing
        tabTrayScreen.assertNewTabButtonExist()
        tabTrayScreen.tapOnNewTabButton()
        browserScreen.navigateToURL("https://www.youtube.com")
        waitUntilPageLoad()

        // Open a new tab in normal browsing and check the "Jump Back In" section
        waitForTabsButton()
        toolbarScreen.tapOnTabsButton()
        tabTrayScreen.switchToRegularBrowsing()
        tabTrayScreen.assertNewTabButtonExist()
        tabTrayScreen.tapOnNewTabButton()
        // The experiment is not opening the keyboard on a new tab
        waitForTabsButton()

        // Twitter should be in "Jump Back In"
        jumpBackInScreen.scrollToJumpBackInSection()
        jumpBackInScreen.assertSectionExists()
        jumpBackInScreen.assertItemExists(title: "Wikipedia")
        jumpBackInScreen.assertItemNotExists(title: "YouTube")

        // Visit "mozilla.org" and check the "Jump Back In" section
        browserScreen.navigateToURL("http://localhost:\(serverPort)/test-fixture/test-example.html")
        waitUntilPageLoad()

        openNewTabFromTabTray()
        // The experiment is not opening the keyboard on a new tab
        waitForTabsButton()
        browserScreen.tapCancelButtonIfExist()

        // Amazon and Twitter are visible in the "Jump Back In" section
        jumpBackInScreen.scrollToJumpBackInSection()
        jumpBackInScreen.assertSectionExists()
        jumpBackInScreen.assertItemExists(title: "Example Domain")
        jumpBackInScreen.assertItemExists(title: "Wikipedia")
        jumpBackInScreen.assertItemNotExists(title: "YouTube")

        // Tap on Twitter from "Jump Back In"
        jumpBackInScreen.tapItem(title: "Wikipedia")

        // The view is switched to the twitter tab
        browserScreen.assertAddressBarContains(value: "wikipedia.org")

        // Open a new tab in normal browsing
        openNewTabFromTabTray()
        // The experiment is not opening the keyboard on a new tab
        waitForTabsButton()

        // Check the "Jump Back In Section"
        jumpBackInScreen.scrollToJumpBackInSection()
        jumpBackInScreen.assertSectionExists()

        // Amazon is visible in "Jump Back In"
        jumpBackInScreen.assertItemExists(title: "Example Domain")

        // Close the amazon tab
        waitForTabsButton()
        toolbarScreen.tapOnTabsButton()
        tabTrayScreen.closeTab(title: "Example Domain")

        // Revisit the "Jump Back In" section
        tabTrayScreen.assertNewTabButtonExist()
        tabTrayScreen.tapOnNewTabButton()
        // The experiment is not opening the keyboard on a new tab
        waitForTabsButton()

        // The "Jump Back In" section is still here with twitter listed
        jumpBackInScreen.scrollToJumpBackInSection()
        jumpBackInScreen.assertSectionExists()
        // FXIOS-5448 - Amazon should not be listed because we've closed the Amazon tab
        // mozWaitForElementToNotExist(app.cells["JumpBackInCell"].staticTexts["Example Domain"])
        jumpBackInScreen.assertItemExists(title: "Wikipedia")
        jumpBackInScreen.assertItemNotExists(title: "YouTube")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2445811
    func testLongTapOnJumpBackInLink() {
        prepareTest()
        // On homepage, go to the "Jump back in" section and long tap on one of the links
        browserScreen.navigateToURL(path(forTestPage: "test-example.html"))
        browserScreen.longPressLink(named: website_2["link"]!, duration: 2)
        mozWaitForElementToExist(app.otherElements.collectionViews.element(boundBy: 0))
        app.buttons["Open in New Tab"].waitAndTap()
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
