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
    var mainMenuScreen: MainMenuScreen!

    override func setUp() async throws {
        try await super.setUp()

        toolBarScreen = ToolbarScreen(app: app)
        browserScreen = BrowserScreen(app: app)
        settingsScreen = SettingScreen(app: app)
        translationSettingScreen = TranslationSettingsScreen(app: app)
        mainMenuScreen = MainMenuScreen(app: app)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3211480
    // Expected failure: iOS 15
    // https://github.com/mozilla-mobile/firefox-ios/issues/35608
    // Regression
    func testTranslationFlow_withDifferentStates_translationExperimentOn() {
        launchWithTranslationsEnabled()

        navigateToTranslationTestPage()
        browserScreen.assertWebPageText(with: "例示用ドメイン")

        // Check that translation icon exists in inactive mode
        toolBarScreen.assertTranslateButtonExists(with: .inactive)
        toolBarScreen.tapTranslateButton(with: .inactive)

        // A language picker may appear before translating; select English if it does
        toolBarScreen.selectTranslationLanguageIfPresented()

        // Check that translation icon switches to loading (spinner) and eventually active mode (blue button)
        toolBarScreen.assertTranslationInProgressOrCompleted()
        toolBarScreen.waitForTranslateButtonToBecomeActive()
        browserScreen.assertWebPageText(with: "Example domain")

        toolBarScreen.tapTranslateButton(with: .active)

        // Check that when tapping on translation button in active mode returns to inactive
        toolBarScreen.assertTranslateButtonExists(with: .inactive)
        browserScreen.assertWebPageText(with: "例示用ドメイン")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3240671
    // Regression
    func testInactiveTranslateButtonNextToShareButton_translationExperimentOn() {
        launchWithTranslationsEnabled()

        navigateToTranslationTestPage()
        toolBarScreen.assertTranslateButtonExists(with: .inactive)
        toolBarScreen.assertTranslateButtonIsNextToShareButton()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3480570
    // Regression
    func testLongPressInactiveTranslateButtonShowsLanguagePicker_translationExperimentOn() {
        launchWithTranslationsEnabled()

        navigateToTranslationTestPage()
        browserScreen.assertWebPageText(with: "例示用ドメイン")
        toolBarScreen.assertTranslateButtonExists(with: .inactive)

        toolBarScreen.longPressTranslateButton()
        toolBarScreen.assertTranslationLanguagePickerShowsSingleLanguage("English")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3486262
    // Expected failure: iOS 15
    // https://github.com/mozilla-mobile/firefox-ios/issues/35608
    // Regression
    func testLongPressActiveTranslateButtonShowsTranslatedLanguagePicker_translationExperimentOn() {
        launchWithTranslationsEnabled()

        openTranslationSettings()
        addPreferredLanguage(searchTerm: "German", nativeName: "Deutsch")
        dismissTranslationSettingsScreen()

        navigateToTranslationTestPage()
        translatePageToEnglish()

        toolBarScreen.longPressTranslateButton(with: .active)
        toolBarScreen.assertActiveTranslationLanguagePicker(translatedTo: "English", otherLanguages: ["Deutsch (German)"])

        toolBarScreen.tapShowOriginal()
        toolBarScreen.assertTranslationLanguagePickerIsDismissed()
        browserScreen.assertWebPageText(with: "例示用ドメイン")
        toolBarScreen.assertTranslateButtonExists(with: .inactive)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3240821
    func testTranslationSettingsShouldShow_translationExperimentOn() {
        launchWithTranslationsEnabled()

        // Check that translation feature setting is on
        openTranslationSettings()
        translationSettingScreen.assertTranslationSwitchIsOn()

        dismissTranslationSettingsScreen()

        navigateToTranslationTestPage()

        // Check that translation icon is shown in toolbar
        toolBarScreen.assertTranslateButtonExists(with: .inactive)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3379185
    func testTranslationSettingsDoesNotAppear_translationExperimentOff() throws {
        try XCTSkipIf(
            isFirefoxBeta || isFirefox,
            "Skipping test because on Firefox and FirefoxBeta addLaunchArgument cannot override the " +
            "default experiment value, so the translations feature cannot be forced off"
        )
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "translations-feature")
        app.launch()
        openSettingsFromToolbarMenu()

        // Check that translation setting is hidden
        settingsScreen.assertTranslationSettingsDoesNotExist()
        settingsScreen.closeSettingsWithDoneButton()

        navigateToTranslationTestPage()

        // Check that translation icon is not shown in toolbar
        toolBarScreen.assertTranslateButtonDoesNotExist(with: .inactive)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3210769
    // Expected failure: iOS 15
    // https://github.com/mozilla-mobile/firefox-ios/issues/35608
    // Regression
    func testTranslationSettingsFromToggleOnToOff_translationExperimentOn() {
        launchWithTranslationsEnabled()

        // Check that translation feature setting is on by default
        openTranslationSettings()
        translationSettingScreen.assertTranslationSwitchIsOn()
        dismissTranslationSettingsScreen()

        navigateToTranslationTestPage()
        assertPageCanBeTranslated()

        // Switch setting to be off
        openTranslationSettings()
        translationSettingScreen.tapOnTranslationSwitch()
        translationSettingScreen.assertTranslationSwitchIsOff()
        dismissTranslationSettingsScreen()

        // Check that translation is no longer available from the toolbar or the main menu
        navigateToTranslationTestPage()
        toolBarScreen.assertTranslateButtonDoesNotExist(with: .inactive)
        toolBarScreen.tapSettingsMenuButton()
        mainMenuScreen.assertTranslatePageItemDoesNotExist()
        mainMenuScreen.closeMenu()

        // Switch setting back on
        openTranslationSettings()
        translationSettingScreen.assertTranslationSwitchIsOff()
        translationSettingScreen.tapOnTranslationSwitch()
        translationSettingScreen.assertTranslationSwitchIsOn()
        dismissTranslationSettingsScreen()

        navigateToTranslationTestPage()
        assertPageCanBeTranslated()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3904778
    // Regression
    func testSelectLanguageSheet_translationExperimentOn() {
        launchWithTranslationsEnabled()

        openTranslationSettings()
        translationSettingScreen.tapAddLanguage()
        translationSettingScreen.assertLanguagePickerIsDisplayed()
        translationSettingScreen.assertLanguagePickerListIsNotEmpty()

        translationSettingScreen.tapLanguagePickerSearchField()
        translationSettingScreen.assertLanguagePickerSearchIsActive()
        translationSettingScreen.tapLanguagePickerSearchCancelButton()
        translationSettingScreen.assertLanguagePickerSearchIsInactive()

        translationSettingScreen.searchLanguagePicker(for: "German")
        translationSettingScreen.assertLanguagePickerListIsFiltered(to: "German")
        translationSettingScreen.selectLanguageInPicker("German")
        translationSettingScreen.assertLanguagePickerIsDismissed()
        translationSettingScreen.assertPreferredLanguageExists("Deutsch")

        translationSettingScreen.tapAddLanguage()
        translationSettingScreen.assertLanguagePickerIsDisplayed()
        translationSettingScreen.tapLanguagePickerCloseButton()
        translationSettingScreen.assertLanguagePickerIsDismissed()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3917536
    // Regression
    func testDeviceLanguageCannotBeRemoved_translationExperimentOn() {
        launchWithTranslationsEnabled()

        openTranslationSettings()
        addPreferredLanguage(searchTerm: "German", nativeName: "Deutsch")
        translationSettingScreen.assertDeviceLanguageExists()

        translationSettingScreen.tapEditButton()
        translationSettingScreen.assertLanguageIsRemovable("Deutsch")
        translationSettingScreen.assertDeviceLanguageIsNotRemovable()

        translationSettingScreen.removeLanguage("Deutsch")
        translationSettingScreen.assertPreferredLanguageDoesNotExist("Deutsch")
        translationSettingScreen.assertDeviceLanguageIsNotRemovable()

        translationSettingScreen.tapDoneButton()
        translationSettingScreen.assertPreferredLanguageDoesNotExist("Deutsch")
        translationSettingScreen.assertDeviceLanguageExists()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3919023
    // Regression
    func testAddLanguageHiddenInEditMode_translationExperimentOn() {
        launchWithTranslationsEnabled()

        openTranslationSettings()
        addPreferredLanguage(searchTerm: "German", nativeName: "Deutsch")
        translationSettingScreen.assertAddLanguageIs(visible: true)

        translationSettingScreen.tapEditButton()
        translationSettingScreen.assertLanguageIsRemovable("Deutsch")
        translationSettingScreen.assertReorderHandleExists(for: "Deutsch")
        translationSettingScreen.assertReorderHandleExists(for: "English")
        translationSettingScreen.assertAddLanguageIs(visible: false)
    }

    private func addPreferredLanguage(searchTerm: String, nativeName: String) {
        translationSettingScreen.tapAddLanguage()
        translationSettingScreen.searchLanguagePicker(for: searchTerm)
        translationSettingScreen.selectLanguageInPicker(searchTerm)
        translationSettingScreen.assertLanguagePickerIsDismissed()
        translationSettingScreen.assertPreferredLanguageExists(nativeName)
    }

    private func assertPageCanBeTranslated() {
        browserScreen.assertWebPageText(with: "例示用ドメイン")
        translatePageToEnglish()

        // Revert the translation so the page is back in its original language
        toolBarScreen.tapTranslateButton(with: .active)
        toolBarScreen.assertTranslateButtonExists(with: .inactive)
        browserScreen.assertWebPageText(with: "例示用ドメイン")
    }

    private func translatePageToEnglish() {
        toolBarScreen.tapTranslateButton(with: .inactive)
        toolBarScreen.selectTranslationLanguageIfPresented()
        toolBarScreen.waitForTranslateButtonToBecomeActive()
        browserScreen.assertWebPageText(with: "Example domain")
    }

    private func launchWithTranslationsEnabled() {
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "translations-feature")
        app.launch()
    }

    private func openTranslationSettings() {
        openSettingsFromToolbarMenu()
        settingsScreen.openTranslationSettings()
    }

    private func dismissTranslationSettingsScreen() {
        translationSettingScreen.tapOnBackButton()
        settingsScreen.closeSettingsWithDoneButton()
    }

    private func openSettingsFromToolbarMenu() {
        toolBarScreen.tapSettingsMenuButton()
        mainMenuScreen.tapSettings()
    }

    private func navigateToTranslationTestPage() {
        browserScreen.tapOnAddressBar()
        let urlPath = path(forTestPage: "test-translation.html")
        browserScreen.typeOnSearchBar(text: urlPath)
        browserScreen.typeOnSearchBar(text: "\r")
        waitUntilPageLoad()
    }
}
