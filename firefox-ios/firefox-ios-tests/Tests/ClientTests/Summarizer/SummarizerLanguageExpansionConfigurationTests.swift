// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing
import Shared
@testable import Client

struct SummarizerLanguageExpansionConfigurationTests {
    private let localeProvider = MockLocaleProvider.defaultEN()
    private let prefs = MockProfilePrefs()

    @Test
    func test_settingOptions() {
        let enLocale = Locale(identifier: "en")
        let subject = createSubject(supportedLocales: [enLocale])

        let options = subject.settingOptions
        #expect(options.count == 3)
        #expect(options[0].toOption() == (.websiteLanguage, .Settings.Summarize.LanguageSection.WebsiteLanguageLabel))
        #expect(options[1].toOption() == (.deviceLanguage, .Settings.Summarize.LanguageSection.PreferredAppLanguageLabel))
        #expect(options[2].toOption() == (.customLocale(enLocale),
                               localeProvider.current.localizedString(forIdentifier: enLocale.identifier)))
    }

    @Test
    func test_save() {
        let subject = createSubject()

        subject.save(preference: .websiteLanguage, prefs: prefs)

        #expect(prefs.stringForKey(PrefsKeys.Summarizer.selectedLanguage) ==
                SummarizerLanguageExpansionConfiguration.UserPreference.websiteLanguage.saveValue)
    }

    @Test
    func test_selectedPreference_whenNoPreferenceSet_returnsDefaultValue() {
        let subject = createSubject()

        let savedPreference = subject.selectedPreference(prefs: prefs)

        #expect(savedPreference == .websiteLanguage)
    }

    @Test
    func test_selectedPreference_whenValidPreferenceIsSet_returnsThatValue() {
        let enLocale = Locale(identifier: "en")
        let subject = createSubject(supportedLocales: [enLocale])
        prefs.setString(enLocale.identifier, forKey: PrefsKeys.Summarizer.selectedLanguage)

        let savedPreference = subject.selectedPreference(prefs: prefs)

        #expect(savedPreference == .customLocale(enLocale))
    }

    @Test
    func test_selectedPreference_withLocaleNotInSupportedLocales_returnsDefaultValue() {
        let enLocale = Locale(identifier: "en")
        let subject = createSubject(supportedLocales: [enLocale])
        // save a not supported locale
        prefs.setString("it-IT", forKey: PrefsKeys.Summarizer.selectedLanguage)

        let savedPreference = subject.selectedPreference(prefs: prefs)

        #expect(savedPreference == .websiteLanguage)
    }

    @Test
    func test_UserPreferenceSaveValue() {
        typealias UserPreference = SummarizerLanguageExpansionConfiguration.UserPreference
        let enLocale = Locale(identifier: "en")

        #expect(UserPreference.deviceLanguage.saveValue == UserPreference.deviceLanguageSaveKey)
        #expect(UserPreference.websiteLanguage.saveValue == UserPreference.websiteLanguageSaveKey)
        #expect(UserPreference.customLocale(enLocale).saveValue == enLocale.identifier)
    }

    @Test
    func test_UserPreferenceFrom() {
        typealias UserPreference = SummarizerLanguageExpansionConfiguration.UserPreference
        let enLocale = Locale(identifier: "en")

        #expect(UserPreference.from(savedValue: UserPreference.websiteLanguageSaveKey) == .websiteLanguage)
        #expect(UserPreference.from(savedValue: UserPreference.deviceLanguageSaveKey) == .deviceLanguage)
        #expect(UserPreference.from(savedValue: enLocale.identifier) == .customLocale(enLocale))
    }

    private func createSubject(
        isFeatureEnabled: Bool = true,
        supportedLocales: [Locale] = [],
    ) -> SummarizerLanguageExpansionConfiguration {
        return SummarizerLanguageExpansionConfiguration(
            isFeatureEnabled: isFeatureEnabled,
            supportedLocales: supportedLocales,
            localeProvider: localeProvider
        )
    }
}
