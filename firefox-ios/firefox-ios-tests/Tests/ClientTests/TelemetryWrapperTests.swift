// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Common
import Glean
import XCTest

class TelemetryWrapperTests: XCTestCase {
    typealias ExtraKey = TelemetryWrapper.EventExtraKey
    typealias ValueKey = TelemetryWrapper.EventValue

    var profile: Profile!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        profile = MockProfile()
        Experiments.events.clearEvents()
        Self.setupTelemetry(with: profile)
    }

    override func tearDown() {
        Self.tearDownTelemetry()
        Experiments.events.clearEvents()
        profile = nil
        super.tearDown()
    }

    // MARK: - Bookmarks

    func test_hasMobileBookmarks_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .view,
                                     object: .mobileBookmarks,
                                     value: .doesHaveMobileBookmarks)

        testBoolMetricSuccess(metric: GleanMetrics.Bookmarks.hasMobileBookmarks,
                              expectedValue: true,
                              failureMessage: "Should have been set to true.")
    }

    func test_doesNotHaveMobileBookmarks_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .view,
                                     object: .mobileBookmarks,
                                     value: .doesNotHaveMobileBookmarks)

        testBoolMetricSuccess(metric: GleanMetrics.Bookmarks.hasMobileBookmarks,
                              expectedValue: false,
                              failureMessage: "Should have been set to false.")
    }

    func test_mobileBookmarksQuantity_GleanIsCalled() {
        let quantityKey = TelemetryWrapper.EventExtraKey.mobileBookmarksQuantity.rawValue
        let expectedQuantity: Int64 = 13
        let extras = [quantityKey: expectedQuantity]

        TelemetryWrapper.recordEvent(category: .information,
                                     method: .view,
                                     object: .mobileBookmarks,
                                     value: .mobileBookmarksCount,
                                     extras: extras)

        testQuantityMetricSuccess(metric: GleanMetrics.Bookmarks.mobileBookmarksCount,
                                  expectedValue: 13,
                                  failureMessage: "Incorrect mobile bookmarks quantity returned.")
    }

    // MARK: - Sponsored shortcuts

    func test_sponsoredShortcuts_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .information,
            method: .view,
            object: .sponsoredShortcuts,
            value: nil,
            extras: ["pref": true]
        )
        testBoolMetricSuccess(metric: GleanMetrics.TopSites.sponsoredShortcuts,
                              expectedValue: true,
                              failureMessage: "Sponsored shortcut value not tracked")
    }

    // MARK: - CFR Analytics

    func test_contextualHintDismissButtonWithoutExtras_GleanIsNotCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .contextualHint,
            value: .dismissCFRFromButton
        )
        XCTAssertNil(GleanMetrics.CfrAnalytics.dismissCfrFromButton.testGetValue())
    }

    func test_contextualHintDismissOutsideTapWithoutExtras_GleanIsNotCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .contextualHint,
            value: .dismissCFRFromOutsideTap
        )
        XCTAssertNil(GleanMetrics.CfrAnalytics.dismissCfrFromOutsideTap.testGetValue())
    }

    func test_contextualHintPressActionWithoutExtras_GleanIsNotCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .contextualHint,
            value: .pressCFRActionButton
        )
        XCTAssertNil(GleanMetrics.CfrAnalytics.pressCfrActionButton.testGetValue())
    }

    // MARK: - Onboarding

    // MARK: Wallpapers

    @MainActor
    func test_backgroundWallpaperMetric_defaultBackgroundIsNotSent() {
        TelemetryWrapper.shared.setup(profile: profile)
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)

        let defaultWallpaper = Wallpaper(id: "fxDefault",
                                         textColor: nil,
                                         cardColor: nil,
                                         logoTextColor: nil)

        WallpaperManager().setCurrentWallpaper(to: defaultWallpaper) { _ in }
        XCTAssertEqual(WallpaperManager().currentWallpaper.type, .none)

        TelemetryWrapper.shared.recordEnteredBackgroundPreferenceMetrics()

        testLabeledMetricSuccess(metric: GleanMetrics.WallpaperAnalytics.themedWallpaper)
        let wallpaperName = WallpaperManager().currentWallpaper.id.lowercased()
        XCTAssertNil(GleanMetrics.WallpaperAnalytics.themedWallpaper[wallpaperName].testGetValue())
    }

    @MainActor
    func test_backgroundWallpaperMetric_themedWallpaperIsSent() {
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        TelemetryWrapper.shared.setup(profile: profile)

        let themedWallpaper = Wallpaper(id: "amethyst",
                                        textColor: nil,
                                        cardColor: nil,
                                        logoTextColor: nil)

        WallpaperManager().setCurrentWallpaper(to: themedWallpaper) { _ in }
        XCTAssertEqual(WallpaperManager().currentWallpaper.type, .other)

        TelemetryWrapper.shared.recordEnteredBackgroundPreferenceMetrics()

        testLabeledMetricSuccess(metric: GleanMetrics.WallpaperAnalytics.themedWallpaper)
        let wallpaperName = WallpaperManager().currentWallpaper.id.lowercased()
        XCTAssertEqual(GleanMetrics.WallpaperAnalytics.themedWallpaper[wallpaperName].testGetValue(), 1)
    }

    // MARK: - Awesomebar result tap
    func test_AwesomebarImpressions_GleanIsCalled() throws {
        let groupsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.groups.rawValue
        let groups = SearchTelemetryValues.Groups.adaptiveHistory.rawValue

        let interactionKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.interaction.rawValue
        let interaction = SearchTelemetryValues.Interaction.persistedSearchTerms.rawValue

        let nCharsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.nChars.rawValue
        let nChars: Int32 = 5

        let nResultsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.nResults.rawValue
        let nResults: Int32 = 12

        let nWordsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.nWords.rawValue
        let nWords: Int32 = 1

        let reasonKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.reason.rawValue
        let reason = SearchTelemetryValues.Reason.pause.rawValue

        let resultsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.results.rawValue
        let results = SearchTelemetryValues.Results.searchEngine.rawValue + ","
                      + SearchTelemetryValues.Results.tabToSearch.rawValue

        let sapKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.sap.rawValue
        let sap = SearchTelemetryValues.Sap.urlbar.rawValue

        let searchModeKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.searchMode.rawValue
        let searchMode = SearchTelemetryValues.SearchMode.bookmarks.rawValue

        let extraDetails = [
            groupsKey: groups,
            interactionKey: interaction,
            nCharsKey: nChars,
            nResultsKey: nResults,
            nWordsKey: nWords,
            reasonKey: reason,
            resultsKey: results,
            sapKey: sap,
            searchModeKey: searchMode
        ] as [String: Any]

        TelemetryWrapper.recordEvent(category: .information,
                                     method: .view,
                                     object: .urlbarImpression,
                                     extras: extraDetails)

        try testEventMetricRecordingSuccess(metric: GleanMetrics.Urlbar.impression)
    }

    func test_AwesomebarEngagement_GleanIsCalled() throws {
        let sapKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.sap.rawValue
        let sap = SearchTelemetryValues.Sap.urlbar.rawValue

        let interactionKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.interaction.rawValue
        let interaction = SearchTelemetryValues.Interaction.persistedSearchTerms.rawValue

        let searchModeKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.searchMode.rawValue
        let searchMode = SearchTelemetryValues.SearchMode.tabs.rawValue

        let nCharsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.nChars.rawValue
        let nChars: Int32 = 5

        let nResultsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.nResults.rawValue
        let nResults: Int32 = 12

        let nWordsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.nWords.rawValue
        let nWords: Int32 = 1

        let selectedResultKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.selectedResult.rawValue
        let selectedResult = SearchTelemetryValues.SelectedResult.topSite.rawValue

        let selectedResultSubtypeKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.selectedResultSubtype.rawValue
        let selectedResultSubtype = "unknown"

        let providerKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.provider.rawValue
        let provider = SearchEngine.none.rawValue

        let engagementTypeKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.engagementType.rawValue
        let engagementType = SearchTelemetryValues.EngagementType.help.rawValue

        let groupsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.groups.rawValue
        let groups = SearchTelemetryValues.Groups.adaptiveHistory.rawValue

        let resultsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.results.rawValue
        let results = SearchTelemetryValues.Results.searchEngine.rawValue + ","
        + SearchTelemetryValues.Results.tabToSearch.rawValue

        let extraDetails = [
            sapKey: sap,
            interactionKey: interaction,
            searchModeKey: searchMode,
            nCharsKey: nChars,
            nWordsKey: nWords,
            nResultsKey: nResults,
            selectedResultKey: selectedResult,
            selectedResultSubtypeKey: selectedResultSubtype,
            providerKey: provider,
            engagementTypeKey: engagementType,
            groupsKey: groups,
            resultsKey: results]
        as [String: Any]

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .urlbarEngagement,
                                     extras: extraDetails)

        try testEventMetricRecordingSuccess(metric: GleanMetrics.Urlbar.engagement)
    }

  func test_AwesomebarAbandonment_GleanIsCalled() throws {
        let groupsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.groups.rawValue
        let groups = SearchTelemetryValues.Groups.adaptiveHistory.rawValue

        let interactionKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.interaction.rawValue
        let interaction = SearchTelemetryValues.Interaction.persistedSearchTerms.rawValue

        let nCharsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.nChars.rawValue
        let nChars: Int32 = 5

        let nResultsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.nResults.rawValue
        let nResults: Int32 = 12

        let nWordsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.nWords.rawValue
        let nWords: Int32 = 1

        let resultsKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.results.rawValue
        let results = SearchTelemetryValues.Results.searchEngine.rawValue + ","
        + SearchTelemetryValues.Results.tabToSearch.rawValue

        let sapKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.sap.rawValue
        let sap = SearchTelemetryValues.Sap.urlbar.rawValue

        let searchModeKey = TelemetryWrapper.EventExtraKey.UrlbarTelemetry.searchMode.rawValue
        let searchMode = SearchTelemetryValues.SearchMode.bookmarks.rawValue

        let extraDetails = [
            groupsKey: groups,
            interactionKey: interaction,
            nCharsKey: nChars,
            nResultsKey: nResults,
            nWordsKey: nWords,
            resultsKey: results,
            sapKey: sap,
            searchModeKey: searchMode
        ] as [String: Any]

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .close,
                                     object: .urlbarAbandonment,
                                     extras: extraDetails)

        try testEventMetricRecordingSuccess(metric: GleanMetrics.Urlbar.abandonment)
    }

    // MARK: - Page Action Menu

    func test_createNewTab_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .createNewTab
        )

        testCounterMetricRecordingSuccess(metric: GleanMetrics.PageActionMenu.createNewTab)
    }

    // MARK: - History

    func test_HistoryPanelOpened_GleanIsCalled() throws {
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .view,
                                     object: .historyPanelOpened)

        try testEventMetricRecordingSuccess(metric: GleanMetrics.History.opened)
    }

    func test_openedHistoryItem_GleanIsCalled() throws {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .openedHistoryItem)

        try testEventMetricRecordingSuccess(metric: GleanMetrics.History.openedItem)
    }

    func test_singleHistoryItemRemoved_GleanIsCalled() throws {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .swipe,
                                     object: .historySingleItemRemoved)

        try testEventMetricRecordingSuccess(metric: GleanMetrics.History.removed)
    }

    func test_viewHistoryPanel_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .viewHistoryPanel
        )

        testCounterMetricRecordingSuccess(metric: GleanMetrics.PageActionMenu.viewHistoryPanel)
    }

    func test_viewDownloadsPanel_GleanIsCalled() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .viewDownloadsPanel
        )

        testCounterMetricRecordingSuccess(metric: GleanMetrics.PageActionMenu.viewDownloadsPanel)
    }

    // Accessibility

    func test_accessibilityVoiceOver_GleanIsCalled() throws {
        let isRunningKey = TelemetryWrapper.EventExtraKey.isVoiceOverRunning.rawValue
        let extras = [isRunningKey: "\(1)"]
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .voiceOver,
            object: .app,
            extras: extras
        )

        try testEventMetricRecordingSuccess(metric: GleanMetrics.Accessibility.voiceOver)
    }

    func test_accessibilitySwitchControl_GleanIsCalled() throws {
        let isRunningKey = TelemetryWrapper.EventExtraKey.isSwitchControlRunning.rawValue
        let extras = [isRunningKey: "\(1)"]
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .switchControl,
            object: .app,
            extras: extras
        )

        try testEventMetricRecordingSuccess(metric: GleanMetrics.Accessibility.switchControl)
    }

    func test_accessibilityReduceTransparency_GleanIsCalled() throws {
        let isRunningKey = TelemetryWrapper.EventExtraKey.isReduceTransparencyEnabled.rawValue
        let extras = [isRunningKey: "\(1)"]
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .reduceTransparency,
            object: .app,
            extras: extras
        )

        try testEventMetricRecordingSuccess(metric: GleanMetrics.Accessibility.reduceTransparency)
    }

    func test_accessibilityReduceMotionEnabled_GleanIsCalled() throws {
        let isRunningKey = TelemetryWrapper.EventExtraKey.isReduceMotionEnabled.rawValue
        let extras = [isRunningKey: "\(1)"]
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .reduceMotion,
            object: .app,
            extras: extras
        )

        try testEventMetricRecordingSuccess(metric: GleanMetrics.Accessibility.reduceMotion)
    }

    func test_accessibilityInvertColorsEnabled_GleanIsCalled() throws {
        let isRunningKey = TelemetryWrapper.EventExtraKey.isInvertColorsEnabled.rawValue
        let extras = [isRunningKey: "\(1)"]
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .invertColors,
            object: .app,
            extras: extras
        )

        try testEventMetricRecordingSuccess(metric: GleanMetrics.Accessibility.invertColors)
    }

    func test_accessibilityDynamicText_GleanIsCalled() throws {
        let isAccessibilitySizeEnabledKey = TelemetryWrapper.EventExtraKey.isAccessibilitySizeEnabled.rawValue
        let preferredContentSizeCategoryKey = TelemetryWrapper.EventExtraKey.preferredContentSizeCategory.rawValue
        let extras = [isAccessibilitySizeEnabledKey: "\(1)",
                    preferredContentSizeCategoryKey: "UICTContentSizeCategoryAccessibilityL"]
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .dynamicTextSize,
            object: .app,
            extras: extras
        )

        try testEventMetricRecordingSuccess(metric: GleanMetrics.Accessibility.dynamicText)
    }

    // MARK: - App Settings Menu

    func test_showTour_GleanIsCalled() throws {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .settingsMenuShowTour
        )

        try testEventMetricRecordingSuccess(metric: GleanMetrics.SettingsMenu.showTourPressed)
    }

    func test_signIntoSync_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .signIntoSync)

        testCounterMetricRecordingSuccess(metric: GleanMetrics.AppMenu.signIntoSync)
    }

    func test_settingsMenuSync_GleanIsCalled() throws {
        TelemetryWrapper.recordEvent(category: .action, method: .open, object: .settingsMenuPasswords)
        try testEventMetricRecordingSuccess(metric: GleanMetrics.SettingsMenu.passwords)
    }

    func test_appMenuLoginsAndPasswordsTapped_GleanIsCalled() throws {
        TelemetryWrapper.recordEvent(category: .action, method: .open, object: .logins)
        try testEventMetricRecordingSuccess(metric: GleanMetrics.AppMenu.passwords)
    }

    // MARK: Logins and Passwords
    func test_loginsAutofilled_GleanIsCalled() throws {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .loginsAutofilled)
        try testEventMetricRecordingSuccess(metric: GleanMetrics.Logins.autofilled)
    }

    func test_loginsAutofillFailed_GleanIsCalled() throws {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .loginsAutofillFailed)
        try testEventMetricRecordingSuccess(metric: GleanMetrics.Logins.autofillFailed)
    }

    func test_loginsManagementAddTapped_GleanIsCalled() throws {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .loginsManagementAddTapped)
        try testEventMetricRecordingSuccess(metric: GleanMetrics.Logins.managementAddTapped)
    }

    func test_loginsManagementLoginsTapped_GleanIsCalled() throws {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .loginsManagementLoginsTapped)
        try testEventMetricRecordingSuccess(metric: GleanMetrics.Logins.managementLoginsTapped)
    }

    func test_loginsModified_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .change,
                                     object: .loginsModified)

        testCounterMetricRecordingSuccess(metric: GleanMetrics.Logins.modified)
    }

    func test_loginsDeleted_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .delete,
                                     object: .loginsDeleted)

        testCounterMetricRecordingSuccess(metric: GleanMetrics.Logins.deleted)
    }

    func test_loginsSaved_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .add,
                                     object: .loginsSaved)

        testCounterMetricRecordingSuccess(metric: GleanMetrics.Logins.saved)
    }

    func test_loginsSyncEnabled_GleanIsCalled() throws {
        let isEnabledKey = TelemetryWrapper.EventExtraKey.isLoginSyncEnabled.rawValue
        let extras = [isEnabledKey: true]
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .loginsSyncEnabled,
                                     extras: extras)

        try testEventMetricRecordingSuccess(metric: GleanMetrics.Logins.syncEnabled)
    }

    func test_loginsSavedAll_GleanIsCalled() {
        let expectedLoginsCount: Int64 = 5
        let extra = [TelemetryWrapper.EventExtraKey.loginsQuantity.rawValue: expectedLoginsCount]
        TelemetryWrapper.recordEvent(
            category: .information,
            method: .foreground,
            object: .loginsSavedAll,
            value: nil,
            extras: extra
        )

        testQuantityMetricSuccess(
            metric: GleanMetrics.Logins.savedAll,
            expectedValue: expectedLoginsCount,
            failureMessage: "Should have \(expectedLoginsCount) logins"
        )
    }
    // MARK: - Sync

    func test_userLoggedOut_GleanIsCalled() throws {
        TelemetryWrapper.recordEvent(category: .firefoxAccount, method: .tap, object: .syncUserLoggedOut)

        try testEventMetricRecordingSuccess(metric: GleanMetrics.Sync.disconnect)
    }

    func test_loginWithQRCode_GleanIsCalled() throws {
        TelemetryWrapper.recordEvent(category: .firefoxAccount, method: .tap, object: .syncSignInScanQRCode)

        try testEventMetricRecordingSuccess(metric: GleanMetrics.Sync.paired)
    }

    func test_loginWithEmail_GleanIsCalled() throws {
        TelemetryWrapper.recordEvent(category: .firefoxAccount, method: .tap, object: .syncSignInUseEmail)

        try testEventMetricRecordingSuccess(metric: GleanMetrics.Sync.useEmail)
    }

    // MARK: - Address autofill

    func test_addressSavedAll_GleanIsCalledWithQuantity() {
        let expectedAddressesCount: Int64 = 5
        let extras: [String: Any] = [TelemetryWrapper.EventExtraKey.AddressTelemetry.count.rawValue: Int64(5)]
        TelemetryWrapper.recordEvent(
            category: .information,
            method: .foreground,
            object: .addressAutofillSettings,
            value: nil,
            extras: extras
        )

        testQuantityMetricSuccess(metric: GleanMetrics.Addresses.savedAll,
                                  expectedValue: expectedAddressesCount,
                                  failureMessage: "Should have \(expectedAddressesCount) addresses")
    }

    func test_addressSettingsAutofill_GleanIsCalled() throws {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .addressAutofillSettings
        )
        try testEventMetricRecordingSuccess(
            metric: GleanMetrics.Addresses.settingsAutofill
        )
    }

    func test_addressAutofillPromptShown_GleanIsCalled() throws {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .view,
            object: .addressAutofillPromptShown
        )
        try testEventMetricRecordingSuccess(
            metric: GleanMetrics.Addresses.autofillPromptShown
        )
    }

    func test_addressAutofillPromptExpanded_GleanIsCalled() throws {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .addressAutofillPromptExpanded
        )
        try testEventMetricRecordingSuccess(
            metric: GleanMetrics.Addresses.autofillPromptExpanded
        )
    }

    func test_addressAutofillPromptDismissed_GleanIsCalled() throws {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .close,
            object: .addressAutofillPromptDismissed
        )
        try testEventMetricRecordingSuccess(
            metric: GleanMetrics.Addresses.autofillPromptDismissed
        )
    }

    func test_addressFormFilledModified_GleanIsCalled() throws {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .change,
            object: .addressFormFilledModified
        )
        try testEventMetricRecordingSuccess(
            metric: GleanMetrics.Addresses.modified
        )
    }

    func test_addressFormAutofilled_GleanIsCalled() throws {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .detect,
            object: .addressFormFilled
        )
        try testEventMetricRecordingSuccess(
            metric: GleanMetrics.Addresses.autofilled
        )
    }

    func test_addressFormDetected_GleanIsCalled() throws {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .detect,
            object: .addressForm
        )
        try testEventMetricRecordingSuccess(
            metric: GleanMetrics.Addresses.formDetected
        )
    }

    // MARK: - Credit card autofill

    func test_autofill_credit_card_settings_tapped_GleanIsCalled() throws {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .creditCardAutofillSettings
        )

        try testEventMetricRecordingSuccess(metric: GleanMetrics.CreditCard.autofillSettingsTapped)
    }

    func test_creditCardAutofillPromptShown_GleanIsCalled() throws {
        TelemetryWrapper.recordEvent(category: .action, method: .view, object: .creditCardAutofillPromptShown)
        try testEventMetricRecordingSuccess(metric: GleanMetrics.CreditCard.autofillPromptShown)
    }

    func test_creditCardAutofillPromptExpanded_GleanIsCalled() throws {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .creditCardAutofillPromptExpanded)
        try testEventMetricRecordingSuccess(metric: GleanMetrics.CreditCard.autofillPromptExpanded)
    }

    func test_creditCardAutofillPromptDismissed_GleanIsCalled() throws {
        TelemetryWrapper.recordEvent(category: .action, method: .close, object: .creditCardAutofillPromptDismissed)
        try testEventMetricRecordingSuccess(metric: GleanMetrics.CreditCard.autofillPromptDismissed)
    }

    func test_creditCardSavePromptShown_GleanIsCalled() throws {
        TelemetryWrapper.recordEvent(category: .action, method: .view, object: .creditCardSavePromptShown)
        try testEventMetricRecordingSuccess(metric: GleanMetrics.CreditCard.savePromptShown)
    }

    func test_creditCardSavePromptUpdate_GleanIsCalled() throws {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .creditCardSavePromptUpdate)
        try testEventMetricRecordingSuccess(metric: GleanMetrics.CreditCard.savePromptUpdate)
    }

    func test_creditCardManagementAddTapped_GleanIsCalled() throws {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .creditCardManagementAddTapped)
        try testEventMetricRecordingSuccess(metric: GleanMetrics.CreditCard.managementAddTapped)
    }

    func test_creditCardManagementCardTapped_GleanIsCalled() throws {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .creditCardManagementCardTapped)
        try testEventMetricRecordingSuccess(metric: GleanMetrics.CreditCard.managementCardTapped)
    }

    func test_creditCardModified_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .change,
                                     object: .creditCardModified)

        testCounterMetricRecordingSuccess(metric: GleanMetrics.CreditCard.modified)
    }

    func test_creditCardDeleted_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .delete,
                                     object: .creditCardDeleted)

        testCounterMetricRecordingSuccess(metric: GleanMetrics.CreditCard.deleted)
    }

    func test_creditCardSaved_GleanIsCalled() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .add,
                                     object: .creditCardSaved)

        testCounterMetricRecordingSuccess(metric: GleanMetrics.CreditCard.saved)
    }

    func test_creditCardSavedAll_GleanIsCalled() {
        let expectedCreditCardsCount: Int64 = 5
        let extra = [TelemetryWrapper.EventExtraKey.creditCardsQuantity.rawValue: expectedCreditCardsCount]
        TelemetryWrapper.recordEvent(
            category: .information,
            method: .foreground,
            object: .creditCardSavedAll,
            value: nil,
            extras: extra
        )

        testQuantityMetricSuccess(metric: GleanMetrics.CreditCard.savedAll,
                                  expectedValue: expectedCreditCardsCount,
                                  failureMessage: "Should have \(expectedCreditCardsCount) credit cards")
    }

    // MARK: - Nimbus Calls

    func test_appForeground_NimbusIsCalled() throws {
        XCTAssertFalse(
            try Experiments.createJexlHelper()!.evalJexl(
                expression: "'app_cycle.foreground'|eventSum('Days', 1, 0) > 0"
            )
        )
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .foreground,
            object: .app,
            value: nil
        )
        Experiments.shared.waitForDbQueue()
        XCTAssertTrue(
            try Experiments.createJexlHelper()!.evalJexl(
                expression: "'app_cycle.foreground'|eventSum('Days', 1, 0) > 0"
            )
        )
    }

    func test_syncLogin_NimbusIsCalled() {
        XCTAssertFalse(
            try Experiments.createJexlHelper()!.evalJexl(
                expression: "'sync.login_completed_view'|eventSum('Days', 1, 0) > 0"
            )
        )
        TelemetryWrapper.recordEvent(
            category: .firefoxAccount,
            method: .view,
            object: .fxaLoginCompleteWebpage,
            value: nil
        )
        Experiments.shared.waitForDbQueue()
        XCTAssertTrue(
            try Experiments.createJexlHelper()!.evalJexl(
                expression: "'sync.login_completed_view'|eventSum('Days', 1, 0) > 0"
            )
        )
    }

    // MARK: - App Errors

    func test_error_largeFileWriteIsCalled() throws {
        let eventExtra = [TelemetryWrapper.EventExtraKey.size.rawValue: Int32(1000)]
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .error,
                                     object: .app,
                                     value: .largeFileWrite,
                                     extras: eventExtra)

        try testEventMetricRecordingSuccess(metric: GleanMetrics.AppErrors.largeFileWrite)
    }

    func test_error_crashedLastLaunchIsCalled() throws {
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .error,
                                     object: .app,
                                     value: .crashedLastLaunch)

        try testEventMetricRecordingSuccess(metric: GleanMetrics.AppErrors.crashedLastLaunch)
    }

    func test_error_cpuExceptionIsCalled() throws {
        let eventExtra = [TelemetryWrapper.EventExtraKey.size.rawValue: Int32(1000)]
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .error,
                                     object: .app,
                                     value: .cpuException,
                                     extras: eventExtra)

        try testEventMetricRecordingSuccess(metric: GleanMetrics.AppErrors.cpuException)
    }

    func test_error_hangExceptionIsCalled() throws {
        let eventExtra = [TelemetryWrapper.EventExtraKey.size.rawValue: Int32(1000)]
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .error,
                                     object: .app,
                                     value: .hangException,
                                     extras: eventExtra)

        try testEventMetricRecordingSuccess(metric: GleanMetrics.AppErrors.hangException)
    }

    func test_error_tabLossDetectedIsCalled() throws {
        TelemetryWrapper.recordEvent(category: .information,
                                     method: .error,
                                     object: .app,
                                     value: .tabLossDetected)

        try testEventMetricRecordingSuccess(metric: GleanMetrics.AppErrors.tabLossDetected)
    }

    // MARK: - RecordSearch
    func test_RecordSearch_GleanIsCalledSearchSuggestion() {
        let extras = [TelemetryWrapper.EventExtraKey.recordSearchLocation.rawValue: "suggestion",
                      TelemetryWrapper.EventExtraKey.recordSearchEngineID.rawValue: "default"] as [String: Any]
        TelemetryWrapper.gleanRecordEvent(category: .action,
                                          method: .tap,
                                          object: .recordSearch,
                                          extras: extras)
    }

    func test_RecordSearch_GleanIsCalledSearchQuickSearch() {
        let extras = [TelemetryWrapper.EventExtraKey.recordSearchLocation.rawValue: "quickSearch",
                      TelemetryWrapper.EventExtraKey.recordSearchEngineID.rawValue: "default"] as [String: Any]
        TelemetryWrapper.gleanRecordEvent(category: .action,
                                          method: .tap,
                                          object: .recordSearch,
                                          extras: extras)
    }

    // MARK: - Webview

    func testRecordWebviewWhenDidFailThenGleanIsCalled() throws {
        TelemetryWrapper.gleanRecordEvent(category: .information,
                                          method: .error,
                                          object: .webview,
                                          value: .webviewFail)
        try testEventMetricRecordingSuccess(metric: GleanMetrics.Webview.didFail)
    }

    func testRecordWebviewWhenDidFailProvisionalThenGleanIsCalled() throws {
        TelemetryWrapper.gleanRecordEvent(category: .information,
                                          method: .error,
                                          object: .webview,
                                          value: .webviewFailProvisional)
        try testEventMetricRecordingSuccess(metric: GleanMetrics.Webview.didFailProvisional)
    }

    func testRecordWebviewWhenDidShowErrorThenGleanIsCalled() throws {
        let extra = [TelemetryWrapper.EventExtraKey.errorCode.rawValue: "403"]
        TelemetryWrapper.gleanRecordEvent(category: .information,
                                          method: .error,
                                          object: .webview,
                                          value: .webviewShowErrorPage,
                                          extras: extra)
        try testEventMetricRecordingSuccess(metric: GleanMetrics.Webview.showErrorPage)
    }
}

