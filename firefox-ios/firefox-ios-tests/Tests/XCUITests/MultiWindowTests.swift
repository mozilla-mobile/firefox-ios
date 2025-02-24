// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

class MultiWindowTests: IpadOnlyTestCase {
    let dotMenu = springboard.buttons["top-affordance:org.mozilla.ios.Fennec"]
    let splitView = springboard.buttons["top-affordance-split-view-button"]
    let dotMenuIdentifier = springboard.buttons.matching(identifier: "top-affordance:org.mozilla.ios.Fennec")

    override func setUp() {
        super.setUp()
        super.setUpLaunchArguments()
        if dotMenuIdentifier.element(boundBy: 1).exists {
            closeSplitViewWindow(windowToClose: 1)
        }
    }

    override func tearDown() {
        if dotMenuIdentifier.element(boundBy: 1).exists {
            closeSplitViewWindow(windowToClose: 1)
        }
        super.tearDown()
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
        let settingsMenuButton = AccessibilityIdentifiers.Toolbar.settingsMenuButton
        let newTab = AccessibilityIdentifiers.MainMenu.newTab
        // A new tab is opened in the same window
        app.links[topSites].firstMatch.waitAndTap()
        app.buttons[settingsMenuButton].firstMatch.waitAndTap()
        app.cells[newTab].firstMatch.waitAndTap()
        let tabButtonSecondWindow = app.buttons.matching(identifier: tabsButtonIdentifier).element(boundBy: 0)
        XCTAssertEqual(tabButtonSecondWindow.value as? String, "2", "Number of tabs opened should be equal to 2")
        // A new tab is opened in the same window
        app.links.matching(identifier: topSites).element(boundBy: 7).waitAndTap()
        app.buttons[settingsMenuButton].firstMatch.waitAndTap()
        app.cells[newTab].firstMatch.waitAndTap()
        let tabButtonFirstWindow = app.buttons.matching(identifier: tabsButtonIdentifier).element(boundBy: 1)
        // Automation issue - action performed in window A is mirrored in window B
        // Workaround until the automation issue is fixed
        XCTAssertEqual(tabButtonFirstWindow.value as? String, "3", "Number of tabs opened should be equal to 3")
    }

    func testOpenWindowFromTabSwitcher() {
        if skipPlatform { return }
        openWindowFromTabSwitcher(windowsNumber: 1)
        // selectTabFromSwitcher()
    }

    private func splitViewFromHomeScreen() {
        dotMenu.waitAndTap()
        splitView.waitAndTap()
        springboard.icons.elementContainingText("split view with Fennec").waitAndTap()
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
        dotMenuIdentifier.element(boundBy: windowToClose).waitAndTap()
        springboard.buttons["top-affordance-close-window"].waitAndTap()
    }

    // Coudn't find a way to select a tab from switcher
//    private func selectTabFromSwitcher() {
//        let tabIdentifier = "card:org.mozilla.ios.Fennec:sceneID:org.mozilla.ios.Fennec"
//    }
}
