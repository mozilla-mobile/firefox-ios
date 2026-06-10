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

    private let htmlLangScript = "return document.documentElement.lang || null"

    /// Minimum confidence from `NLLanguageRecognizer` for a text-sample identification to be trusted.
    /// The recognizer's own confidence reliably separates clean text (scores ~0.9+, even on short or
    /// non-Latin samples) from code, markup, and mixed-language content (well below), so it is a better
    /// gate than an input-length threshold and is calibrated against the recognizer we actually ship.
    private let confidenceThreshold: Double

    init(confidenceThreshold: Double = 0.85) {
        self.confidenceThreshold = confidenceThreshold
    }

    /// Detects the page language from two signals. A confident text-sample identification is the
    /// strongest signal and overrides the `<html lang>` attribute, which authors frequently
    /// mislabel (e.g. `lang="en"` on non-English content). When the text identification isn't
    /// confident, it falls back to the HTML tag. Returns `nil` when neither yields a result.
    func detectLanguage(from source: LanguageSampleSource) async throws -> String? {
        let htmlTagLanguage = try await extractHTMLLangAttribute(from: source)
        let confidentLanguage = try await confidentlyIdentifiedLanguage(from: source)
        return confidentLanguage ?? htmlTagLanguage
    }

    /// Identifies the page language from an extracted text sample, but only when `NLLanguageRecognizer`
    /// reports a confidence at or above `confidenceThreshold`. A low-confidence result (typical of
    /// code, markup, or mixed-language samples) is discarded rather than used to override the HTML tag
    /// or stand on its own. Returns `nil` for empty or unrecognized samples.
    private func confidentlyIdentifiedLanguage(from source: LanguageSampleSource) async throws -> String? {
        let sample = try await extractSample(from: source)
        guard let sample else { return nil }
        let trimmed = sample.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(trimmed)
        guard let dominant = recognizer.dominantLanguage,
              let confidence = recognizer.languageHypotheses(withMaximum: 1)[dominant],
              confidence >= confidenceThreshold else {
            return nil
        }
        return dominant.rawValue
    }

    /// Reads the `lang` attribute from the page's `<html>` element.
    private func extractHTMLLangAttribute(from source: LanguageSampleSource) async throws -> String? {
        guard let rawLang = try await source.getLanguageSample(scriptEvalExpression: htmlLangScript),
              !rawLang.isEmpty else {
            return nil
        }
        return Self.normalizeLanguageCode(rawLang)
    }

    /// Extracts a text sample from the page via the JS bridge.
    /// Returns `nil` if the bridge isn't ready or no sample is available.
    private func extractSample(from source: LanguageSampleSource) async throws -> String? {
        let sample = try await source.getLanguageSample(scriptEvalExpression: languageSampleScript)
        guard let sample = sample, !sample.isEmpty else { return nil }
        return sample
    }

    /// Normalizes a raw HTML `lang` value to the format used by the translation models.
    /// Preserves script subtags (e.g. `"zh-Hans-CN"` → `"zh-Hans"`) but drops region-only
    /// suffixes (e.g. `"en-US"` → `"en"`).
    static func normalizeLanguageCode(_ code: String) -> String? {
        let components = code.split(separator: "-")
        guard let language = components.first, !language.isEmpty else { return nil }
        let languageCode = String(language).lowercased()
        // BCP-47 script subtags are exactly 4 characters, starting with uppercase (e.g. "Hans", "Hant").
        if components.count >= 2 {
            let second = String(components[1])
            if second.count == 4, second.first?.isUppercase == true {
                return "\(languageCode)-\(second)"
            }
        }
        return languageCode
    }
}
