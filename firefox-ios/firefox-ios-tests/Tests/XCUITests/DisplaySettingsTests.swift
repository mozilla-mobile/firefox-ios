// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class DisplaySettingTests: BaseTestCase {
    // https://mozilla.testrail.io/index.php?/cases/view/2337485
    func testCheckDisplaySettingsDefault() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(DisplaySettings)
        waitForElementsToExist(
            [
                app.navigationBars["Theme"],
                app.tables["DisplayTheme.Setting.Options"]
            ]
        )
        let switchValue = app.switches["SystemThemeSwitchValue"].value!
        XCTAssertEqual(switchValue as? String, "1")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2337487
    func testCheckSystemThemeChanges() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(DisplaySettings)
        mozWaitForElementToExist(app.switches["SystemThemeSwitchValue"])
        navigator.performAction(Action.SystemThemeSwitch)
        waitForElementsToExist(
            [
                app.tables["DisplayTheme.Setting.Options"].otherElements.staticTexts["SWITCH MODE"],
                app.tables["DisplayTheme.Setting.Options"].otherElements.staticTexts["THEME PICKER"]
            ]
        )

        // Going back to Settings and Display settings keeps the value
        navigator.goto(SettingsScreen)
        navigator.goto(DisplaySettings)
        mozWaitForElementToExist(app.switches["SystemThemeSwitchValue"])
        let switchValue = app.switches["SystemThemeSwitchValue"].value!
        XCTAssertEqual(switchValue as? String, "0")
        waitForElementsToExist(
            [
                app.cells.staticTexts["Light"],
                app.cells.staticTexts["Dark"]
            ]
        )

        // Select the Automatic mode
        navigator.performAction(Action.SelectAutomatically)
        mozWaitForElementToExist(app.tables.otherElements["THRESHOLD"])
        mozWaitForElementToNotExist(app.cells.staticTexts["Light"])
        mozWaitForElementToNotExist(app.cells.staticTexts["Dark"])

        // Now select the Manual mode
        navigator.performAction(Action.SelectManually)
        mozWaitForElementToNotExist(app.tables.otherElements["THRESHOLD"])
        waitForElementsToExist(
            [
                app.cells.staticTexts["Light"],
                app.cells.staticTexts["Dark"]
            ]
        )

        // Enable back system theme
        navigator.performAction(Action.SystemThemeSwitch)
        let switchValueAfter = app.switches["SystemThemeSwitchValue"].value!
        XCTAssertEqual(switchValueAfter as? String, "1")
        mozWaitForElementToNotExist(app.tables["DisplayTheme.Setting.Options"].otherElements.staticTexts["SWITCH MODE"])
        mozWaitForElementToNotExist(app.tables["DisplayTheme.Setting.Options"].otherElements.staticTexts["THEME PICKER"])
    }
}
