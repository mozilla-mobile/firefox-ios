// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

// Holds the configuration / state of the translation button on the toolbar
// Whether we should show translate button and which mode (inactive, loading, active)
struct TranslationConfiguration: Equatable, FeatureFlaggable {
    let prefs: Prefs
    init(prefs: Prefs) {
        self.prefs = prefs
    }

    /// Determines whether to show the translate icon on the toolbar
    /// The experiment needs to be turned on and the user settings needs to be enabled
    /// If user has not toggled the settings, then we enable the feature by default
    var canTranslate: Bool {
        let isExperimentOn = featureFlags.isFeatureEnabled(.translation, checking: .buildOnly)
        let isSettingsEnabled = prefs.boolForKey(PrefsKeys.Settings.translationsFeature) ?? true
        return isExperimentOn && isSettingsEnabled
    }

    static func == (lhs: TranslationConfiguration, rhs: TranslationConfiguration) -> Bool {
        return lhs.canTranslate == rhs.canTranslate
    }
}
