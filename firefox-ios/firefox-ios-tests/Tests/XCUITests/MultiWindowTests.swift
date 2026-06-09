// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

class MultiWindowTests: IpadOnlyTestCase {
    let dotMenu = springboard.buttons["top-affordance:org.mozilla.ios.Fennec"]
    let splitView = springboard.buttons["top-affordance-split-view-button"]
    let dotMenuIdentifier = springboard.buttons.matching(identifier: "top-affordance:org.mozilla.ios.Fennec")

    override func setUp() async throws {
        try await super.setUp()
        super.setUpLaunchArguments()
        // Skip all tests in this class on iOS 26
        if ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 26 {
            throw XCTSkip("Skipping MultiWindowTests on iOS 26")
        }
        if dotMenuIdentifier.element(boundBy: 1).exists {
            closeSplitViewWindow(windowToClose: 1)
        }
    }

    override func tearDown() async throws {
        // No-op on iOS 26 (matching setUp skip)
        if ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 26 {
            try await super.tearDown()
            return
        }
        if dotMenuIdentifier.element(boundBy: 1).exists {
            closeSplitViewWindow(windowToClose: 1)
        }
        try await super.tearDown()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2711015
    func testMultiWindowSplitView() {
        if skipPlatform { return }
        dismissSurveyPrompt()
        splitViewFromHomeScreen()
        XCTAssertEqual(dotMenuIdentifier.count, 2, "There are not 2 instances opened")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2711016
    func testMultiWindowNewTab() {
        if skipPlatform { return }
        splitViewFromHomeScreen()
        // Access hamburger menu and tap on "new tab"
        let tabsButtonIdentifier = AccessibilityIdentifiers.Toolbar.tabsButton
        let topSites = AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell
        let newTab = AccessibilityIdentifiers.Toolbar.addNewTabButton
        // A new tab is opened in the same window
        mozWaitForElementToExist(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField])
        mozWaitForElementToExist(app.collectionViews.firstMatch)
        mozWaitForElementToExist(app.staticTexts[AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.topSites])
        mozWaitForElementToExist(app.staticTexts[AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.merino])
        app.links[topSites].firstMatch.waitAndTap()
        waitUntilPageLoad()
        app.buttons[newTab].firstMatch.waitAndTap()
        let tabButtonSecondWindow = app.buttons.matching(identifier: tabsButtonIdentifier).element(boundBy: 0)
        XCTAssertEqual(tabButtonSecondWindow.value as? String, "2", "Number of tabs opened should be equal to 2")
        // A new tab is opened in the same window
        app.links.matching(identifier: topSites).element(boundBy: 7).waitAndTap()
        waitUntilPageLoad()
        let tabButtonFirstWindow = app.buttons.matching(identifier: tabsButtonIdentifier).element(boundBy: 1)
        XCTAssertEqual(tabButtonFirstWindow.value as? String, "2", "Number of tabs opened should be equal to 2")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3374336
    func testOpenWindowFromTabSwitcher() {
        if skipPlatform { return }
        openWindowFromTabSwitcher(windowsNumber: 1)
    }

    private func splitViewFromHomeScreen() {
        dotMenu.waitAndTap()
        splitView.waitAndTap()
        springboard.icons.elementContainingText("split view with Fennec").waitAndTap()
        mozWaitForElementToNotExist(springboard.icons.elementContainingText("split view with Fennec"))
    }

    // Param windowsNumber - number of tab windows to open from switcher
    private func openWindowFromTabSwitcher(windowsNumber: Int) {
        for  _ in 1...windowsNumber {
            dotMenu.waitAndTap()
            let cardOrgMozillaIosFennecButton = springboard.buttons["card:org.mozilla.ios.Fennec:"]
            cardOrgMozillaIosFennecButton.waitAndTap()
        }
    }

    // Param windowToClose - 0 for the first window, 1 for the second window
    func closeSplitViewWindow(windowToClose: Int) {
        dotMenuIdentifier.element(boundBy: windowToClose).tapWithRetry()
        springboard.buttons["top-affordance-close-window"].tapWithRetry()
    }
}
