// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest

class TabCounterTests: BaseTestCase {

    func testTabIncrement() throws {
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.CloseURLBarOpen)
        waitForTabsButton()

        var tabsOpen = app.buttons["Show Tabs"].value
        XCTAssertEqual("1", tabsOpen as? String)

        navigator.createNewTab()
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.CloseURLBarOpen)
        waitForTabsButton()

        tabsOpen = app.buttons["Show Tabs"].value
        XCTAssertEqual("2", tabsOpen as? String)

        navigator.goto(TabTray)
        tabsOpen = app.buttons["2"].label
        XCTAssertTrue(app.buttons["2"].isSelected)
        XCTAssertEqual("2", tabsOpen as? String)
    }

    func testTabDecrement() throws {
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.CloseURLBarOpen)
        waitForTabsButton()

        var tabsOpen = app.buttons["Show Tabs"].value
        XCTAssertEqual("1", tabsOpen as? String)

        navigator.createNewTab()
        navigator.nowAt(NewTabScreen)
        
        navigator.performAction(Action.CloseURLBarOpen)
        waitForTabsButton()

        tabsOpen = app.buttons["Show Tabs"].value
        XCTAssertEqual("2", tabsOpen as? String)

        navigator.goto(TabTray)
        tabsOpen = app.buttons["2"].label
        XCTAssertTrue(app.buttons["2"].isSelected)
        XCTAssertEqual("2", tabsOpen as? String)

        if isTablet {
            app.otherElements["Tabs Tray"].collectionViews.cells.element(boundBy: 0).buttons["tab close"].tap()
        } else {
            app.otherElements["Tabs Tray"].cells.element(boundBy: 0).buttons["tab close"].tap()
        }

        app.otherElements["Tabs Tray"].cells.element(boundBy: 0).tap()
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.CloseURLBarOpen)
        waitForTabsButton()

        tabsOpen = app.buttons["Show Tabs"].value
        XCTAssertEqual("1", tabsOpen as? String)

        navigator.goto(TabTray)
        tabsOpen = app.segmentedControls["navBarTabTray"].buttons.element(boundBy:0).label
        XCTAssertTrue(app.segmentedControls.buttons.element(boundBy: 0).isSelected)
        XCTAssertEqual("1", tabsOpen as? String)
    }
}
