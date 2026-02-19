// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared

protocol SummarizerNimbusUtils {
    /// Determines if the Summarize feature should be shown,
    /// based on both feature availability and the user's settings.
    var isSummarizeFeatureToggledOn: Bool { get }
    /// Determines whether the Summarize feature is available,
    /// regardless of the user's settings.
    /// (i.e. we want to show the settings toggle to enable or disable summarize with this flag)
    var isSummarizeFeatureEnabled: Bool { get }
    var isShakeGestureEnabled: Bool { get }
    var isToolbarButtonEnabled: Bool { get }

    func isAppleSummarizerEnabled() -> Bool
    func isHostedSummarizerEnabled() -> Bool
    func isAppAttestAuthEnabled() -> Bool
    func isShakeGestureFeatureFlagEnabled() -> Bool
}

/// Tiny utility to simplify checking for availability of the summarizers
struct DefaultSummarizerNimbusUtils: FeatureFlaggable, SummarizerNimbusUtils {
    let prefs: Prefs

    var isSummarizeFeatureToggledOn: Bool {
        return isSummarizeFeatureEnabled && didUserEnableSummarizeFeature
    }

    var isSummarizeFeatureEnabled: Bool {
        return isAppleSummarizerEnabled() || isHostedSummarizerEnabled()
    }

    var isToolbarButtonEnabled: Bool {
        let summarizeFeatureOn = isSummarizeFeatureToggledOn
        let isToolbarFeatureEnabled = isHostedSummarizerToolbarEndpointEnabled() || isAppleSummarizerToolbarEndpointEnabled()
        return summarizeFeatureOn && isToolbarFeatureEnabled
    }

    /// Takes into consideration that summarize feature is on,
    /// shake feature flag is enabled, and user setting for shake is enabled
    var isShakeGestureEnabled: Bool {
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
            let isEngLang = NSLocale.current.languageCode == "en"
            return isEngLang && AppleIntelligenceUtil().isAppleIntelligenceAvailable
        #else
            return false
        #endif
    }

    func isHostedSummarizerEnabled() -> Bool {
        return featureFlags.isFeatureEnabled(.hostedSummarizer, checking: .buildOnly)
    }

    private func isAppleSummarizerToolbarEndpointEnabled() -> Bool {
        let isEngLang = NSLocale.current.languageCode == "en"
        return isEngLang && isAppleSummarizerEnabled()
    }

    private func isHostedSummarizerToolbarEndpointEnabled() -> Bool {
        let isFlagEnabled = featureFlags.isFeatureEnabled(.hostedSummarizerToolbarEntrypoint, checking: .buildOnly)
        return isHostedSummarizerEnabled() && isFlagEnabled
    }

    private func isAppleSummarizerShakeGestureEnabled() -> Bool {
        let isEngLang = NSLocale.current.languageCode == "en"
        return isEngLang && isAppleSummarizerEnabled()
    }

    private func isHostedSummarizerShakeGestureEnabled() -> Bool {
        let isShakeEnabled = featureFlags.isFeatureEnabled(.hostedSummarizerShakeGesture, checking: .buildOnly)
        return isHostedSummarizerEnabled() && isShakeEnabled
    }

    func isShakeGestureFeatureFlagEnabled() -> Bool {
        return isAppleSummarizerShakeGestureEnabled() || isHostedSummarizerShakeGestureEnabled()
    }

    func isAppAttestAuthEnabled() -> Bool {
        return featureFlags.isFeatureEnabled(.summarizerAppAttestAuth, checking: .buildOnly)
    }
}
