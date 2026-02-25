// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

struct SummarizerLanguageExpansionConfiguration {
    /// Represents the user's language preference for summarization.
    enum UserPreference: Equatable {
        case websiteLanguage
        case deviceLanguage
        case customLocale(Locale)

        static var websiteLanguageSaveKey: String {
            return "websiteLanguage"
        }
        static var deviceLanguageSaveKey: String {
            return "deviceLanguage"
        }

        /// Converts the preference to a string value suitable for persistence.
        var saveValue: String {
            switch self {
            case .websiteLanguage:
                return Self.websiteLanguageSaveKey
            case .deviceLanguage:
                return Self.deviceLanguageSaveKey
            case .customLocale(let locale):
                return locale.identifier
            }
        }

        /// Reconstructs a `UserPreference` from a previously saved string value.
        static func from(savedValue: String) -> UserPreference {
            switch savedValue {
            case websiteLanguageSaveKey:
                return .websiteLanguage
            case deviceLanguageSaveKey:
                return .deviceLanguage
            default:
                let locale = Locale(identifier: savedValue)
                return .customLocale(locale)
            }
        }
    }
    struct SettingOption {
        let value: UserPreference
        let displayName: String

        /// Returns a tuple with value and display name, suitable for constructing setting options.
        func toOption() -> (UserPreference, String) {
            return (value, displayName)
        }
    }

    let isFeatureEnabled: Bool
    /// The supported Locales for the language expansion experiment
    let supportedLocales: [Locale]
    private let localeProvider: LocaleProvider

    /// Returns available language setting options
    var settingOptions: [SettingOption] {
        var options = [SettingOption]()
        options.append(
            SettingOption(
                value: .websiteLanguage,
                displayName: .Settings.Summarize.LanguageSection.WebsiteLanguageLabel
            )
        )
        options.append(
            SettingOption(
                value: .deviceLanguage,
                displayName: .Settings.Summarize.LanguageSection.PreferredAppLanguageLabel
            )
        )

        return options + supportedLocales.compactMap {
            guard let localizedLocale = localeProvider.current.localizedString(
                forIdentifier: $0.identifier
            ) else { return nil }

            return SettingOption(value: .customLocale($0), displayName: localizedLocale)
        }
    }

    init(
        isFeatureEnabled: Bool,
        supportedLocales: [Locale],
        localeProvider: LocaleProvider = SystemLocaleProvider()
    ) {
        self.isFeatureEnabled = isFeatureEnabled
        self.supportedLocales = supportedLocales
        self.localeProvider = localeProvider
    }

    /// Persists the selected language preference.
    func save(preference: UserPreference, prefs: Prefs) {
        prefs.setString(preference.saveValue, forKey: PrefsKeys.Summarizer.selectedLanguage)
    }

    /// Retrieves the saved language preference, defaulting to `UserPreference.websiteLanguage` if none is saved.
    func selectedPreference(prefs: Prefs) -> UserPreference {
        let savedValue = prefs.stringForKey(PrefsKeys.Summarizer.selectedLanguage)
        guard let savedValue else {
            return .websiteLanguage
        }
        let preference = UserPreference.from(savedValue: savedValue)
        // in case the locale is not in the supported once return the default preference
        if case .customLocale(let locale) = preference, !supportedLocales.contains(locale) {
            return .websiteLanguage
        }
        return preference
    }
}
