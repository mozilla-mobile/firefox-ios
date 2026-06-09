// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Represents a single message exchanged with the LLM.
public struct LiteLLMMessage<ProviderFields: Codable & Sendable>: Codable, Sendable {
    public let role: LiteLLMRole
    public let content: String
    // Parameters or response data that are unique to a particular model provider and
    // not part of the standard OpenAI API format.
    public let providerSpecificFields: ProviderFields?

    public init(role: LiteLLMRole, content: String, providerSpecificFields: ProviderFields? = nil) {
        self.role = role
        self.content = content
        self.providerSpecificFields = providerSpecificFields
    }

    enum CodingKeys: String, CodingKey {
        case role
        case content
        case providerSpecificFields = "provider_specific_fields"
    }
}
