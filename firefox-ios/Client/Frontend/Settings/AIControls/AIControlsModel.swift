// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Common

class AIControlsModel: ObservableObject, LegacyFeatureFlaggable {
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
        translationConfiguration: TranslationConfiguration? = nil,
        summarizerConfiguration: SummarizerNimbusUtils = DefaultSummarizerNimbusUtils()
    ) {
        self.prefs = prefs
        self.translationConfiguration = translationConfiguration ?? TranslationConfiguration(prefs: prefs)
        self.summarizerConfiguration = summarizerConfiguration

        translationEnabled = self.translationConfiguration.isTranslationFeatureEnabled
        pageSummariesEnabled = self.summarizerConfiguration.isSummarizeFeatureToggledOn

        pageSummariesVisible = self.summarizerConfiguration.isSummarizeFeatureEnabled
        translationsVisible = featureFlags.isFeatureEnabled(.translation, checking: .buildOnly)

        killSwitchIsOn = featureFlags.isFeatureEnabled(.aiKillSwitch, checking: .buildAndUser)
    }

    func toggleKillSwitch(to newValue: Bool) {
        prefs.setBool(newValue, forKey: PrefsKeys.Settings.aiKillSwitchFeature)
        switch newValue {
        case false:
            pageSummariesEnabled = true
            translationEnabled = true
            prefs.setBool(true, forKey: PrefsKeys.Settings.translationsFeature)
            prefs.setBool(true, forKey: PrefsKeys.Summarizer.summarizeContentFeature)
        case true:
            pageSummariesEnabled = false
            translationEnabled = false
            prefs.setBool(false, forKey: PrefsKeys.Settings.translationsFeature)
            prefs.setBool(false, forKey: PrefsKeys.Summarizer.summarizeContentFeature)
        }
    }

    func toggleTranslationsFeature(to newValue: Bool) {
        prefs.setBool(newValue, forKey: PrefsKeys.Settings.translationsFeature)
    }

    func togglePageSummariesFeature(to newValue: Bool) {
        prefs.setBool(newValue, forKey: PrefsKeys.Summarizer.summarizeContentFeature)
    }
}
