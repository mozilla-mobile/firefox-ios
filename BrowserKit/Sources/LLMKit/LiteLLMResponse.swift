// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct LiteLLMResponse: Codable {
    let id: String
    let choices: [LiteLLMChoice]
}

struct LiteLLMChoice: Codable {
    let index: Int
    let message: LiteLLMMessage?
    let delta: LiteLLMMessage?
    let finishReason: String?
    let providerSpecificFields: ProviderSpecificFields?

    enum CodingKeys: String, CodingKey {
        case index
        case message
        case delta
        case finishReason
        case providerSpecificFields = "provider_specific_fields"
    }
}

/// Provider-specific data that may be included in responses
/// Different providers may include different fields
struct ProviderSpecificFields: Codable {
    /// Citations from search-enabled providers (e.g., Exa)
    let citations: [Citation]?

    /// Native finish reason when it differs from OpenAI-compatible mapping
    let nativeFinishReason: String?

    enum CodingKeys: String, CodingKey {
        case citations
        case nativeFinishReason = "native_finish_reason"
    }
}

struct Citation: Codable {
    let id: String
    let title: String?
    let url: String
    let publishedDate: String?
    let author: String?
    let image: String?
    let favicon: String?
}

// TODO: FXIOS-15123 - Temporarily added until we get actual endpoint
public struct SearchResponse: Codable {
    public let results: [SearchSource]
}

public struct SearchSource: Codable {
    public let title: String?
    public let url: String?
    public let snippet: String?
}