// MARK: - Helper functions to test telemetry
extension XCTestCase {
    func testEventMetricRecordingSuccess<ExtraObject>(
        metric: EventMetricType<ExtraObject>,
        expectedCount: Int = 1,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws where ExtraObject: EventExtras {
        let resultValue = try XCTUnwrap(metric.testGetValue())
        XCTAssertNotNil(resultValue, "Should have value on event metric \(metric)", file: file, line: line)
        XCTAssertEqual(resultValue.count, expectedCount, file: file, line: line)

        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidLabel), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidOverflow), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidState), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidValue), 0, file: file, line: line)
    }

    func testCounterMetricRecordingSuccess(metric: CounterMetricType,
                                           value: Int32 = 1,
                                           file: StaticString = #filePath,
                                           line: UInt = #line) {
        XCTAssertNotNil(metric.testGetValue(), "Should have value on counter metric \(metric)", file: file, line: line)
        XCTAssertEqual(metric.testGetValue(), value, file: file, line: line)

        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidLabel), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidOverflow), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidState), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidValue), 0, file: file, line: line)
    }

    func testLabeledMetricSuccess(metric: LabeledMetricType<CounterMetricType>,
                                  file: StaticString = #filePath,
                                  line: UInt = #line) {
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidLabel), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidOverflow), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidState), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidValue), 0, file: file, line: line)
    }

    func testQuantityMetricSuccess(metric: QuantityMetricType,
                                   expectedValue: Int64,
                                   failureMessage: String,
                                   file: StaticString = #filePath,
                                   line: UInt = #line) {
        XCTAssertNotNil(metric.testGetValue(), "Should have value on quantity metric \(metric)", file: file, line: line)
        XCTAssertEqual(metric.testGetValue(), expectedValue, failureMessage, file: file, line: line)

        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidLabel), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidOverflow), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidState), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidValue), 0, file: file, line: line)
    }

    func testStringMetricSuccess(metric: StringMetricType,
                                 expectedValue: String,
                                 failureMessage: String,
                                 file: StaticString = #filePath,
                                 line: UInt = #line) {
        XCTAssertNotNil(metric.testGetValue(), "Should have value on string metric \(metric)", file: file, line: line)
        XCTAssertEqual(metric.testGetValue(), expectedValue, failureMessage, file: file, line: line)

        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidLabel), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidOverflow), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidState), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidValue), 0, file: file, line: line)
    }

    func testUrlMetricSuccess(metric: UrlMetricType,
                              expectedValue: String,
                              failureMessage: String,
                              file: StaticString = #filePath,
                              line: UInt = #line) {
        XCTAssertNotNil(metric.testGetValue(), "Should have value on url metric \(metric)", file: file, line: line)
        XCTAssertEqual(metric.testGetValue(), expectedValue, failureMessage, file: file, line: line)

        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidLabel), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidOverflow), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidState), 0, file: file, line: line)
        XCTAssertEqual(metric.testGetNumRecordedErrors(ErrorType.invalidValue), 0, file: file, line: line)
    }

    func testUuidMetricSuccess(metric: UuidMetricType,
                               expectedValue: UUID,
                               failureMessage: String,
                               file: StaticString = #filePath,
                               line: UInt = #line) {
        XCTAssertNotNil(metric.testGetValue(), "Should have value on uuid metric \(metric)", file: file, line: line)
        XCTAssertEqual(metric.testGetValue(), expectedValue, failureMessage, file: file, line: line)
    }

    func testBoolMetricSuccess(metric: BooleanMetricType,
                               expectedValue: Bool,
                               failureMessage: String,
                               file: StaticString = #filePath,
                               line: UInt = #line) {
        XCTAssertNotNil(metric.testGetValue(), "Should have value on bool metric \(metric)", file: file, line: line)
        XCTAssertEqual(metric.testGetValue(), expectedValue, failureMessage, file: file, line: line)
    }
}
