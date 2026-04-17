// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct LiteLLMResponse: Codable {
    let id: String
    let choices: [LiteLLMChoice]
    let references: [LiteLLMReference]?
}

struct LiteLLMChoice: Codable {
    let index: Int
    let message: LiteLLMMessage?
    let delta: LiteLLMMessage?
    let finishReason: String?
}

public struct LiteLLMReference: Codable, Sendable {
    public let title: String
    public let url: URL?
    public let faviconUrl: URL?
}
