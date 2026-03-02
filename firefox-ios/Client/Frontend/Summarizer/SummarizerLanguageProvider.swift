// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol SummarizerLanguageProvider: Sendable {
    func getLanguage(
        userPreference: SummarizerLanguageExpansionConfiguration.UserPreference,
        supportedLocales: [Locale],
        languageSampleSource: LanguageSampleSource,
    ) async -> Locale?
}

struct DefaultSummarizerLanguageProvider: SummarizerLanguageProvider {
    let websiteLanguageProvider: LanguageDetectorProvider

    func getLanguage(
        userPreference: SummarizerLanguageExpansionConfiguration.UserPreference,
        supportedLocales: [Locale],
        languageSampleSource: any LanguageSampleSource
    ) async -> Locale? {
        var locale: Locale?
        switch userPreference {
        case .websiteLanguage:
            let languageIdentifier = try? await websiteLanguageProvider.detectLanguage(from: languageSampleSource)
            if let languageIdentifier {
                locale = Locale(identifier: languageIdentifier)
            }
        case .customLocale(let customLocale):
            locale = customLocale
        }
        guard let locale else { return nil }

        let localeIsSupported = supportedLocales.contains(locale)
        return localeIsSupported ? locale : nil
    }
    
    private func getWebsiteLocale(from source: LanguageSampleSource) async -> Locale? {
        let languageIdentifier = try? await websiteLanguageProvider.detectLanguage(from: source)
        guard let languageIdentifier else { return nil }
        return Locale(identifier: languageIdentifier)
    }
}
