// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest

class DisplaySettingTests: BaseTestCase {

    func testCheckDisplaySettingsDefault() {
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(DisplaySettings)
        waitForExistence(app.navigationBars["Theme"])
        XCTAssertTrue(app.tables["DisplayTheme.Setting.Options"].exists)
        let switchValue = app.switches["SystemThemeSwitchValue"].value!
        XCTAssertEqual(switchValue as! String, "1")
    }

    func testCheckSystemThemeChanges() {
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(DisplaySettings)
        waitForExistence(app.switches["SystemThemeSwitchValue"])
        navigator.performAction(Action.SystemThemeSwitch)
        waitForExistence(app.tables["DisplayTheme.Setting.Options"].otherElements.staticTexts["SWITCH MODE"])

        // Going back to Settings and Display settings keeps the value
        navigator.goto(SettingsScreen)
        navigator.goto(DisplaySettings)
        waitForExistence(app.switches["SystemThemeSwitchValue"])
        let switchValue = app.switches["SystemThemeSwitchValue"].value!
        XCTAssertEqual(switchValue as! String, "0")
        XCTAssertTrue(app.cells.staticTexts["Light"].exists)
        XCTAssertTrue(app.cells.staticTexts["Dark"].exists)

        // Select the Automatic mode
        navigator.performAction(Action.SelectAutomatically)

        XCTAssertTrue(app.tables.otherElements["THRESHOLD"].exists)
        XCTAssertFalse(app.cells.staticTexts["Light"].exists)
        XCTAssertFalse(app.cells.staticTexts["Dark"].exists)

        // Now select the Manaul mode
        navigator.performAction(Action.SelectManually)
        XCTAssertFalse(app.tables.otherElements["THRESHOLD"].exists)
        XCTAssertTrue(app.cells.staticTexts["Light"].exists)
        XCTAssertTrue(app.cells.staticTexts["Dark"].exists)

        // Enable back syste theme
        navigator.performAction(Action.SystemThemeSwitch)
        let switchValueAfter = app.switches["SystemThemeSwitchValue"].value!
        XCTAssertEqual(switchValueAfter as! String, "1")
        XCTAssertFalse(app.tables["DisplayTheme.Setting.Options"].otherElements.staticTexts["SWITCH MODE"].exists)
    }
}
