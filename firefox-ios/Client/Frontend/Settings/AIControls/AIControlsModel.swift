// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Common

class AIControlsModel: ObservableObject,
                       FeatureFlaggable,
                       UserFeaturePreferenceProvider {
    let windowUUID: WindowUUID
    @Published var killSwitchIsOn = false
    @Published var translationEnabled: Bool
    @Published var pageSummariesEnabled: Bool
    @Published var translationsVisible = false
    @Published var pageSummariesVisible: Bool

    let headerLinkInfo = LinkInfo(
        label: .Settings.AIControls.HeaderCard.Link,
        url: SupportUtils.URLForTopic(AIControlsModel.topicString, useMobilePath: true)
    )

    let blockAIEnhancementsLinkInfo = LinkInfo(
        label: .Settings.AIControls.BlockAIEnhancementsLink,
        url: SupportUtils.URLForTopic(AIControlsModel.topicString, useMobilePath: true)
    )

    let headerCardTitle: String = {
        String(
            format: .Settings.AIControls.HeaderCard.Title,
            AppName.shortName.rawValue
        )
    }()

    let blockedStatusDescription = {
        try? AttributedString(
            markdown: .Settings.AIControls.AIPoweredFeaturesSection.BlockedStatusDescription
        )
    }()

    let availableStatusDescription = {
        try? AttributedString(
            markdown: .Settings.AIControls.AIPoweredFeaturesSection.AvailableStatusDescription
        )
    }()

    let blockAIEnhancementsDescription: String = {
        String(
            format: .Settings.AIControls.BlockAIEnhancementsDescription,
            AppName.shortName.rawValue
        )
    }()

    var hasVisibleAIFeatures: Bool {
        return translationsVisible || pageSummariesVisible
    }

    private static let topicString = "ios-ai-controls"
    private let translationConfiguration: TranslationConfiguration
    private let summarizerConfiguration: SummarizerNimbusUtils
    private let prefs: Prefs
    private let settingsTelemetry: SettingsTelemetry
    private let logger: Logger

    struct LinkInfo {
        let label: String
        let url: URL?
    }

    init(
        prefs: Prefs,
        windowUUID: WindowUUID,
        translationConfiguration: TranslationConfiguration? = nil,
        summarizerConfiguration: SummarizerNimbusUtils = DefaultSummarizerNimbusUtils(),
        settingsTelemetry: SettingsTelemetry = SettingsTelemetry(),
        logger: Logger = DefaultLogger.shared
    ) {
        self.prefs = prefs
        self.windowUUID = windowUUID
        self.translationConfiguration = translationConfiguration ?? TranslationConfiguration(prefs: prefs)
        self.summarizerConfiguration = summarizerConfiguration
        self.settingsTelemetry = settingsTelemetry
        self.logger = logger

        translationEnabled = self.translationConfiguration.isTranslationFeatureEnabled
        pageSummariesEnabled = self.summarizerConfiguration.isSummarizeFeatureToggledOn

        pageSummariesVisible = self.summarizerConfiguration.isSummarizeFeatureEnabled
        translationsVisible = featureFlagsProvider.isEnabled(.translation)

        killSwitchIsOn = featureFlagsProvider.isEnabled(.aiKillSwitch) && userPreferences.getPreferenceFor(.aiKillSwitch)
    }

    @MainActor
    func toggleKillSwitch(to newValue: Bool) {
        guard killSwitchIsOn != newValue else {
            logger.log(
                "Not toggling AI control, toggle value is unchanged",
                level: .warning,
                category: .settings
            )
            return
        }

        killSwitchIsOn = newValue
        prefs.setBool(newValue, forKey: PrefsKeys.Settings.aiKillSwitchFeature)
        updatePageSummariesFeature(to: !newValue)
        updateTranslationsFeature(to: !newValue)
        settingsTelemetry.changedSetting(
            PrefsKeys.Settings.aiKillSwitchFeature,
            to: String(newValue),
            from: String(!newValue)
        )
    }

    @MainActor
    func toggleTranslationsFeature(to newValue: Bool) {
        updateTranslationsFeature(to: newValue)
        settingsTelemetry.changedSetting(
            PrefsKeys.Settings.translationsFeature,
            to: String(newValue),
            from: String(!newValue)
        )
    }

    @MainActor
    func togglePageSummariesFeature(to newValue: Bool) {
        updatePageSummariesFeature(to: newValue)
        settingsTelemetry.changedSetting(
            PrefsKeys.Summarizer.summarizeContentFeature,
            to: String(newValue),
            from: String(!newValue)
        )
    }

    @MainActor
    private func updateTranslationsFeature(to newValue: Bool) {
        guard translationEnabled != newValue else {
            logger.log(
                "Not toggling translations feature control, toggle value is unchanged",
                level: .warning,
                category: .settings
            )
            return
        }

        translationEnabled = newValue
        store.dispatch(TranslationSettingsViewAction(
            newSettingValue: newValue,
            toggledViaAIControls: true,
            windowUUID: windowUUID,
            actionType: TranslationSettingsViewActionType.toggleTranslationsEnabled
        ))
    }

    @MainActor
    private func updatePageSummariesFeature(to newValue: Bool) {
        guard pageSummariesEnabled != newValue else {
            logger.log(
                "Not toggling page summaries feature control, toggle value is unchanged",
                level: .warning,
                category: .settings
            )
            return
        }

        pageSummariesEnabled = newValue
        prefs.setBool(newValue, forKey: PrefsKeys.Summarizer.summarizeContentFeature)
    }
}
