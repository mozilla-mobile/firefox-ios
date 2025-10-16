// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit
import NaturalLanguage

/// Simple utility for extracting and detecting language samples from a web view.
struct LanguageDetector {
    /// Extracts a text sample from the page via the Translations bridge.
    /// Returns `nil` if the bridge isn’t ready or no sample is available.
    @MainActor
    static func extractSample(from webView: WKWebView) async throws -> String? {
        // TODO(Issam): Add comment and link to where this is defined.
        let js = "return await window.__firefox__.Translations.getLanguageSampleWhenReady()"
        let result = try await webView.callAsyncJavaScript(js, contentWorld: .defaultClient)
        guard let sample = result as? String, !sample.isEmpty else {
            return nil
        }
        return sample
    }

    /// Detects the dominant language of a given text and returns its BCP-47 code (e.g. `"en"`, `"fr"`).
    static func detectLanguage(of text: String) -> String? {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return NLLanguageRecognizer.dominantLanguage(for: text)?.rawValue
    }
}
