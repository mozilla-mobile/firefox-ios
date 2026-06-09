// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing
@testable import Client

struct SummarizerLanguageProviderTests {
    private let websiteLanguageProvider = MockLanguageDetector()

    @Test
    func test_getLanguage_whenCantFetchWebsiteLocale_returnsNil() async {
        websiteLanguageProvider.mockError = NSError(domain: "", code: 0)
        let subject = createSubject()

        let locale = await subject.getLanguage(
            userPreference: .websiteLanguage,
            supportedLocales: [],
            languageSampleSource: MockLanguageSampleSource()
        )
        #expect(locale == nil)
    }

    @Test
    func test_getLanguage_whenWebsiteLanguageNotInSupportedLocales_returnsNil() async {
        websiteLanguageProvider.detectedLanguage = "fr"
        let subject = createSubject()

        let locale = await subject.getLanguage(
            userPreference: .websiteLanguage,
            supportedLocales: [Locale(identifier: "en-GB")],
            languageSampleSource: MockLanguageSampleSource()
        )
        #expect(locale == nil)
    }

    @Test
    func test_getLanguage_whenWebsiteLanguageInSupportedLocales_returnsWebsiteLanguage() async {
        websiteLanguageProvider.detectedLanguage = "fr"
        let subject = createSubject()

        let locale = await subject.getLanguage(
            userPreference: .websiteLanguage,
            supportedLocales: [
                Locale(identifier: "fr-FR"),
                Locale(identifier: "en-GB")
            ],
            languageSampleSource: MockLanguageSampleSource()
        )

        #expect(locale == Locale(identifier: websiteLanguageProvider.detectedLanguage))
    }

    @Test
    func test_getLanguage_whenCustomLocalePreference_returnsCustomLocale() async {
        websiteLanguageProvider.detectedLanguage = "de"
        let subject = createSubject()

        let locale = await subject.getLanguage(
            userPreference: .customLocale(Locale(identifier: "de")),
            supportedLocales: [Locale(identifier: "de")],
            languageSampleSource: MockLanguageSampleSource()
        )

        #expect(locale == Locale(identifier: "de"))
    }

    @Test
    func test_getLanguage_whenCustomLocalePreference_returnsNilForLocaleNotInSupportedLocales() async {
        websiteLanguageProvider.detectedLanguage = "it"
        let subject = createSubject()

        let locale = await subject.getLanguage(
            userPreference: .customLocale(Locale(identifier: "de")),
            supportedLocales: [Locale(identifier: "it")],
            languageSampleSource: MockLanguageSampleSource()
        )

        #expect(locale == nil)
    }

    private func createSubject() -> DefaultSummarizerLanguageProvider {
        return DefaultSummarizerLanguageProvider(websiteLanguageProvider: websiteLanguageProvider)
    }
}
