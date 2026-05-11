// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class CopiedLinksTests: BaseTestCase {
    private var settingScreen: SettingScreen!
    private var toolbarScreen: ToolbarScreen!
    private var mainMenuScreen: MainMenuScreen!

    override func setUp() async throws {
        try await super.setUp()
        settingScreen = SettingScreen(app: app)
        toolbarScreen = ToolbarScreen(app: app)
        mainMenuScreen = MainMenuScreen(app: app)
    }

    // This test is enable Offer to open copied links, when opening firefox
    func testCopiedLinks() {
        toolbarScreen.tapSettingsMenuButton()
        mainMenuScreen.tapSettings()
        settingScreen.openBrowsingSettings()

        // Check Offer to open copied links, when opening firefox is off
        settingScreen.assertCopiedLinksToggleIsOff()

        // Switch on, Offer to open copied links, when opening firefox
        settingScreen.tapCopiedLinksToggle()

        // Check Offer to open copied links, when opening firefox is on
        settingScreen.assertCopiedLinksToggleIsOn()

        settingScreen.tapBackToSettings()
        settingScreen.closeSettingsWithDoneButton()

        toolbarScreen.tapSettingsMenuButton()
        mainMenuScreen.tapSettings()
        settingScreen.openBrowsingSettings()

        // Check Offer to open copied links, when opening firefox is on
        settingScreen.assertCopiedLinksToggleIsOn()
    }
}
