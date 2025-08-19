// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A simple wrapper for fetching LiteLLM configuration values from Info.plist.
public struct LiteLLMConfig {
    private enum InfoKey: String {
        case apiKey      = "LiteLLMAPIKey"
        case apiEndpoint = "LiteLLMAPIEndpoint"
        case apiModel    = "LiteLLMAPIModel"
    }

    /// Fetches a non-empty String for the given key, or returns nil if missing/empty.
    private static func fetchValue(for key: InfoKey) -> String? {
        let value = Bundle.main.object(forInfoDictionaryKey: key.rawValue) as? String
        guard let value, !value.isEmpty else { return nil }
        return value
    }

    static var apiKey: String? {
        return fetchValue(for: .apiKey)
    }

    static var apiEndpoint: String? {
        return fetchValue(for: .apiEndpoint)
    }

    static var apiModel: String? {
        return fetchValue(for: .apiModel)
    }

    /// `maxWords` limits the number of words in the input text.
    /// While the hosted model has a very large context window (128k),
    /// It's limited to 5000 words due to performance and budget constraints.
    public static let maxWords = 5_000
    /// `maxTokens` is used to instruct the hosted model on the maximum number of tokens to generate.
    /// 2000 tokens is a reasonable limit for most summaries.
    static let maxTokens = 2_000
}
