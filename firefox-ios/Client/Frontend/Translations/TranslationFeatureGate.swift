// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Maps raw Nimbus flags to product-level capability decisions for the Translations feature.
/// All `translationLanguagePicker` flag reads go through this gate, so that adding a
/// Phase 3 path requires editing only this type, not individual call sites.
struct TranslationFeatureGate {
    private let featureFlagsProvider: FeatureFlagProviding

    init(featureFlagsProvider: FeatureFlagProviding) {
        self.featureFlagsProvider = featureFlagsProvider
    }

    /// Whether the multi-language translation flow is available (eligibility checks, auto-translate).
    var isMultiLanguageFlowEnabled: Bool {
        featureFlagsProvider.isEnabled(.translationLanguagePicker)
    }

    /// Whether the language-picker UI should be presented to the user.
    var shouldUsePickerUI: Bool {
        featureFlagsProvider.isEnabled(.translationLanguagePicker)
    }
}

extension FeatureFlaggable {
    var translationFeatureGate: TranslationFeatureGate {
        TranslationFeatureGate(featureFlagsProvider: featureFlagsProvider)
    }
}
