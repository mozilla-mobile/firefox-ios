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
    var isLanguageExpansionEnabled: Bool { get }

    func isAppleSummarizerEnabled() -> Bool
    func isHostedSummarizerEnabled() -> Bool
    func isAppAttestAuthEnabled() -> Bool
    func isShakeGestureFeatureFlagEnabled() -> Bool
    func languageExpansionConfiguration(
        from nimbusFeature: SummarizerLanguageExpansionFeature
    ) -> SummarizerLanguageExpansionConfiguration
}

/// Tiny utility to simplify checking for availability of the summarizers
struct DefaultSummarizerNimbusUtils: FeatureFlaggable, SummarizerNimbusUtils {
    private let prefs: Prefs
    private let localeProvider: LocaleProvider
    private let appleIntelligenceUtil: AppleIntelligenceUtil

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

    var isLanguageExpansionEnabled: Bool {
        return featureFlags.isFeatureEnabled(.summarizerLanguageExpansion, checking: .buildOnly)
    }

    /// Takes into consideration that summarize feature is on,
    /// shake feature flag is enabled, and user setting for shake is enabled
    var isShakeGestureEnabled: Bool {
        let summarizeFeatureOn = isSummarizeFeatureToggledOn
        let isShakeFlagEnabled = isShakeGestureFeatureFlagEnabled()
        let userSettingEnabled = didUserEnableShakeGestureFeature
        return summarizeFeatureOn && isShakeFlagEnabled && userSettingEnabled
    }

    init(
        profile: Profile = AppContainer.shared.resolve(),
        localeProvider: LocaleProvider = SystemLocaleProvider(),
        appleIntelligenceUtil: AppleIntelligenceUtil = AppleIntelligenceUtil()
    ) {
        self.prefs = profile.prefs
        self.localeProvider = localeProvider
        self.appleIntelligenceUtil = appleIntelligenceUtil
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
            // if the language expansion is enabled don't check the en locale cause we support multiple locales
            if languageExpansionConfiguration().isFeatureEnabled {
                return appleIntelligenceUtil.isAppleIntelligenceAvailable
            }
            let isEngLang = localeProvider.current.languageCode == "en"
            return isEngLang && appleIntelligenceUtil.isAppleIntelligenceAvailable
        #else
            return false
        #endif
    }

    func isHostedSummarizerEnabled() -> Bool {
        return featureFlags.isFeatureEnabled(.hostedSummarizer, checking: .buildOnly)
    }

    func isAppAttestAuthEnabled() -> Bool {
        return featureFlags.isFeatureEnabled(.summarizerAppAttestAuth, checking: .buildOnly)
    }

    private func isAppleSummarizerToolbarEndpointEnabled() -> Bool {
        return isAppleSummarizerEnabled()
    }

    private func isHostedSummarizerToolbarEndpointEnabled() -> Bool {
        let isFlagEnabled = featureFlags.isFeatureEnabled(.hostedSummarizerToolbarEntrypoint, checking: .buildOnly)
        return isHostedSummarizerEnabled() && isFlagEnabled
    }

    private func isAppleSummarizerShakeGestureEnabled() -> Bool {
        return isAppleSummarizerEnabled()
    }

    private func isHostedSummarizerShakeGestureEnabled() -> Bool {
        let isShakeEnabled = featureFlags.isFeatureEnabled(.hostedSummarizerShakeGesture, checking: .buildOnly)
        return isHostedSummarizerEnabled() && isShakeEnabled
    }

    func isShakeGestureFeatureFlagEnabled() -> Bool {
        return isAppleSummarizerShakeGestureEnabled() || isHostedSummarizerShakeGestureEnabled()
    }

    func languageExpansionConfiguration(
        from nimbusFeature: SummarizerLanguageExpansionFeature =
        FxNimbus.shared.features.summarizerLanguageExpansionFeature.value()
    ) -> SummarizerLanguageExpansionConfiguration {
        return SummarizerLanguageExpansionConfiguration(
            isFeatureEnabled: nimbusFeature.enabled,
            isWebsiteDeviceLanguageSupported: nimbusFeature.supportWebsiteLanguage,
            isDeviceLanguageSupported: nimbusFeature.supportDeviceLanguage,
            supportedLocales: nimbusFeature.supportedLocales.map({
                return Locale(identifier: $0)
            })
        )
    }
}
