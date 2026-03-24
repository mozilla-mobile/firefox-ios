// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Represents a single message exchanged with the LLM.
public struct LiteLLMMessage: Codable, Sendable {
    public let role: LiteLLMRole
    public let content: String

    public init(role: LiteLLMRole, content: String) {
        self.role = role
        self.content = content
    }
}
