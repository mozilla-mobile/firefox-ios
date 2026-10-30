// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

final class MockSummarizerLanguageProvider: SummarizerLanguageProvider, @unchecked Sendable {
    var shouldReturnLocale = false
    let returnedLocale = Locale(identifier: "en")
    var returnedPageLocale = Locale(identifier: "en")
    private(set) var getLanguageCallCount = 0

    func getLanguage(
        userPreference: SummarizerLanguageExpansionConfiguration.UserPreference,
        supportedLocales: [Locale],
        languageSampleSource: any LanguageSampleSource
    ) async -> SummarizerLanguageResolution? {
        getLanguageCallCount += 1
        guard shouldReturnLocale else { return nil }
        return SummarizerLanguageResolution(summaryLocale: returnedLocale, pageLocale: returnedPageLocale)
    }
}
