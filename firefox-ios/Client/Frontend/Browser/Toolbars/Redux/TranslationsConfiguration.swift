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
    let isUserSettingEnabled: Bool
    let state: IconState?
    /// The language code the page was translated to, if in the active state (e.g. "en", "fr").
    let translatedToLanguage: String?
    /// The original language of the page before translation (e.g. "de", "fr").
    let sourceLanguage: String?

    // We initially set icon state as nil until we can detect the
    // web page and determine if we should show the translation icon
    // and set the icon to .inactive state.
    init(
        prefs: Prefs,
        isUserSettingEnabled: Bool = true,
        state: IconState? = nil,
        translatedToLanguage: String? = nil,
        sourceLanguage: String? = nil
    ) {
        self.prefs = prefs
        self.isUserSettingEnabled = isUserSettingEnabled
        self.state = state
        self.translatedToLanguage = translatedToLanguage
        self.sourceLanguage = sourceLanguage
    }

    var isMultiLanguageFlow: Bool {
        guard featureFlagsProvider.isEnabled(.translationLanguagePicker) else { return false }
        guard let stored = prefs.stringForKey(PrefsKeys.Settings.translationPreferredLanguages),
              !stored.isEmpty else { return false }
        return stored.components(separatedBy: ",").count != 1
    }

    /// Determines whether to show the translate icon on the toolbar.
    /// The experiment needs to be turned on and the user setting needs to be enabled.
    var isTranslationFeatureEnabled: Bool {
        return featureFlagsProvider.isEnabled(.translation) && isUserSettingEnabled
    }

    static func == (lhs: TranslationConfiguration, rhs: TranslationConfiguration) -> Bool {
        return lhs.isUserSettingEnabled == rhs.isUserSettingEnabled
            && lhs.state == rhs.state
            && lhs.translatedToLanguage == rhs.translatedToLanguage
            && lhs.sourceLanguage == rhs.sourceLanguage
    }
}
