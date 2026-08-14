// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

@MainActor
final class AIControlsTests: FeatureFlaggedTestBase {
    var toolBarScreen: ToolbarScreen!
    var browserScreen: BrowserScreen!
    var settingsScreen: SettingScreen!
    var mainMenuScreen: MainMenuScreen!
    var aiControlsScreen: AIControlsScreen!
    var translationSettingScreen: TranslationSettingsScreen!
    var summarizeSettingScreen: SummarizeSettingsScreen!

    override func setUp() async throws {
        try await super.setUp()

        toolBarScreen = ToolbarScreen(app: app)
        browserScreen = BrowserScreen(app: app)
        settingsScreen = SettingScreen(app: app)
        mainMenuScreen = MainMenuScreen(app: app)
        aiControlsScreen = AIControlsScreen(app: app)
        translationSettingScreen = TranslationSettingsScreen(app: app)
        summarizeSettingScreen = SummarizeSettingsScreen(app: app)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3960880
    // Regression
    func testAIFeaturesSetToOffAreNotAvailable() throws {
        try XCTSkipIf(
            isFirefox || isFirefoxBeta,
            "Skipping because on Firefox and FirefoxBeta addLaunchArgument cannot override the default " +
            "experiment values, so the AI features cannot be forced on/off"
        )
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "ai-kill-switch-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "translations-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "hosted-summarizer-feature")
        app.launch()

        // Baseline: with the features enabled, Translation is available on a web page
        navigateToTranslationTestPage()
        toolBarScreen.assertTranslateButtonExists(with: .inactive)

        // Configuration 1: Block AI Enhancements ON forces Translation and Page Summaries OFF
        openSettingsFromToolbarMenu()
        settingsScreen.openAIControlsSettings()
        aiControlsScreen.assertScreenShown()
        // Establish a known "available" baseline before blocking so the transition to off is meaningful
        aiControlsScreen.setPageSummariesToggle(on: true)
        aiControlsScreen.turnOnBlockAIEnhancements()
        aiControlsScreen.assertTranslationToggleIsOff()
        aiControlsScreen.assertPageSummariesToggleIsOff()
        settingsScreen.tapBackToSettings()
        settingsScreen.closeSettingsWithDoneButton()

        assertAIFeaturesAreNotAvailable()

        // Configuration 2: Block AI Enhancements OFF, but each feature toggled OFF individually
        openSettingsFromToolbarMenu()
        settingsScreen.openAIControlsSettings()
        aiControlsScreen.assertScreenShown()
        // Turning the kill switch off re-enables the features; verify then turn each off individually
        aiControlsScreen.turnOffBlockAIEnhancements()
        aiControlsScreen.assertTranslationToggleIsOn()
        aiControlsScreen.turnOffTranslationToggle()
        aiControlsScreen.turnOffPageSummariesToggle()
        aiControlsScreen.assertTranslationToggleIsOff()
        aiControlsScreen.assertPageSummariesToggleIsOff()
        settingsScreen.tapBackToSettings()
        settingsScreen.closeSettingsWithDoneButton()

        assertAIFeaturesAreNotAvailable()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3965955
    // Regression
    func testTranslationSettingChangesReflectInAIControls() throws {
        try XCTSkipIf(
            isFirefox || isFirefoxBeta,
            "Skipping because on Firefox and FirefoxBeta addLaunchArgument cannot override the default " +
            "experiment values, so the AI features cannot be forced on/off"
        )
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "ai-kill-switch-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "translations-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "hosted-summarizer-feature")
        app.launch()

        navigateToTranslationTestPage()

        // The standalone Translation setting mirrors into AI Controls both with the kill switch untouched
        // and after it has been used to block AI features
        verifyStandaloneTranslationMirrorsAIControls(blockAIEnhancementsFirst: false)
        verifyStandaloneTranslationMirrorsAIControls(blockAIEnhancementsFirst: true)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3965956
    // Regression
    func testPageSummariesSettingChangesReflectInAIControls() throws {
        try XCTSkipIf(
            isFirefox || isFirefoxBeta,
            "Skipping because on Firefox and FirefoxBeta addLaunchArgument cannot override the default " +
            "experiment values, so the AI features cannot be forced on/off"
        )
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "ai-kill-switch-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "translations-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "hosted-summarizer-feature")
        app.launch()

        navigateToBookOfMozillaPage()

        verifyStandalonePageSummariesMirrorsAIControls(blockAIEnhancementsFirst: false)
        verifyStandalonePageSummariesMirrorsAIControls(blockAIEnhancementsFirst: true)
    }

    // MARK: - Helpers

