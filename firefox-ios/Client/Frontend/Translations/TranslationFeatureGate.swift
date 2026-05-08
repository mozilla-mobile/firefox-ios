// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Single place that maps raw Nimbus flags to Translations capability decisions.
/// Adding a Phase 3 flag requires editing only this type.
struct TranslationFeatureGate {
    private let featureFlagsProvider: FeatureFlagProviding

    init(featureFlagsProvider: FeatureFlagProviding) {
        self.featureFlagsProvider = featureFlagsProvider
    }

    var isLanguagePickerEnabled: Bool {
        featureFlagsProvider.isEnabled(.translationLanguagePicker)
    }
}

extension FeatureFlaggable {
    var translationFeatureGate: TranslationFeatureGate {
        TranslationFeatureGate(featureFlagsProvider: featureFlagsProvider)
    }
}
