// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit
import NaturalLanguage

/// A small utility for extracting a text sample from a web page and detecting its language.
/// The sample is extracted using JS.
final class LanguageDetector {
    /// JS function that is called to get a page sample back. The function is implemented in `Summarizer.js`.
    private static let languageSampleScript =
        "return await window.__firefox__.Translations.getLanguageSampleWhenReady()"

    /// Extracts a text sample from the page via the JS bridge.
    /// Returns `nil` if the bridge isn’t ready or no sample is available.
    @MainActor
    func extractSample(from source: LanguageSampleSource) async throws -> String? {
        let result = try await source.getLanguageSample(scriptEvalExpression: Self.languageSampleScript)
        guard let sample = result, !sample.isEmpty else { return nil }
        return sample
    }

    /// Detects the dominant language of a given text and returns its BCP-47 code (e.g. `"en"`, `"fr"`).
    func detectLanguage(of text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return NLLanguageRecognizer.dominantLanguage(for: trimmed)?.rawValue
    }
}
