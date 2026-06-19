// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

struct MockNimbusUtils: SummarizerNimbusUtils {
    var isSummarizeFeatureToggledOn: Bool {
        return summarizeFeatureToggledOn
    }

    var isSummarizeFeatureEnabled: Bool {
        return summarizeFeatureEnabled
    }

    var isShakeGestureEnabled: Bool {
        return true
    }

    var isToolbarButtonEnabled: Bool {
        return true
    }

    var isLanguageExpansionEnabled: Bool {
        return true
    }

    func isAppleSummarizerEnabled() -> Bool {
        return true
    }

    func isHostedSummarizerEnabled() -> Bool {
        return true
    }

    func isAppAttestAuthEnabled() -> Bool {
        return true
    }

    func usesPermissiveGuardrails() -> Bool {
        return true
    }

    func isShakeGestureFeatureFlagEnabled() -> Bool {
        return true
    }

    private let summarizeFeatureToggledOn: Bool
    private let summarizeFeatureEnabled: Bool

    init(summarizeFeatureToggledOn: Bool, summarizeFeatureEnabled: Bool) {
        self.summarizeFeatureToggledOn = summarizeFeatureToggledOn
        self.summarizeFeatureEnabled = summarizeFeatureEnabled
    }
    func languageExpansionConfiguration(
        from nimbusFeature: SummarizerLanguageExpansionFeature
    ) -> SummarizerLanguageExpansionConfiguration {
        return SummarizerLanguageExpansionConfiguration(supportedLocales: [])
    }
}
