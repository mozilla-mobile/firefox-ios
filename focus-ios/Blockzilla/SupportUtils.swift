/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public enum SupportTopic: String {
    case focusHelp = "focus"
    case klarHelp = "klar"
    case usageData = "usage-data"

    /// These are the additional supported languages, next to the default language the document is written in. At
    /// some later stage SUMO will do an automatic redirect based on the Accepts-Language header. For now we will
    /// have to maintain a static list of supported languages.

    var supportedLanguages: Set<String> {
        switch self {
        case .focusHelp:
            return Set(["es", "fr", "hi-in", "id", "it", "jp", "pl", "pt", "ru", "zh-tw"])
        case .klarHelp:
            return Set()
        case .usageData:
            return Set(["de", "es", "fr", "hi-in", "id", "it", "jp", "pl", "pt", "ru", "zh-tw"])
        }
    }

    var slug: String {
        return self.rawValue
    }

    /// Return a URL to this topic for the given language. The logic here is as follows: try to find the best matching
    /// language code that this topic supports. And fall back to the default if no match is found. The default language
    /// is silent, and is not added to the URL.

    func URLForLanguageCode(_ languageCode: String) -> URL? {
        if let matchingLanguageCode = matchPreferredLanguageToSupportedLanguages(languageCode.lowercased()) {
            return URL(string: "https://support.mozilla.org/kb/\(slug)-\(matchingLanguageCode)")
        } else {
            return URL(string: "https://support.mozilla.org/kb/\(slug)")
        }
    }

    /// Given a preferred language code, find the best match for this topic's supported languages. Returns nil if no
    /// match can be found.

    private func matchPreferredLanguageToSupportedLanguages(_ preferredLanguage: String) -> String? {
        // 1. Try a direct match (es against es, zh-TW against zh-tw)
        if supportedLanguages.contains(preferredLanguage) {
            return preferredLanguage
        }

        // 2. Try to match the simplified preferred language against the supported languages (es-MX against es)
        if preferredLanguage.contains("-") {
            if let language = preferredLanguage.components(separatedBy: "-").first, supportedLanguages.contains(language) {
                return language
            }
        }

        // 3. Try to match the simplified preferred language against the simplified supported languages (hi against hi-in)
        if !preferredLanguage.contains("-") {
            for supportedLanguage in supportedLanguages {
                if let language  = supportedLanguage.components(separatedBy: "-").first, preferredLanguage == language {
                    return supportedLanguage
                }
            }
        }

        return nil
    }
}

/// Utility functions related to SUMO.
public struct SupportUtils {
    /// Return a SUMO URL for the given topic.
    public static func URLForTopic(_ topic: SupportTopic) -> URL? {
        return topic.URLForLanguageCode(Locale.preferredLanguages.first ?? "en")
    }
}
