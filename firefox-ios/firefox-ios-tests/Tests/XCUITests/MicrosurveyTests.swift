// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

final class MicrosurveyTests: BaseTestCase {
    private var microsurveyScreen: MicrosurveyScreen!
    private var browserScreen: BrowserScreen!
    private var toolbarScreen: ToolbarScreen!
    private var tabTrayScreen: TabTrayScreen!
    private var settingScreen: SettingScreen!

    override func setUp() async throws {
        launchArguments = [
            LaunchArguments.SkipIntro,
            LaunchArguments.ResetMicrosurveyExpirationCount
        ]
        try await super.setUp()
        app.launch()
        microsurveyScreen = MicrosurveyScreen(app: app)
        browserScreen = BrowserScreen(app: app)
        toolbarScreen = ToolbarScreen(app: app)
        tabTrayScreen = TabTrayScreen(app: app)
        settingScreen = SettingScreen(app: app)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2776931
    func testShowMicrosurvey() {
        generateTriggerForMicrosurvey()
        microsurveyScreen.tapTakeSurveyButton()

        microsurveyScreen.assertSurveyExists()
        microsurveyScreen.tapFirstSurveyOption()
        microsurveyScreen.assertFirstSurveyOptionSelected()
        microsurveyScreen.assertSurveyOptionUnselected(label: "Neutral")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2776934
    func testCloseButtonDismissesSurveyAndPrompt() {
        generateTriggerForMicrosurvey()
        microsurveyScreen.tapTakeSurveyButton()

        microsurveyScreen.tapSurveyCloseButton()

        microsurveyScreen.assertSurveyDismissed()
        microsurveyScreen.assertPromptDismissed()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2776933
    func testCloseButtonDismissesMicrosurveyPrompt() {
        // Workaround: The microsurvey prompt may not appear on the first run due to retained app
        // state or missing triggers.
        // To ensure the prompt is shown, the app is terminated and relaunched to make sure the
        // microsurvey is triggered again.
        app.terminate()
        app.launch()
        generateTriggerForMicrosurvey()
        microsurveyScreen.assertPromptExists()
        microsurveyScreen.tapPromptCloseButton()
        microsurveyScreen.assertPromptDismissed()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2776932
    func testURLBorderHiddenWhenMicrosurveyPromptShown() throws {
        guard !iPad() else {
            throw XCTSkip("Toolbar option not available for iPad")
        }
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)
        settingScreen.navigateToToolbarSettings()
        settingScreen.selectBottomToolbar()
        settingScreen.tapBackToSettings()
        settingScreen.closeSettingsWithDoneButton()
        generateTriggerForMicrosurvey()

        microsurveyScreen.assertTopBorderHidden()

        microsurveyScreen.assertPromptExists()
        microsurveyScreen.tapPromptCloseButton()
        microsurveyScreen.assertPromptDismissed()

        microsurveyScreen.assertTopBorderVisible()
    }

    private func generateTriggerForMicrosurvey() {
        toolbarScreen.tapOnTabsButton()
        tabTrayScreen.switchToPrivateMode()
        tabTrayScreen.tapOnNewTabButton()
        browserScreen.navigateToURL(path(forTestPage: url_2["url"]!))
        waitUntilPageLoad()
    }
}
