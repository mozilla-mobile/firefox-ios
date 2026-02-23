// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

@MainActor
final class TranslationsTests: FeatureFlaggedTestBase {
    var toolBarScreen: ToolbarScreen!
    var browserScreen: BrowserScreen!
    var translationSettingScreen: TranslationSettingsScreen!
    var settingsScreen: SettingScreen!

    override func setUp() async throws {
        try await super.setUp()

        toolBarScreen = ToolbarScreen(app: app)
        browserScreen = BrowserScreen(app: app)
        settingsScreen = SettingScreen(app: app)
        translationSettingScreen = TranslationSettingsScreen(app: app)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3211480
    func testTranslationFlow_withDifferentStates_translationExperimentOn() {
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "translations-feature")
        app.launch()

        navigateToTranslationTestPage()
        browserScreen.assertWebPageText(with: "例示用ドメイン")

        // Check that translation icon exists in inactive mode
        toolBarScreen.assertTranslateButtonExists(with: .inactive)
        toolBarScreen.tapTranslateButton(with: .inactive)

        // Check that translation icon switches to loading (spinner) and eventually active mode (blue button)
        toolBarScreen.assertTranslateButtonExists(with: .loading)
        toolBarScreen.assertTranslateButtonExists(with: .active)
        browserScreen.assertWebPageText(with: "Example domain")

        toolBarScreen.tapTranslateButton(with: .active)

        // Check that when tapping on translation button in active mode returns to inactive
        toolBarScreen.assertTranslateButtonExists(with: .inactive)
        browserScreen.assertWebPageText(with: "例示用ドメイン")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3240821
    func testTranslationSettingsShouldShow_translationExperimentOn() {
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "translations-feature")
        app.launch()

        navigator.goto(SettingsScreen)
        navigator.nowAt(SettingsScreen)

        // Check that translation feature setting is on
        settingsScreen.openTranslationSettings()
        translationSettingScreen.assertTranslationSwitchIsOn()

        dismissTranslationSettingsScreen()

        navigateToTranslationTestPage()

        // Check that translation icon is shown in toolbar
        toolBarScreen.assertTranslateButtonExists(with: .inactive)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3379185
    func testTranslationSettingsDoesNotAppear_translationExperimentOff() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "translations-feature")
        app.launch()
        navigator.goto(SettingsScreen)
        navigator.nowAt(SettingsScreen)

        // Check that translation setting is hidden
        settingsScreen.assertTranslationSettingsDoesNotExist()
        settingsScreen.closeSettingsWithDoneButton()

        navigateToTranslationTestPage()

        // Check that translation icon is not shown in toolbar
        toolBarScreen.assertTranslateButtonDoesNotExist(with: .inactive)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3210769
    func testTranslationSettingsFromToggleOnToOff_translationExperimentOn() {
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "translations-feature")
        app.launch()

        navigateToTranslationTestPage()

        // Check that translation icon is shown in toolbar
        toolBarScreen.assertTranslateButtonExists(with: .inactive)

        navigator.goto(SettingsScreen)
        navigator.nowAt(SettingsScreen)

        // Check that translation feature setting is on
        settingsScreen.openTranslationSettings()
        translationSettingScreen.assertTranslationSwitchIsOn()

        // Switch setting to be off
        translationSettingScreen.tapOnTranslationSwitch()
        translationSettingScreen.assertTranslationSwitchIsOff()

        dismissTranslationSettingsScreen()

        // Check that translation icon is no longer shown in toolbar
        toolBarScreen.assertTranslateButtonDoesNotExist(with: .inactive)

        navigator.nowAt(BrowserTab)
        navigator.goto(SettingsScreen)

        // Check that translation feature setting is off
        settingsScreen.openTranslationSettings()
        translationSettingScreen.assertTranslationSwitchIsOff()

        // Switch setting to be on
        translationSettingScreen.tapOnTranslationSwitch()
        translationSettingScreen.assertTranslationSwitchIsOn()

        dismissTranslationSettingsScreen()

        // Check that translation icon is shown in toolbar
        toolBarScreen.assertTranslateButtonExists(with: .inactive)
    }

    private func dismissTranslationSettingsScreen() {
        translationSettingScreen.tapOnBackButton()
        settingsScreen.closeSettingsWithDoneButton()
    }

    private func navigateToTranslationTestPage() {
        browserScreen.tapOnAddressBar()
        let urlPath = path(forTestPage: "test-translation.html")
        browserScreen.typeOnSearchBar(text: urlPath)
        browserScreen.typeOnSearchBar(text: "\r")
        waitUntilPageLoad()
    }
}
