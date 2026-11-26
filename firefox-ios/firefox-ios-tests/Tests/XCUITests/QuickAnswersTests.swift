// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class QuickAnswersTests: FeatureFlaggedTestBase {
    var homePageScreen: HomePageScreen!
    var quickAnswersScreen: QuickAnswersScreen!
    var toolbarScreen: ToolbarScreen!
    var settingScreen: SettingScreen!
    var quickAnswersSettingsScreen: QuickAnswersSettingsScreen!

    override func setUp() async throws {
        try await super.setUp()

        homePageScreen = HomePageScreen(app: app)
        quickAnswersScreen = QuickAnswersScreen(app: app)
        toolbarScreen = ToolbarScreen(app: app)
        settingScreen = SettingScreen(app: app)
        quickAnswersSettingsScreen = QuickAnswersSettingsScreen(app: app)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/4158184
    // Regression
    func testDismissOptInSheetWithCloseButton() throws {
        try launchWithQuickAnswersEnabled()
        homePageScreen.dismissQuickAnswersTipIfPresented()

        homePageScreen.tapQuickAnswersButton()
        quickAnswersScreen.assertOptInSheetShown()

        quickAnswersScreen.closeOptInSheet()
        quickAnswersScreen.assertOptInSheetDismissed()
        homePageScreen.assertHomepageIsDisplayed()
        homePageScreen.assertQuickAnswersButtonIsHittable()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/4158170
    // Regression
    func testQuickAnswersSettingsLayoutAndDefaults() throws {
        try launchWithQuickAnswersEnabled()
        homePageScreen.dismissQuickAnswersTipIfPresented()

        toolbarScreen.openSettingsFromMenu()
        settingScreen.assertQuickAnswersSettingsIsInGeneralSection(isOn: true)

        settingScreen.openQuickAnswersSettings()
        quickAnswersSettingsScreen.assertScreenShown()

        quickAnswersSettingsScreen.assertQuickAnswersSwitchIsOn()
        quickAnswersSettingsScreen.assertDescriptionWithBlueLearnMoreLink()

        quickAnswersSettingsScreen.tapLearnMore()
        quickAnswersSettingsScreen.assertSumoPageOpened()
    }

    private func launchWithQuickAnswersEnabled() throws {
        try XCTSkipIf(
            isFirefox || isFirefoxBeta,
            "Skipping because on Firefox and FirefoxBeta addLaunchArgument cannot override the default " +
            "experiment values, so Quick Answers cannot be forced on"
        )
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "quick-answers-feature")
        app.launch()
    }
}
