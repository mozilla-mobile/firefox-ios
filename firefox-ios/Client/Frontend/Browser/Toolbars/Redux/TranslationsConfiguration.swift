// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Common
import Shared

// Holds the configuration / state of the translation button on the toolbar
// Whether we should show translate button and which mode (inactive, loading, active)
struct TranslationConfiguration: Equatable, FeatureFlaggable {
    /// This is used to configure the translation icon state.
    /// States:
    /// inactive - page has not been translated yet
    /// loading - currently translating page
    /// active - page has been translated
    enum IconState {
        case inactive
        case loading
        case active

        var buttonImageName: String? {
            switch self {
            case .inactive:
                return StandardImageIdentifiers.Medium.translate
            case .loading:
                return nil
            case .active:
                return ImageIdentifiers.Translations.translationActive
            }
        }

        var buttonA11yLabel: String {
            switch self {
            case .inactive:
                return .Toolbars.Translation.ButtonInactiveAccessibilityLabel
            case .loading:
                return .Toolbars.Translation.LoadingButtonAccessibilityLabel
            case .active:
                return .Toolbars.Translation.ButtonActiveAccessibilityLabel
            }
        }

        var buttonA11yIdentifier: String {
            switch self {
            case .inactive:
                return AccessibilityIdentifiers.Toolbar.translateButton
            case .loading:
                return AccessibilityIdentifiers.Toolbar.translateLoadingButton
            case .active:
                return AccessibilityIdentifiers.Toolbar.translateActiveButton
            }
        }
    }

    let prefs: Prefs
    let state: IconState?

    // We initially set icon state as nil until we can detect the
    // web page and determine if we should show the translation icon
    // and set the icon to .inactive state.
    init(prefs: Prefs, state: IconState? = nil) {
        self.prefs = prefs
        self.state = state
    }

    /// Determines whether to show the translate icon on the toolbar
    /// The experiment needs to be turned on and the user settings needs to be enabled
    /// If user has not toggled the settings, then we enable the feature by default
    var isTranslationFeatureEnabled: Bool {
        let isExperimentOn = featureFlags.isFeatureEnabled(.translation, checking: .buildOnly)
        let isSettingsEnabled = prefs.boolForKey(PrefsKeys.Settings.translationsFeature) ?? true
        return isExperimentOn && isSettingsEnabled
    }

    static func == (lhs: TranslationConfiguration, rhs: TranslationConfiguration) -> Bool {
        return lhs.isTranslationFeatureEnabled == rhs.isTranslationFeatureEnabled
    }
}
