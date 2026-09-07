// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A single incremental update of a streamed chat completion. Exposes both the text delta and the
/// provider-specific fields (e.g. citations) carried by that chunk, since providers send the latter
/// in their own chunk rather than alongside every text delta.
public struct LiteLLMStreamChunk<ProviderFields: Codable & Sendable>: Sendable {
    public let content: String
    public let providerSpecificFields: ProviderFields?

    public init(content: String, providerSpecificFields: ProviderFields? = nil) {
        self.content = content
        self.providerSpecificFields = providerSpecificFields
    }
}

struct LiteLLMStreamResponse<ProviderFields: Codable & Sendable>: Codable, Sendable {
    let id: String
    let created: Int
    let model: String
    let object: String
    let choices: [StreamChoice<ProviderFields>]
}

struct StreamChoice<ProviderFields: Codable & Sendable>: Codable, Sendable {
    let index: Int
    let delta: Delta<ProviderFields>
}

struct Delta<ProviderFields: Codable & Sendable>: Codable, Sendable {
    let role: String?
    let content: String?
    let providerSpecificFields: ProviderFields?

    enum CodingKeys: String, CodingKey {
        case role
        case content
        case providerSpecificFields = "provider_specific_fields"
    }
}
