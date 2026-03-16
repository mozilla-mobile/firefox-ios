// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

final class MockSummarizerNimbusUtils: SummarizerNimbusUtils, @unchecked Sendable {
    var isSummarizeFeatureToggledOn = false
    var isSummarizeFeatureEnabled = false
    var isShakeGestureEnabled = false
    var isToolbarButtonEnabled = false

    var appleSummarizerEnabled = false
    var hostedSummarizerEnabled = false
    var shakeGestureFeatureFlagEnabled = false
    var appAttestAuthEnabled = false
    var isLanguageExpansionEnabled = false

    private(set) var isAppleSummarizerEnabledCallCount = 0
    private(set) var isHostedSummarizerEnabledCallCount = 0
    private(set) var isShakeGestureFeatureFlagEnabledCallCount = 0
    private(set) var isAppAttestAuthEnabledCallCount = 0
    private(set) var languageExpansionConfigurationCallCount = 0
    var languageExpansionConfiguration = SummarizerLanguageExpansionConfiguration(
        supportedLocales: []
    )

    func isAppleSummarizerEnabled() -> Bool {
        isAppleSummarizerEnabledCallCount += 1
        return appleSummarizerEnabled
    }

    func isHostedSummarizerEnabled() -> Bool {
        isHostedSummarizerEnabledCallCount += 1
        return hostedSummarizerEnabled
    }

    func isShakeGestureFeatureFlagEnabled() -> Bool {
        isShakeGestureFeatureFlagEnabledCallCount += 1
        return shakeGestureFeatureFlagEnabled
    }

    func isAppAttestAuthEnabled() -> Bool {
        isAppAttestAuthEnabledCallCount += 1
        return appAttestAuthEnabled
    }

    func languageExpansionConfiguration(
        from nimbusFeature: Client.SummarizerLanguageExpansionFeature
    ) -> Client.SummarizerLanguageExpansionConfiguration {
        languageExpansionConfigurationCallCount += 1
        return languageExpansionConfiguration
    }
}
