// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class DisplaySettingTests: BaseTestCase {
    private var settingScreen: SettingScreen!

    override func setUp() async throws {
        // Fresh install the app
        // removeApp() does not work on iOS 15 and 16 intermittently
        if name.contains("testCheckDisplaySettingsDefault") {
            if #available(iOS 17, *) {
                removeApp()
            }
        }
        // The app is correctly installed
        try await super.setUp()
        settingScreen = SettingScreen(app: app)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2337485
    func testCheckDisplaySettingsDefault() {
        navigator.goto(SettingsScreen)
        settingScreen.navigateToDisplaySettings()
        waitForElementsToExist(
            [
                app.navigationBars["Appearance"],
                app.buttons[AccessibilityIdentifiers.Settings.Appearance.automaticThemeView]
            ]
        )
        if #available(iOS 17, *) {
            waitForElementsToExist([app.switches[AccessibilityIdentifiers.Settings.Appearance.darkModeToggle]])
        } else {
            waitForElementsToExist([app.buttons[AccessibilityIdentifiers.Settings.Appearance.darkModeToggle]])
        }

        settingScreen.assertAutomaticThemeSelected()
        settingScreen.assertLightThemeSelected(false)
        settingScreen.assertDarkThemeSelected(false)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3298823
    func testCheckSystemThemeChanges() {
        navigator.goto(SettingsScreen)
        settingScreen.navigateToDisplaySettings()

        // Select Light mode
        settingScreen.selectLightTheme()
        settingScreen.assertLightThemeSelected()

        // Select Dark mode
        settingScreen.selectDarkTheme()
        settingScreen.assertDarkThemeSelected()

        // Select Automatic mode
        settingScreen.selectAutomaticTheme()
        settingScreen.assertAutomaticThemeSelected()
    }
}
