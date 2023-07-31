// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

class TabCounterTests: BaseTestCase {
    func testTabIncrement() throws {
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()

        var tabsOpen = app.buttons["Show Tabs"].value
        XCTAssertEqual("1", tabsOpen as? String)

        navigator.createNewTab()
        navigator.nowAt(NewTabScreen)
        if !iPad() {
            navigator.performAction(Action.CloseURLBarOpen)
        }
        waitForTabsButton()

        tabsOpen = app.buttons["Show Tabs"].value
        XCTAssertEqual("2", tabsOpen as? String)

        // Check only for iPhone, for iPad there is not counter in tab tray
        if !iPad() {
            navigator.goto(TabTray)
            let navBarTabTrayButton = app.segmentedControls["navBarTabTray"].buttons.firstMatch
            waitForExistence(navBarTabTrayButton)
            XCTAssertTrue(navBarTabTrayButton.isSelected)
            let tabsOpenTabTray: String = navBarTabTrayButton.label
            XCTAssertTrue(tabsOpenTabTray.hasSuffix("2"))
        }
    }

    func testTabDecrement() throws {
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()

        var tabsOpen = app.buttons["Show Tabs"].value
        XCTAssertEqual("1", tabsOpen as? String)

        navigator.createNewTab()
        navigator.nowAt(NewTabScreen)

        if !iPad() {
            navigator.performAction(Action.CloseURLBarOpen)
        }
        waitForTabsButton()

        tabsOpen = app.buttons["Show Tabs"].value
        XCTAssertEqual("2", tabsOpen as? String)

        navigator.goto(TabTray)

        if isTablet {
            app.otherElements["Tabs Tray"].collectionViews.cells.element(boundBy: 0).buttons[StandardImageIdentifiers.Large.cross].tap()
        } else {
            let navBarTabTrayButton = app.segmentedControls["navBarTabTray"].buttons.firstMatch
            waitForExistence(navBarTabTrayButton)
            XCTAssertTrue(navBarTabTrayButton.isSelected)
            let tabsOpenTabTray: String = navBarTabTrayButton.label
            XCTAssertTrue(tabsOpenTabTray.hasSuffix("2"))

            app.otherElements["Tabs Tray"].cells.element(boundBy: 0).buttons[StandardImageIdentifiers.Large.cross].tap()
        }

        app.otherElements["Tabs Tray"].cells.element(boundBy: 0).tap()
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()

        tabsOpen = app.buttons["Show Tabs"].value
        XCTAssertEqual("1", tabsOpen as? String)

        navigator.goto(TabTray)
        if isTablet {
            waitForExistence(app.navigationBars["Client.TabTrayView"])
        } else {
            waitForExistence(app.navigationBars["Open Tabs"])
        }
        tabsOpen = app.segmentedControls.buttons.element(boundBy: 0).label
        XCTAssertTrue(app.segmentedControls.buttons.element(boundBy: 0).isSelected)
        if !isTablet {
            waitForExistence(app.segmentedControls.firstMatch, timeout: 5)
            let tabsOpenTabTray: String = app.segmentedControls.buttons.firstMatch.label
            XCTAssertTrue(tabsOpenTabTray.hasSuffix("1"))
        }
    }
}
