// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

class AIControlsModel: ObservableObject, FeatureFlaggable {
    @Published var killSwitchToggledOn = false
    @Published var killSwitchIsOn = false
    @Published var translationEnabled: Bool
    @Published var pageSummariesEnabled: Bool

    let headerLinkInfo = LinkInfo(
        label: .Settings.AIControls.HeaderCard.Link,
        url: URL(string: "https://www.mozilla.org/en-US/privacy/firefox-privacy-policy/")!
    )

    let blockAIEnhancementsLinkInfo = LinkInfo(
        label: .Settings.AIControls.BlockAIEnhancementsLink,
        url: URL(string: "https://www.mozilla.org/en-US/privacy/firefox-privacy-policy/")!
    )

    private let translationConfiguration: TranslationConfiguration
    private let summarizerConfiguration: DefaultSummarizerNimbusUtils
    private let prefs: Prefs

    struct LinkInfo {
        let label: String
        let url: URL
    }

    init(prefs: Prefs) {
        self.prefs = prefs
        translationConfiguration = TranslationConfiguration(prefs: prefs)
        summarizerConfiguration = DefaultSummarizerNimbusUtils()
        translationEnabled = translationConfiguration.isTranslationFeatureEnabled
        pageSummariesEnabled = summarizerConfiguration.isSummarizeFeatureEnabled
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
            killSwitchToggledOn = true
            pageSummariesEnabled = false
            translationEnabled = false
            prefs.setBool(false, forKey: PrefsKeys.Settings.translationsFeature)
            prefs.setBool(false, forKey: PrefsKeys.Summarizer.summarizeContentFeature)
        }
    }
}