    /// Drives the standalone Translation toggle ON → OFF → ON, asserting after each change that the AI
    /// Controls Translation toggle mirrors it and the translate toolbar button availability follows.
    private func verifyStandaloneTranslationMirrorsAIControls(blockAIEnhancementsFirst: Bool) {
        if blockAIEnhancementsFirst {
            openSettingsFromToolbarMenu()
            settingsScreen.openAIControlsSettings()
            aiControlsScreen.turnOnBlockAIEnhancements()
            aiControlsScreen.assertTranslationToggleIsOff()
            settingsScreen.tapBackToSettings()
            settingsScreen.closeSettingsWithDoneButton()
        }

        setStandaloneTranslationAndAssertMirror(on: true)
        toolBarScreen.assertTranslateButtonExists(with: .inactive)

        setStandaloneTranslationAndAssertMirror(on: false)
        toolBarScreen.assertTranslateButtonDoesNotExist(with: .inactive)

        // Re-enabling returns the feature even after Block AI Enhancements was used
        setStandaloneTranslationAndAssertMirror(on: true)
        toolBarScreen.assertTranslateButtonExists(with: .inactive)
    }

    /// Sets the standalone Translations toggle, then reopens AI Controls to assert it reflects the state.
    private func setStandaloneTranslationAndAssertMirror(on: Bool) {
        openSettingsFromToolbarMenu()
        settingsScreen.openTranslationSettings()
        translationSettingScreen.setTranslationSwitch(on: on)
        settingsScreen.tapBackToSettings()

        settingsScreen.openAIControlsSettings()
        if on {
            aiControlsScreen.assertTranslationToggleIsOn()
        } else {
            aiControlsScreen.assertTranslationToggleIsOff()
        }
        settingsScreen.tapBackToSettings()
        settingsScreen.closeSettingsWithDoneButton()
    }

    /// Drives the standalone Page Summaries toggle ON → OFF → ON, asserting the AI Controls Page
    /// Summaries toggle mirrors it. When off, the Summarize main-menu entry is absent.
    private func verifyStandalonePageSummariesMirrorsAIControls(blockAIEnhancementsFirst: Bool) {
        if blockAIEnhancementsFirst {
            openSettingsFromToolbarMenu()
            settingsScreen.openAIControlsSettings()
            aiControlsScreen.turnOnBlockAIEnhancements()
            aiControlsScreen.assertPageSummariesToggleIsOff()
            settingsScreen.tapBackToSettings()
            settingsScreen.closeSettingsWithDoneButton()
        }

        // Availability of the live summarize surface depends on runtime summarizer config (app-attest /
        // page content) a UI test cannot force, so the enabled state is verified via the toggles only.
        setStandalonePageSummariesAndAssertMirror(on: true)

        setStandalonePageSummariesAndAssertMirror(on: false)

        // When off, the Summarize main-menu entry is absent; continue into Settings from the same open
        // menu rather than dismissing and reopening (an in-flight dismiss swallows the reopen tap).
        toolBarScreen.tapSettingsMenuButton()
        mainMenuScreen.assertSummarizePageItemDoesNotExist()
        setStandalonePageSummariesAndAssertMirror(on: true, fromOpenMenu: true)
    }

    /// Sets the standalone Page Summaries toggle, then reopens AI Controls to assert it reflects the state.
    private func setStandalonePageSummariesAndAssertMirror(on: Bool, fromOpenMenu: Bool = false) {
        if fromOpenMenu {
            mainMenuScreen.tapSettings()
        } else {
            openSettingsFromToolbarMenu()
        }
        settingsScreen.openSummarizeSettings()
        summarizeSettingScreen.setSummarizeSwitch(on: on)
        settingsScreen.tapBackToSettings()

        settingsScreen.openAIControlsSettings()
        if on {
            aiControlsScreen.assertPageSummariesToggleIsOn()
        } else {
            aiControlsScreen.assertPageSummariesToggleIsOff()
        }
        settingsScreen.tapBackToSettings()
        settingsScreen.closeSettingsWithDoneButton()
    }

    /// Asserts Translation and Page Summaries are unavailable across every surface reachable in a UI
    /// test: the address bar, the main menu, and their standalone settings screens.
    private func assertAIFeaturesAreNotAvailable() {
        // Address bar: no translate button on the loaded page
        toolBarScreen.assertTranslateButtonDoesNotExist(with: .inactive)

        // Main menu: no Translate or Summarize entry
        toolBarScreen.tapSettingsMenuButton()
        mainMenuScreen.assertTranslatePageItemDoesNotExist()
        mainMenuScreen.assertSummarizePageItemDoesNotExist()

        // Standalone settings screens: both feature toggles read off
        mainMenuScreen.tapSettings()
        settingsScreen.openTranslationSettings()
        translationSettingScreen.assertTranslationSwitchIsOff()
        settingsScreen.tapBackToSettings()
        settingsScreen.openSummarizeSettings()
        summarizeSettingScreen.assertSummarizeToggleIsOff()
        settingsScreen.tapBackToSettings()
        settingsScreen.closeSettingsWithDoneButton()
    }

    private func openSettingsFromToolbarMenu() {
        toolBarScreen.tapSettingsMenuButton()
        mainMenuScreen.tapSettings()
    }

    private func navigateToTranslationTestPage() {
        loadTestPage("test-translation.html")
    }

    private func navigateToBookOfMozillaPage() {
        loadTestPage("test-mozilla-book.html")
    }

    private func loadTestPage(_ page: String) {
        browserScreen.tapOnAddressBar()
        browserScreen.typeOnSearchBar(text: path(forTestPage: page))
        browserScreen.typeOnSearchBar(text: "\r")
        waitUntilPageLoad()
    }
}
