// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared

/// Tiny utility to simplify checking for availability of the summarizers
struct SummarizerNimbusUtils: FeatureFlaggable {
    let prefs: Prefs
    static let shared = SummarizerNimbusUtils()

    /// Takes into consideration if summarizer is available and user setting for summarizing content is on.
    var isSummarizeFeatureToggledOn: Bool {
        return isSummarizeFeatureEnabled && didUserEnableSummarizeFeature()
    }

    var isSummarizeFeatureEnabled: Bool {
        return isAppleSummarizerEnabled() || isHostedSummarizerEnabled()
    }

    init(profile: Profile = AppContainer.shared.resolve()) {
        self.prefs = profile.prefs
    }

    /// Retrieves user preference for enabling the summarize content feature from settings
    private func didUserEnableSummarizeFeature() -> Bool {
        return prefs.boolForKey(PrefsKeys.Summarizer.summarizeContentFeature) ?? true
    }

    func isAppleSummarizerEnabled() -> Bool {
        #if canImport(FoundationModels)
            let isFlagEnabled = featureFlags.isFeatureEnabled(.appleSummarizer, checking: .buildOnly)
            return AppleIntelligenceUtil().isAppleIntelligenceAvailable && isFlagEnabled
        #else
            return false
        #endif
    }

    private func isHostedSummarizerEnabled() -> Bool {
        return featureFlags.isFeatureEnabled(.hostedSummarizer, checking: .buildOnly)
    }

    func isAppleSummarizerToolbarEndpointEnabled() -> Bool {
        let isFlagEnabled = featureFlags.isFeatureEnabled(.appleSummarizerToolbarEntrypoint, checking: .buildOnly)
        return isAppleSummarizerEnabled() && isFlagEnabled
    }

    func isHostedSummarizerToolbarEndpointEnabled() -> Bool {
        let isFlagEnabled = featureFlags.isFeatureEnabled(.hostedSummarizerToolbarEntrypoint, checking: .buildOnly)
        return isHostedSummarizerEnabled() && isFlagEnabled
    }
}
