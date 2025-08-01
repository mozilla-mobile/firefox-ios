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
        return isSummarizeFeatureEnabled && didUserEnableSummarizeFeature
    }

    var isSummarizeFeatureEnabled: Bool {
        return isAppleSummarizerEnabled() || isHostedSummarizerEnabled()
    }

    /// Takes into consideration that summarize feature is on,
    /// shake feature flag is enabled, and user setting for shake is enabled
    var isShakeEnabled: Bool {
        let summarizeFeatureOn = isSummarizeFeatureToggledOn
        let isShakeFlagEnabled = isShakeGestureFeatureFlagEnabled()
        let userSettingEnabled = didUserEnableShakeGestureFeature
        return summarizeFeatureOn && isShakeFlagEnabled && userSettingEnabled
    }

    init(profile: Profile = AppContainer.shared.resolve()) {
        self.prefs = profile.prefs
    }

    /// Retrieves user preference for enabling the summarize content feature from settings
    private var didUserEnableSummarizeFeature: Bool {
        return prefs.boolForKey(PrefsKeys.Summarizer.summarizeContentFeature) ?? true
    }

    /// Retrieves user preference for enabling shake gesture feature from settings
    private var didUserEnableShakeGestureFeature: Bool {
        return prefs.boolForKey(PrefsKeys.Summarizer.shakeGestureEnabled) ?? true
    }

    func isAppleSummarizerEnabled() -> Bool {
        #if canImport(FoundationModels)
            let isFlagEnabled = featureFlags.isFeatureEnabled(.appleSummarizer, checking: .buildOnly)
            return AppleIntelligenceUtil().isAppleIntelligenceAvailable && isFlagEnabled
        #else
            return false
        #endif
    }

    func isHostedSummarizerEnabled() -> Bool {
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

    private func isAppleSummarizerShakeGestureEnabled() -> Bool {
        let isShakeEnabled = featureFlags.isFeatureEnabled(.appleSummarizerShakeGesture, checking: .buildOnly)
        return isAppleSummarizerEnabled() && isShakeEnabled
    }

    private func isHostedSummarizerShakeGestureEnabled() -> Bool {
        let isShakeEnabled = featureFlags.isFeatureEnabled(.hostedSummarizerShakeGesture, checking: .buildOnly)
        return isHostedSummarizerEnabled() && isShakeEnabled
    }

    func isShakeGestureFeatureFlagEnabled() -> Bool {
        return isAppleSummarizerShakeGestureEnabled() || isHostedSummarizerShakeGestureEnabled()
    }
}
