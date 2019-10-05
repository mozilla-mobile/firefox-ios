/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class DisplaySettingTests: BaseTestCase {

    override func tearDown() {
        navigator.goto(DisplaySettings)
        waitForExistence(app.switches["DisplaySwitchValue"])
        if (app.switches["DisplaySwitchValue"].value! as! String == "1") {
            app.switches["DisplaySwitchValue"].tap()
        }
        super.tearDown()
    }

    func testCheckDisplaySettingsDefault() {
        navigator.goto(DisplaySettings)
        waitForExistence(app.navigationBars["Display"])
        XCTAssertTrue(app.tables["DisplayTheme.Setting.Options"].exists)
        let switchValue = app.switches["DisplaySwitchValue"].value!
        XCTAssertEqual(switchValue as! String, "0")
        XCTAssertTrue(app.tables.cells.staticTexts["Light"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts["Dark"].exists)
    }

    func testModifySwitchAutomatically() {
        navigator.goto(DisplaySettings)
        waitForExistence(app.switches["DisplaySwitchValue"])
        navigator.performAction(Action.SelectAutomatically)
        waitForExistence(app.sliders["0%"])
        XCTAssertFalse(app.tables.cells.staticTexts["Dark"].exists)

        // Going back to Settings and Display settings keeps the value
        navigator.goto(SettingsScreen)
        navigator.goto(DisplaySettings)
        waitForExistence(app.switches["DisplaySwitchValue"])
        let switchValue = app.switches["DisplaySwitchValue"].value!
        XCTAssertEqual(switchValue as! String, "1")
        XCTAssertFalse(app.tables.cells.staticTexts["Dark"].exists)

        // Unselect the Automatic mode
        navigator.performAction(Action.SelectAutomatically)
        waitForExistence(app.tables.cells.staticTexts["Light"])
        XCTAssertTrue(app.tables.cells.staticTexts["Dark"].exists)
    }

    func testChangeMode() {
        // From XCUI there is now way to check the Mode, but at least we test it can be changed
        if iPad() {
        navigator.goto(SettingsScreen)
        }
        navigator.goto(DisplaySettings)
        waitForExistence(app.cells.staticTexts["Dark"], timeout: 5)
        navigator.performAction(Action.SelectDarkMode)
        navigator.goto(SettingsScreen)
        navigator.performAction(Action.SelectLightMode)
    }
}
