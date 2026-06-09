// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// `LiteLLMMessage` can return a field called `providerSpecificFields`, which
/// corresponds to response data that are unique to a particular model provider and
/// not part of the standard OpenAI API format. This file contains types that help
/// define these provider-specific field structures and provides convenient type aliases
/// for common message types used throughout the app.

public typealias QuickAnswersMessage = LiteLLMMessage<QuickAnswersProviderFields>
public typealias StandardMessage = LiteLLMMessage<EmptyProviderFields>

/// Empty provider fields for messages that don't have provider-specific data
public struct EmptyProviderFields: Codable, Sendable {
    public init() {}
}

/// Provider-specific data for Quick Answers (using exa endpoint)
public struct QuickAnswersProviderFields: Codable, Sendable {
    public let citations: [Citation]?
}

public struct Citation: Codable, Sendable {
    public let id: String
    public let title: String?
    public let url: String?
    public let image: String?
    public let favicon: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case url
        case image
        case favicon
    }

    public init(
        id: String,
        title: String? = nil,
        url: String? = nil,
        image: String? = nil,
        favicon: String? = nil
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.image = image
        self.favicon = favicon
    }
}
