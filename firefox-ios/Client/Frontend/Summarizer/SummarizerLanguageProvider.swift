// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Provides locale selection for summarization based on user preferences and website language detection.
protocol SummarizerLanguageProvider: Sendable {
    /// Determines the appropriate locale for summarization.
    ///
    /// - Parameters:
    ///   - userPreference: User preference for the summarizer locale.
    ///   - supportedLocales: List of locales that the summarizer can handle
    ///   - languageSampleSource: Source from which to detect the website's language
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
        // Always detect website language first.
        // This ensures we only proceed if the website has detectable content in a supported language.
        guard let websiteLanguage = await getWebsiteLocale(from: languageSampleSource) else { return nil }
        guard isLocaleInSupportedLocales(websiteLanguage, supportedLocales: supportedLocales) else { return nil }

        switch userPreference {
        case .websiteLanguage:
            return websiteLanguage
        case .customLocale(let customLocale):
            guard isLocaleInSupportedLocales(customLocale, supportedLocales: supportedLocales) else { return nil }
            return customLocale
        }
    }

    /// Detects the website's dominant language and converts it to a `Locale` object.
    ///
    /// The language detector returns a simple language code (e.g., "en", "fr", "de")
    /// which is then used to construct a Locale. This means the detected locale will only
    /// contain the language code, without region or script information.
    /// - Note: For reference see `LanguageDetector.getDominantLanguage()`
    private func getWebsiteLocale(from source: LanguageSampleSource) async -> Locale? {
        let languageIdentifier = try? await websiteLanguageProvider.detectLanguage(from: source)
        guard let languageIdentifier else { return nil }
        return Locale(identifier: languageIdentifier)
    }

    /// Checks that the locale identifier is contained in the supported locale identifiers.
    /// This allows locale like `de-DE` to be supported if the supported list contains `de` only.
    private func isLocaleInSupportedLocales(
        _ locale: Locale,
        supportedLocales: [Locale]
    ) -> Bool {
        return supportedLocales.map({ $0.identifier }).contains {
            $0.contains(locale.identifier)
        }
    }
}
