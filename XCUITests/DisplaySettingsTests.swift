/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class DisplaySettingTests: BaseTestCase {

    func testCheckDisplaySettingsDefault() {
        navigator.goto(DisplaySettings)
        Base.helper.waitForExistence(Base.app.navigationBars["Theme"])
        XCTAssertTrue(Base.app.tables["DisplayTheme.Setting.Options"].exists)
        let switchValue = Base.app.switches["SystemThemeSwitchValue"].value!
        XCTAssertEqual(switchValue as! String, "1")
    }

    func testCheckSystemThemeChanges() {
        navigator.goto(DisplaySettings)
        Base.helper.waitForExistence(Base.app.switches["SystemThemeSwitchValue"])
        navigator.performAction(Action.SystemThemeSwitch)
        Base.helper.waitForExistence(Base.app.tables["DisplayTheme.Setting.Options"].otherElements.staticTexts["SWITCH MODE"])

        // Going back to Settings and Display settings keeps the value
        navigator.goto(SettingsScreen)
        navigator.goto(DisplaySettings)
        Base.helper.waitForExistence(Base.app.switches["SystemThemeSwitchValue"])
        let switchValue = Base.app.switches["SystemThemeSwitchValue"].value!
        XCTAssertEqual(switchValue as! String, "0")
        XCTAssertTrue(Base.app.cells.staticTexts["Light"].exists)
        XCTAssertTrue(Base.app.cells.staticTexts["Dark"].exists)

        // Select the Automatic mode
        navigator.performAction(Action.SelectAutomatically)

        XCTAssertTrue(Base.app.tables.otherElements["THRESHOLD"].exists)
        XCTAssertFalse(Base.app.cells.staticTexts["Light"].exists)
        XCTAssertFalse(Base.app.cells.staticTexts["Dark"].exists)

        // Now select the Manaul mode
        navigator.performAction(Action.SelectManually)
        XCTAssertFalse(Base.app.tables.otherElements["THRESHOLD"].exists)
        XCTAssertTrue(Base.app.cells.staticTexts["Light"].exists)
        XCTAssertTrue(Base.app.cells.staticTexts["Dark"].exists)

        // Enable back syste theme
        navigator.performAction(Action.SystemThemeSwitch)
        let switchValueAfter = Base.app.switches["SystemThemeSwitchValue"].value!
        XCTAssertEqual(switchValueAfter as! String, "1")
        XCTAssertFalse(Base.app.tables["DisplayTheme.Setting.Options"].otherElements.staticTexts["SWITCH MODE"].exists)
    }
}
