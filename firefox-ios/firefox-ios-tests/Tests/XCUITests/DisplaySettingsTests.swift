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
                app.navigationBars["Appearance"],
                app.buttons[AccessibilityIdentifiers.Settings.Appearance.automaticThemeView],
                app.switches[AccessibilityIdentifiers.Settings.Appearance.darkModeToggle]
            ]
        )

        let automaticIsSelected = app.buttons[AccessibilityIdentifiers.Settings.Appearance.automaticThemeView].value
        XCTAssertEqual(automaticIsSelected as? String, "1")

        let lightThemeValue = app.buttons[AccessibilityIdentifiers.Settings.Appearance.lightThemeView].value
        XCTAssertEqual(lightThemeValue as? String, "0")

        let darkThemeValue = app.buttons[AccessibilityIdentifiers.Settings.Appearance.darkThemeView].value
        XCTAssertEqual(darkThemeValue as? String, "0")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2337487
    func testCheckSystemThemeChanges() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(DisplaySettings)

        // Select Light mode
        navigator.performAction(Action.SelectLightTheme)
        let lightIsSelected = app.buttons[AccessibilityIdentifiers.Settings.Appearance.lightThemeView].value
        XCTAssertEqual(lightIsSelected as? String, "1")

        // Select Dark mode
        navigator.performAction(Action.SelectDarkTheme)
        let darkIsSelected = app.buttons[AccessibilityIdentifiers.Settings.Appearance.darkThemeView].value
        XCTAssertEqual(darkIsSelected as? String, "1")

        // Select Automatic mode
        navigator.performAction(Action.SelectAutomaticTheme)
        let automaticIsSelected = app.buttons[AccessibilityIdentifiers.Settings.Appearance.automaticThemeView].value
        XCTAssertEqual(automaticIsSelected as? String, "1")
    }
}
