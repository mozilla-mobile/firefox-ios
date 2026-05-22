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

    /// NLLanguageRecognizer hypotheses below this threshold are treated as unreliable.
    static let minimumConfidence: Double = 0.5

    func detectLanguage(from source: LanguageSampleSource) async throws -> String? {
        if let htmlLang = try await extractHTMLLangAttribute(from: source) {
            return htmlLang
        }
        let sample = try await extractSample(from: source)
        guard let textSample = sample else { return nil }
        return getDominantLanguage(of: textSample)
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

    /// Detects the dominant language of a given text and returns its BCP-47 code (e.g. `"en"`, `"fr"`).
    private func getDominantLanguage(of text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(trimmed)
        guard let dominant = recognizer.dominantLanguage else { return nil }
        let confidence = recognizer.languageHypotheses(withMaximum: 1)[dominant] ?? 0
        guard confidence >= Self.minimumConfidence else { return nil }
        return dominant.rawValue
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
