// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct LiteLLMStreamResponse: Codable, Sendable {
//    let id: String
//    let created: Int
//    let model: String
//    let object: String
    public init(choices: [StreamChoice], references: [LiteLLMReference]?) {
        self.choices = choices
        self.references = references
    }
    
    public let choices: [StreamChoice]?
    public let references: [LiteLLMReference]?
    
    public func accumulate(_ response: Self) -> Self {
        let choices = (self.choices ?? []) + (response.choices ?? [])
        let references = (self.references ?? []) + (response.references ?? [])
        return LiteLLMStreamResponse(choices: choices, references: references)
    }
}

public struct StreamChoice: Codable, Sendable {
//    let index: Int
    public let delta: Delta
}

public struct Delta: Codable, Sendable {
    public let role: String?
    public let content: String?
}
