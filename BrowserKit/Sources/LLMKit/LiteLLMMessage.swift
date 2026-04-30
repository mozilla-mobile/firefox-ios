// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Represents a single message exchanged with the LLM.
public struct LiteLLMMessage: Codable, Sendable {
    public let role: LiteLLMRole
    public let content: String
    public let providerSpecificFields: ProviderSpecificFields?

    public init(role: LiteLLMRole, content: String, providerSpecificFields: ProviderSpecificFields? = nil) {
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

/// Provider-specific data that may be included in message responses
/// Different providers may include different fields
public struct ProviderSpecificFields: Codable, Sendable {
    public let citations: [Citation]?
}

public struct Citation: Codable, Sendable {
    public let id: String
    public let title: String?
    public let url: String?
    public let publishedDate: String?
    public let author: String?
    public let image: String?
    public let favicon: String?

    public init(
        id: String,
        title: String? = nil,
        url: String,
        publishedDate: String? = nil,
        author: String? = nil,
        image: String? = nil,
        favicon: String? = nil
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.publishedDate = publishedDate
        self.author = author
        self.image = image
        self.favicon = favicon
    }
}
