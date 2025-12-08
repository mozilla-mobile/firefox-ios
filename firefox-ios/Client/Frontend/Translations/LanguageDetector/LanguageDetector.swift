// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit
import NaturalLanguage

/// A small utility for extracting a text sample from a web page and detecting its language.
/// The sample is extracted using JS.
protocol LanguageDetectorProvider: Sendable {
    func detectLanguage(from source: LanguageSampleSource) async throws -> String?
}

final class LanguageDetector: LanguageDetectorProvider {
    /// JS function that is called to get a page sample back. The function is implemented in `Summarizer.js`.
    private let languageSampleScript =
        "return await window.__firefox__.Translations.getLanguageSampleWhenReady()"

    func detectLanguage(from source: LanguageSampleSource) async throws -> String? {
        let sample = try await extractSample(from: source)
        guard let textSample = sample else { return nil }
        return getDominantLanguage(of: textSample)
    }

    /// Extracts a text sample from the page via the JS bridge.
    /// Returns `nil` if the bridge isn’t ready or no sample is available.
    private func extractSample(from source: LanguageSampleSource) async throws -> String? {
        let sample = try await source.getLanguageSample(scriptEvalExpression: languageSampleScript)
        guard let sample = sample, !sample.isEmpty else { return nil }
        return sample
    }

    /// Detects the dominant language of a given text and returns its BCP-47 code (e.g. `"en"`, `"fr"`).
    private func getDominantLanguage(of text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return NLLanguageRecognizer.dominantLanguage(for: trimmed)?.rawValue
    }
}
