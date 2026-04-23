// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Common

class AIControlsModel: ObservableObject,
                       LegacyFeatureFlaggable, // TODO: ROUX remove with 15192
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

    struct LinkInfo {
        let label: String
        let url: URL?
    }

    init(
        prefs: Prefs,
        windowUUID: WindowUUID,
        translationConfiguration: TranslationConfiguration? = nil,
        summarizerConfiguration: SummarizerNimbusUtils = DefaultSummarizerNimbusUtils()
    ) {
        self.prefs = prefs
        self.windowUUID = windowUUID
        self.translationConfiguration = translationConfiguration ?? TranslationConfiguration(prefs: prefs)
        self.summarizerConfiguration = summarizerConfiguration

        translationEnabled = self.translationConfiguration.isTranslationFeatureEnabled
        pageSummariesEnabled = self.summarizerConfiguration.isSummarizeFeatureToggledOn

        pageSummariesVisible = self.summarizerConfiguration.isSummarizeFeatureEnabled
        translationsVisible = featureFlags.isFeatureEnabled(.translation, checking: .buildOnly)

        killSwitchIsOn = featureFlagsProvider.isEnabled(.aiKillSwitch) && userPreferences.isAIKillSwitchEnabled
    }

    @MainActor
    func toggleKillSwitch(to newValue: Bool) {
        prefs.setBool(newValue, forKey: PrefsKeys.Settings.aiKillSwitchFeature)
        pageSummariesEnabled = !newValue
        translationEnabled = !newValue
    }

    @MainActor
    func toggleTranslationsFeature(to newValue: Bool) {
        store.dispatch(TranslationSettingsViewAction(
            newSettingValue: newValue,
            windowUUID: windowUUID,
            actionType: TranslationSettingsViewActionType.toggleTranslationsEnabled
        ))
    }

    func togglePageSummariesFeature(to newValue: Bool) {
        prefs.setBool(newValue, forKey: PrefsKeys.Summarizer.summarizeContentFeature)
    }
}
