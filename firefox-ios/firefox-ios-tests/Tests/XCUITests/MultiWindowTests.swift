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

    func testMultiWindowFromHomeScreen() {
        if skipPlatform { return }
        dismissSurveyPrompt()
        splitViewFromHomeScreen()
        XCTAssertEqual(dotMenuIdentifier.count, 2, "There are not 2 instances opened")
        // Tap menu button on first and second window
        let menuButton = AccessibilityIdentifiers.Toolbar.settingsMenuButton
        mozWaitForElementToExist(app.buttons.matching(identifier: menuButton).element(boundBy: 0))
        app.buttons.matching(identifier: menuButton).element(boundBy: 0).tap()
        mozWaitForElementToExist(app.buttons.matching(identifier: menuButton).element(boundBy: 1))
        app.buttons.matching(identifier: menuButton).element(boundBy: 1).tap()
        // Tap on settings on first and second window
        let settings = StandardImageIdentifiers.Large.settings
        let settingsOption = app.tables.otherElements.matching(identifier: settings).element(boundBy: 0)
        settingsOption.tap()
        settingsOption.tap()
    }

    func testOpenWindowFromTabSwitcher() {
        if skipPlatform { return }
        openWindowFromTabSwitcher(windowsNumber: 1)
        // selectTabFromSwitcher()
    }

    private func splitViewFromHomeScreen() {
        mozWaitForElementToExist(dotMenu)
        dotMenu.tap()
        mozWaitForElementToExist(splitView)
        splitView.tap()
        springboard.icons.elementContainingText("split view with Fennec").tap()
    }

    // Param windowsNumber - number of tab windows to open from switcher
    private func openWindowFromTabSwitcher(windowsNumber: Int) {
        for  _ in 1...windowsNumber {
            mozWaitForElementToExist(dotMenu)
            dotMenu.tap()
            let cardOrgMozillaIosFennecButton = springboard.buttons["card:org.mozilla.ios.Fennec:"]
            cardOrgMozillaIosFennecButton.tap()
        }
    }

    // Param windowToClose - 0 for the first window, 1 for the second window
    func closeSplitViewWindow(windowToClose: Int) {
        mozWaitForElementToExist(dotMenuIdentifier.element(boundBy: windowToClose))
        dotMenuIdentifier.element(boundBy: windowToClose).tap()
        mozWaitForElementToExist(springboard.buttons["top-affordance-close-window"])
        springboard.buttons["top-affordance-close-window"].tap()
    }

    // Coudn't find a way to select a tab from switcher
//    private func selectTabFromSwitcher() {
//        let tabIdentifier = "card:org.mozilla.ios.Fennec:sceneID:org.mozilla.ios.Fennec"
//    }
}
